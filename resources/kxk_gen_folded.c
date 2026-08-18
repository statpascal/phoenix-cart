/*
 * kxk_gen_folded.c - KRvK / KQvK distance-to-mate generator WITH symmetry folding.
 *
 * Extends the validated kxk_gen.c: after solving the full 262144-entry weak-to-move
 * slice, it folds the STRONG king into a 10-square canonical triangle using the full
 * 8-fold board symmetry (the pawnless endgame's dihedral group), giving a
 * 10*64*64 = 40960-byte table per piece. DTM is symmetry-invariant, so the fold is
 * exact. The program then VERIFIES the folded lookup reproduces the full slice for
 * every one of the 262144 positions before writing anything.
 *
 * Build: gcc -O2 -o kxk_gen_folded kxk_gen_folded.c
 * Run:   ./kxk_gen_folded   (prints stats + verification; writes krk_dtm_folded.bin / kqk_dtm_folded.bin)
 *
 * Squares a1=0..h8=63. Value = plies-to-mate, 255 = draw, 254 = illegal.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

typedef uint64_t U64;
#define BIT(s) (1ULL<<(s))
enum { ROOK, QUEEN };
enum { DRAW = 255, ILL = 254 };

/* ---------- solver (verbatim from the validated kxk_gen.c) ---------- */
static U64 kingAtt[64];
static void init_king(void){
    static const int dr[8]={1,1,1,0,0,-1,-1,-1}, df[8]={1,0,-1,1,-1,1,0,-1};
    for(int s=0;s<64;s++){ int r=s/8,f=s%8; U64 a=0;
        for(int i=0;i<8;i++){int rr=r+dr[i],ff=f+df[i]; if(rr>=0&&rr<8&&ff>=0&&ff<8) a|=BIT(rr*8+ff);}
        kingAtt[s]=a; }
}
static U64 slider(int sq,U64 occ,const int*dr,const int*df){
    U64 a=0; int r=sq/8,f=sq%8;
    for(int d=0;d<4;d++){int rr=r+dr[d],ff=f+df[d];
        while(rr>=0&&rr<8&&ff>=0&&ff<8){int s=rr*8+ff; a|=BIT(s); if(occ&BIT(s))break; rr+=dr[d];ff+=df[d];}}
    return a;
}
static const int RDR[4]={1,-1,0,0},RDF[4]={0,0,1,-1},BDR[4]={1,1,-1,-1},BDF[4]={1,-1,1,-1};
static U64 patt(int piece,int s,U64 o){ U64 a=slider(s,o,RDR,RDF); if(piece==QUEEN) a|=slider(s,o,BDR,BDF); return a; }

#define IDX(sK,wK,pc,stm) ((((sK)*64+(wK))*64+(pc))*2+(stm))

static unsigned char *gen(int piece){
    unsigned char *T = malloc(64*64*64*2);
    memset(T,DRAW,64*64*64*2);
    for(int sK=0;sK<64;sK++)for(int wK=0;wK<64;wK++)for(int pc=0;pc<64;pc++){
        if(sK==wK||sK==pc||wK==pc||(kingAtt[sK]&BIT(wK))){ T[IDX(sK,wK,pc,0)]=ILL; T[IDX(sK,wK,pc,1)]=ILL; continue; }
        U64 occ=BIT(sK)|BIT(wK)|BIT(pc);
        if(patt(piece,pc,occ)&BIT(wK)) T[IDX(sK,wK,pc,0)]=ILL;
    }
    int changed=1,pass=0;
    while(changed){ changed=0; pass++;
      for(int sK=0;sK<64;sK++)for(int wK=0;wK<64;wK++)for(int pc=0;pc<64;pc++){
        U64 occ=BIT(sK)|BIT(wK)|BIT(pc);
        /* weak (black) to move: won only if ALL moves lead to won; DTM = 1 + max child (weak stalls) */
        int i1=IDX(sK,wK,pc,1);
        if(T[i1]!=ILL){
            U64 patk = patt(piece, pc, BIT(sK)|BIT(pc));
            U64 wm = kingAtt[wK] & ~kingAtt[sK] & ~BIT(sK) & (~patk | BIT(pc));
            int legal=0,allWin=1,worst=-1; U64 m=wm;
            while(m){ int to=__builtin_ctzll(m); m&=m-1; legal++;
                if(to==pc){ allWin=0; continue; }
                int cv=T[IDX(sK,to,pc,0)];
                if(cv>=250) allWin=0; else if(cv>worst) worst=cv;
            }
            if(legal==0){ if(patt(piece,pc,occ)&BIT(wK)){ if(T[i1]!=0){ T[i1]=0; changed=1; } } }  /* mate */
            else if(allWin){ int nv=1+worst; if(T[i1]==DRAW || nv<T[i1]){ T[i1]=(unsigned char)nv; changed=1; } }
        }
        /* strong (white) to move: won if ANY move leads to won; DTM = 1 + min child (strong hurries) */
        int i0=IDX(sK,wK,pc,0);
        if(T[i0]!=ILL){
            int best=1000;
            U64 km = kingAtt[sK] & ~kingAtt[wK] & ~BIT(pc);
            U64 m=km; while(m){int to=__builtin_ctzll(m);m&=m-1; int cv=T[IDX(to,wK,pc,1)]; if(cv<250&&1+cv<best)best=1+cv;}
            U64 pm = patt(piece,pc,occ) & ~BIT(sK) & ~BIT(wK);
            m=pm; while(m){int to=__builtin_ctzll(m);m&=m-1; int cv=T[IDX(sK,wK,to,1)]; if(cv<250&&1+cv<best)best=1+cv;}
            if(best<250 && (T[i0]==DRAW || best<T[i0])){ T[i0]=(unsigned char)best; changed=1; }
        }
      }
    }
    return T;
}

