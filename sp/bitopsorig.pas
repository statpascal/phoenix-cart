unit bitopsorig;

interface

uses bitops;

procedure BitTrimOrig(var b1, b2 : bitboard; var n, ptype : integer; flg : integer);


implementation

var 
    iloc, disp, cumdisp, flag, oflag, subrtn, subrtn1, pcount: integer;
    dbyte: uint8;

const 
    vflag: integer =   0;
    zero: integer =   0;
    bittab: array [0..7] of uint8 =   (128,64,32,16,8,4,2,1);


//trim sliding pieces movement rays
//rays will be trimmed to first empty square
//bitboard1 is untrimmed movement bitboard
//bitboard2 is the sides bitboard (left and right sides set to 1)
//intloc is starting position of sliding piece
//inttype is piece type : r=8, b=24, q=32
//flag = 1 when trimming for opponent pieces, otherwise 0 

procedure BitTrimOrig(var b1, b2: bitboard; var n, ptype: integer; flg: integer);
assembler;
lwpi    >8320
mov     @>8314, r10 // copy stack pointer from Pascal runtime workspace

b @startofproc

clr     r0 // TODO: dummy op - avoid double lables
//trim a ray to empty squares
trimrayorig mov     r11,@subrtn1
nxtsqr  a       @disp,@cumdisp
mov     @cumdisp,r4
ci      r4,0            //check if location off bottom of board
jlt     doneorigorig
ci      r4,63           //check if location off top of board
jgt     doneorigorig
bl      @bitchk         //check value of bit at new location
ci      r5,0            //is bit value 0?
jne     nextorig
c       @flag,@zero     //check if zero flag already set
jne     sidebitorig
inc     @flag           //set zero flag
c       @oflag,@zero    //check of opponent flag set
jeq     sidebitorig
clr     r5              //set the displacement bit
movb    *r4,r5
inv     r6
socb    r6,r5
movb    r5,*r4
inv     r6
sidebitorig c       @vflag,@zero
jne     nxtsqr
clr     r4
movb    @dbyte,r4       //get byte displacement
swpb    r4
a       r2,r4           //point to byte in side bitboard
clr     r5
movb    *r4,r5
szcb    r6,r5           //r5 now has value of sides bitboard bit
ci      r5,0
jeq     nxtsqr
jmp     doneorigorig
nextorig    c       @flag,@zero
jeq     sidebitorig
inv     r6
clr     r5
movb    *r4,r5
szcb    r6,r5
movb    r5,*r4          //clear the displacement bit
inv     r6
jmp     sidebitorig
doneorigorig    mov     @subrtn1,r11
b       *r11

//return value of displacement bit in r5
//r4 has the bitboard position
bitchk  clr     r7              //clear index to bittab
mov     r4,r5           //point to displacement square
mov     r5,r6
srl     r5,3            //calculate byte displacement (DIV 8)
mov     r5,r4           //save byte displacement
sla     r5,3            //multiply by 8
jmp     trgchk
nxtbit  inc     r5              //add a bit to the byte
inc     r7              //increment bit mask table index
trgchk  c       r5,r6           //are we at the displacement bit?
jne     nxtbit
swpb    r4
movb    r4,@dbyte       //store byte displacement
swpb    r4
a       r3,r4           //point to byte in bitboard
clr     r5
movb    *r4,r5          //get displacement byte content
clr     r6
movb    @bittab(r7),r6
inv     r6
szcb    r6,r5           //high byte of r5 has value of displacement bit
b       *r11

//check if at left edge of board
l_edge  mov     r11,@subrtn1
clr     r5
mov     @iloc,r4
ci      r4,0
jeq     atedge
ci      r4,8
jeq     atedge
ci      r4,16
jeq     atedge
ci      r4,24
jeq     atedge
ci      r4,32
jeq     atedge
ci      r4,40
jeq     atedge
ci      r4,48
jeq     atedge
ci      r4,56
jeq     atedge
jmp     notedge
atedge  inc     r5
notedge mov     @subrtn1,r11
b       *r11

//check if at right edge of board
r_edge  mov     r11,@subrtn1
clr     r5
mov     @iloc,r4
ci      r4,7
jeq     atedge1
ci      r4,15
jeq     atedge1
ci      r4,23
jeq     atedge1
ci      r4,31
jeq     atedge1
ci      r4,39
jeq     atedge1
ci      r4,47
jeq     atedge1
ci      r4,55
jeq     atedge1
ci      r4,63
jeq     atedge1
jmp     noedge
atedge1 inc     r5
noedge  mov     @subrtn1,r11
b       *r11


startofproc:


mov     @flg,@oflag    //get opponent flag value
mov     @ptype,r0       //get pointer to piece type
mov     @n,r1           //get pointer to intloc
mov     @b2,r2          //get pointer to bitboard2
mov     @b1,r3          //get pointer to bitboard1

mov     *r1,r4          // get piece location
mov     r4,@iloc        // save piece location
mov     r4,@cumdisp
mov     *r0,r5          // get value of piece type
ci      r5,24           // check if bishoporig
jeq     bishoporig
// up ray
clr     @flag
inc     @vflag
li      r5,8            // displacement value
mov     r5,@disp
bl      @trimrayorig
// down ray
clr     @flag
mov     @iloc,@cumdisp
li      r5,-8
mov     r5,@disp
bl      @trimrayorig
// left ray
clr     @flag
clr     @vflag
bl      @l_edge         // check if already at left edge
ci      r5,0
jne     rrayorig
mov     @iloc,@cumdisp
li      r5,-1
mov     r5,@disp
bl      @trimrayorig
// right ray
rrayorig    clr     @flag
bl      @r_edge         // check if already at right edge
ci      r5,0
jne     isrookorig
mov     @iloc,@cumdisp
li      r5,1
mov     r5,@disp
bl      @trimrayorig
isrookorig  mov     *r0,r5
ci      r5,8
jeq     finishorig
// left upper ray
bishoporig  clr     @flag
bl      @l_edge         // check if already at left edge
ci      r5,0
jne     rcheckorig
mov     @iloc,@cumdisp
li      r5,7
mov     r5,@disp
bl      @trimrayorig
// left lower ray
clr     @flag
mov     @iloc,@cumdisp
li      r5,-9
mov     r5,@disp
bl      @trimrayorig
rcheckorig  // right upper ray
clr     @flag
bl      @r_edge         // check if already at right edge
ci      r5,0
jne     finishorig
mov     @iloc,@cumdisp
li      r5,9
mov     r5,@disp
bl      @trimrayorig
// right lower ray
clr     @flag
mov     @iloc,@cumdisp
li      r5,-7
mov     r5,@disp
bl      @trimrayorig
finishorig
lwpi    >8300
end;

end.
