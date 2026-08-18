# KRvK / KQvK endgame tables — symmetry folding + a generator fix

Everything below is **verified** by `kxk_gen_folded.c` in this folder: it solves the tables,
folds them, and checks the folded lookup reproduces the full 262,144-position table exactly
(0 mismatches) before writing anything.

## 1. Folding 

These endgames are **pawnless**, so the full **8-fold** board symmetry applies (the dihedral
group of the square: 2 mirrors + 2 diagonals = 8 transforms). You get better than the ×4 from
rotations alone:

- **Canonicalise on the strong king**: fold it into the 10-square corner triangle
  `a1,b1,c1,d1,b2,c2,d2,c3,d3,d4` (64 → 10). Apply the **same** transform to the weak king and
  the piece, then look up.
- **Table size: 10 × 64 × 64 = 40,960 bytes** per endgame (from 262,144). KRvK + KQvK = **80 KB**.
- DTM is **symmetry-invariant**, so this is exact — no loss. (Rotations-only, if you prefer:
  fold to a 16-square quadrant → 64 KB each.)

### The lookup (C, straight from the verified generator)

```c
/* the 8 board symmetries, square 0..63 (a1=0..h8=63) */
static int sym(int t,int s){
    int r=s/8,f=s%8,nr,nf;
    switch(t){
        case 0: nr=r;   nf=f;   break;   case 1: nr=r;   nf=7-f; break;  /* id, flip files   */
        case 2: nr=7-r; nf=f;   break;   case 3: nr=7-r; nf=7-f; break;  /* flip ranks, 180  */
        case 4: nr=f;   nf=r;   break;   case 5: nr=7-f; nf=7-r; break;  /* diag, anti-diag  */
        case 6: nr=f;   nf=7-r; break;   default:nr=7-f; nf=r;   break;  /* rot 90, rot 270  */
    }
    return nr*8+nf;
}
/* precompute once: canonT[s] = transform mapping s to the min of its orbit;
   canonIdx[s] = 0..9 for the 10 canonical squares, -1 otherwise. */
int canonT[64], canonIdx[64], nCanon=0;
void initCanon(void){
    for(int s=0;s<64;s++){ int best=100,bt=0;
        for(int t=0;t<8;t++){int im=sym(t,s); if(im<best){best=im;bt=t;}} canonT[s]=bt; }
    for(int s=0;s<64;s++) canonIdx[s]=-1;
    for(int s=0;s<64;s++) if(sym(canonT[s],s)==s) canonIdx[s]=nCanon++;   /* nCanon == 10 */
}
/* folded lookup: F is the 40960-byte table; returns plies-to-mate (255 = draw, 254 = illegal) */
unsigned char lookupFolded(unsigned char *F,int sK,int wK,int pc){
    int t=canonT[sK];
    return F[((size_t)canonIdx[sym(t,sK)]*64 + sym(t,wK))*64 + sym(t,pc)];
}
```

If the **weak** side is white/strong-is-black, flip all three squares with `sq xor 56` first
(as the root-hook design already does), look up, then flip the chosen move's squares back.

### Reference StatPascal for the cart

```pascal
{ folded KRvK/KQvK table embedded as a ROM resource, 40960 bytes }
procedure ext_krk; external '../resources/krk_dtm_folded.dat';
var krkFold: array [0 .. 10*64*64 - 1] of uint8 absolute ext_krk;

const symTab: array [0..7, 0..63] of uint8 = ( {...precompute or generate at init...} );
var   canonT, canonIdx: array [0..63] of integer;   { fill once at startup as in initCanon }

function lookupFolded (sK, wK, pc: integer): uint8;
    var t: integer;
    begin
        t := canonT [sK];
        lookupFolded := krkFold [(canonIdx [symTab[t,sK]] * 64 + symTab[t,wK]) * 64 + symTab[t,pc]]
    end;
```

`symTab` is just `sym(t,s)` tabulated (8×64 bytes); `canonT`/`canonIdx` fill from a ~10-line
init loop. All tiny.