/* ---------- 8-fold symmetry of the board (dihedral group of the square) ---------- */
static int sym(int t,int s){
    int r=s/8,f=s%8,nr,nf;
    switch(t){
        case 0: nr=r;   nf=f;   break;   /* identity          */
        case 1: nr=r;   nf=7-f; break;   /* flip files (H)     */
        case 2: nr=7-r; nf=f;   break;   /* flip ranks (V)     */
        case 3: nr=7-r; nf=7-f; break;   /* 180 rotation       */
        case 4: nr=f;   nf=r;   break;   /* main diagonal      */
        case 5: nr=7-f; nf=7-r; break;   /* anti-diagonal      */
        case 6: nr=f;   nf=7-r; break;   /* 90 rotation        */
        default:nr=7-f; nf=r;   break;   /* 270 rotation       */
    }
    return nr*8+nf;
}
/* canonT[s] = transform mapping s to the minimum square of its orbit (its canonical form).
   canonIdx[s] = 0..nCanon-1 for canonical squares, -1 otherwise. */
static int canonT[64], canonIdx[64], nCanon;
static void init_canon(void){
    for(int s=0;s<64;s++){ int best=100,bt=0;
        for(int t=0;t<8;t++){ int im=sym(t,s); if(im<best){best=im;bt=t;} }
        canonT[s]=bt; }
    nCanon=0;
    for(int s=0;s<64;s++) canonIdx[s]=-1;
    for(int s=0;s<64;s++) if(sym(canonT[s],s)==s) canonIdx[s]=nCanon++;
}
/* fold: store slice only for canonical strong-king squares */
static unsigned char *foldSlice(unsigned char *slice){
    unsigned char *F = malloc((size_t)nCanon*64*64);
    for(int sK=0;sK<64;sK++) if(canonIdx[sK]>=0)
        for(int wK=0;wK<64;wK++) for(int pc=0;pc<64;pc++)
            F[((size_t)canonIdx[sK]*64+wK)*64+pc] = slice[((size_t)sK*64+wK)*64+pc];
    return F;
}
/* lookup: canonicalize by the strong king, apply the SAME transform to weak king + piece */
static unsigned char lookupFolded(unsigned char *F,int sK,int wK,int pc){
    int t = canonT[sK];
    int csK = sym(t,sK), cwK = sym(t,wK), cpc = sym(t,pc);
    return F[((size_t)canonIdx[csK]*64+cwK)*64+cpc];
}

int main(void){
    init_king();
    init_canon();
    printf("canonical strong-king squares: %d (triangle)\n", nCanon);
    const char *nm[2]={"KRvK","KQvK"}; const char *fn[2]={"krk_dtm_folded.bin","kqk_dtm_folded.bin"};
    int allok=1;
    for(int p=0;p<2;p++){
        unsigned char *T=gen(p);
        unsigned char *slice=malloc(64*64*64);
        long won=0; int mx=0;
        for(int k=0;k<64*64*64;k++){ unsigned char v=T[k*2+1]; slice[k]=v; if(v<250){won++; if(v>mx)mx=v;} }
        /* DIAGNOSTIC: concrete won positions vs their horizontal-flip images */
        if(p==0){ int shown=0;
            for(int sK=0;sK<64&&shown<6;sK++)for(int wK=0;wK<64&&shown<6;wK++)for(int pc=0;pc<64&&shown<6;pc++){
                unsigned char v=slice[((size_t)sK*64+wK)*64+pc];
                if(v<250){ int fsK=sym(1,sK),fwK=sym(1,wK),fpc=sym(1,pc);
                    unsigned char fv=slice[((size_t)fsK*64+fwK)*64+fpc];
                    printf("  ex: sK=%d wK=%d pc=%d -> %d | flip sK=%d wK=%d pc=%d -> %d\n",sK,wK,pc,v,fsK,fwK,fpc,fv);
                    shown++; }
            }
        }
        /* DIAGNOSTIC: which of the 8 symmetries actually leave the DTM slice invariant? */
        for(int t=0;t<8;t++){ long mm=0;
            for(int sK=0;sK<64;sK++)for(int wK=0;wK<64;wK++)for(int pc=0;pc<64;pc++){
                int a=slice[((size_t)sK*64+wK)*64+pc];
                int b=slice[((size_t)sym(t,sK)*64+sym(t,wK))*64+sym(t,pc)];
                if(a!=b) mm++;
            }
            printf("  %s transform %d: %ld invariance mismatches\n", nm[p], t, mm);
        }
        unsigned char *F=foldSlice(slice);
        /* VERIFY: folded lookup == full slice for every position */
        long mism=0;
        for(int sK=0;sK<64;sK++)for(int wK=0;wK<64;wK++)for(int pc=0;pc<64;pc++)
            if(lookupFolded(F,sK,wK,pc)!=slice[((size_t)sK*64+wK)*64+pc]) mism++;
        printf("%s: %ld won, maxDTM %d plies (%d moves) | full 262144 B -> folded %d B (%.1f KB) | verify: %ld/262144 mismatches %s\n",
               nm[p], won, mx, (mx+1)/2, nCanon*64*64, nCanon*64*64/1024.0, mism, mism? "FAIL":"OK");
        if(mism) allok=0;
        else { FILE*f=fopen(fn[p],"wb"); fwrite(F,1,(size_t)nCanon*64*64,f); fclose(f); }
        free(F); free(slice); free(T);
    }
    printf(allok? "ALL VERIFIED - folded tables written.\n" : "VERIFICATION FAILED - nothing written.\n");
    return allok?0:1;
}
