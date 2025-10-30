
unit bitops;

interface

type 
    bitboard =   array[0..3] of integer;
    bitarray =   array[0..64] of integer;


procedure BitTrim(var b1, b2 : bitboard; var n, ptype : integer; flg : integer);
procedure BitPos(var b1 : bitboard; var posarray : bitarray);

procedure BitNot(var b1, br : bitboard);
procedure BitAnd(var b1, b2, br : bitboard);
procedure BitOr(var b1, b2, br : bitboard);
procedure RShift(var b1, br : bitboard; n : integer);
procedure LShift(var b1, br : bitboard; n : integer);


implementation

var 
    iloc, disp, cumdisp, flag, oflag, subrtn, subrtn1, pcount: integer;
    dbyte: uint8;

const 
    vflag: integer =   0;
    zero: integer =   0;
    bittab: array [0..7] of uint8 =   (128,64,32,16,8,4,2,1);

procedure dummy;
assembler;
// not called; provides assembler block
clr     r0 // TODO: dummy op - avoid double lables
//trim a ray to empty squares
trimray mov     r11,@subrtn1
nxtsqr  a       @disp,@cumdisp
mov     @cumdisp,r4
ci      r4,0            //check if location off bottom of board
jlt     done
ci      r4,63           //check if location off top of board
jgt     done
bl      @bitchk         //check value of bit at new location
ci      r5,0            //is bit value 0?
jne     next
c       @flag,@zero     //check if zero flag already set
jne     sidebit
inc     @flag           //set zero flag
c       @oflag,@zero    //check of opponent flag set
jeq     sidebit
clr     r5              //set the displacement bit
movb    *r4,r5
inv     r6
socb    r6,r5
movb    r5,*r4
inv     r6
sidebit c       @vflag,@zero
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
jmp     done
next    c       @flag,@zero
jeq     sidebit
inv     r6
clr     r5
movb    *r4,r5
szcb    r6,r5
movb    r5,*r4          //clear the displacement bit
inv     r6
jmp     sidebit
done    mov     @subrtn1,r11
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
end;

//trim sliding pieces movement rays
//rays will be trimmed to first empty square
//bitboard1 is untrimmed movement bitboard
//bitboard2 is the sides bitboard (left and right sides set to 1)
//intloc is starting position of sliding piece
//inttype is piece type : r=8, b=24, q=32
//flag = 1 when trimming for opponent pieces, otherwise 0 

procedure BitTrim(var b1, b2: bitboard; var n, ptype: integer; flg: integer);
assembler;
lwpi    >8320
mov     @>8314, r10 // copy stack pointer from Pascal runtime workspace

mov     @flg,@oflag    //get opponent flag value
mov     @ptype,r0       //get pointer to piece type
mov     @n,r1           //get pointer to intloc
mov     @b2,r2          //get pointer to bitboard2
mov     @b1,r3          //get pointer to bitboard1

mov     *r1,r4          // get piece location
mov     r4,@iloc        // save piece location
mov     r4,@cumdisp
mov     *r0,r5          // get value of piece type
ci      r5,24           // check if bishop
jeq     bishop
// up ray
clr     @flag
inc     @vflag
li      r5,8            // displacement value
mov     r5,@disp
bl      @trimray
// down ray
clr     @flag
mov     @iloc,@cumdisp
li      r5,-8
mov     r5,@disp
bl      @trimray
// left ray
clr     @flag
clr     @vflag
bl      @l_edge         // check if already at left edge
ci      r5,0
jne     rray
mov     @iloc,@cumdisp
li      r5,-1
mov     r5,@disp
bl      @trimray
// right ray
rray    clr     @flag
bl      @r_edge         // check if already at right edge
ci      r5,0
jne     isrook
mov     @iloc,@cumdisp
li      r5,1
mov     r5,@disp
bl      @trimray
isrook  mov     *r0,r5
ci      r5,8
jeq     finish
// left upper ray
bishop  clr     @flag
bl      @l_edge         // check if already at left edge
ci      r5,0
jne     rcheck
mov     @iloc,@cumdisp
li      r5,7
mov     r5,@disp
bl      @trimray
// left lower ray
clr     @flag
mov     @iloc,@cumdisp
li      r5,-9
mov     r5,@disp
bl      @trimray
rcheck  // right upper ray
clr     @flag
bl      @r_edge         // check if already at right edge
ci      r5,0
jne     finish
mov     @iloc,@cumdisp
li      r5,9
mov     r5,@disp
bl      @trimray
// right lower ray
clr     @flag
mov     @iloc,@cumdisp
li      r5,-7
mov     r5,@disp
bl      @trimray
finish
lwpi    >8300
end;

//extract the board positions of each piece on the board
//intarray will have number of pieces at index 0
//and a sequential list of positions for each piece
//starting at index 1 and board position 

procedure BitPos(var b1 : bitboard; var posarray : bitarray);
assembler;
lwpi    >8320
mov     @>8314, r10 // copy stack pointer from Pascal runtime workspace

mov     @posarray,r1        //get array pointer
mov     @b1,r3        //get bitboard pointer
clr     r0              //initialize position marker
clr     r4              //initialize board position
clr     @pcount         //initialize piece counter
mov     r1,r2           //save array pointer
inct    r1              //point to array index 1
nextpos bl      @bitchk         //get value of bit in msb of r5
ci      r5,0
jeq     nopiece
mov     r0,*r1+         //store piece position in array
inc     @pcount         //update piece counter
nopiece inc     r0
mov     r0,r4
ci      r4,63           //check if end of bitboard reached
jgt     donebrd
jmp     nextpos
donebrd mov     @pcount,*r2     //store pieces number in array

lwpi    >8300
end;

//complements a bitboard
//the complement of bitboard1 will be stored in bitboard2

procedure BitNot(var b1, br : bitboard);
assembler;
lwpi    >8320
mov     @>8314, r10      // copy stack pointer from Pascal runtime workspace

mov     @br,r6          //get pointer to bitboard2
mov     @b1,r5          //get pointer to bitboard1
mov     *r5+,r4         //protect content of bitboard1
inv     r4              //complement bitboard1
mov     r4,*r6+         //store in bitboard2
mov     *r5+,r4
inv     r4
mov     r4,*r6+
mov     *r5+,r4
inv     r4
mov     r4,*r6+
mov     *r5,r4
inv     r4
mov     r4,*r6

lwpi    >8300
end;

//logically AND 2 bitboards
//bitboard1 and bitboard2 are ANDed and the result placed in bitboard3

procedure BitAnd(var b1, b2, br : bitboard);
assembler;
lwpi    >8320
mov     @>8314, r10      // copy stack pointer from Pascal runtime workspace

mov     @br,r7        //get pointer to bitboard3
mov     @b2,r6        //get pointer to bitboard2
mov     @b1,r5         //get pointer to bitboard1
mov     *r5+,r3         //protect contents of bitboard1 and bitboard2
mov     *r6+,r4
inv     r3              //AND bitboard1 with bitboard 2
szc     r3,r4           //inv then szc = and
mov     r4,*r7+         //save result in bitboard3
mov     *r5+,r3
mov     *r6+,r4
inv     r3
szc     r3,r4
mov     r4,*r7+
mov     *r5+,r3
mov     *r6+,r4
inv     r3
szc     r3,r4
mov     r4,*r7+
mov     *r5,r3
mov     *r6,r4
inv     r3
szc     r3,r4
mov     r4,*r7

lwpi    >8300
end;

//logicaly OR two bitboards
//bitboard1 and bitboard2 are ORed and the result placed in bitboard3

procedure BitOr(var b1, b2, br : bitboard);
assembler;
lwpi    >8320
mov     @>8314, r10      // copy stack pointer from Pascal runtime workspace

mov     @br,r7          //get pointer to bitboard3
mov     @b2,r6          //get pointer to bitboard2
mov     @b1,r5          //get pointer to bitboard1
mov     *r6+,r3         //protect contents of bitboard2
soc     *r5+,r3         //or bitboard1 and bitboard2
mov     r3,*r7+         //store result in bitboard3
mov     *r6+,r3
soc     *r5+,r3
mov     r3,*r7+
mov     *r6+,r3
soc     *r5+,r3
mov     r3,*r7+
mov     *r6,r3
soc     *r5,r3
mov     r3,*r7

lwpi    >8300
end;


//logically right shift a bitboard
//bitboard1 is logically right shifted intnum times
//the result is placed in bitboard2

procedure RShift(var b1, br : bitboard; n : integer);
assembler;
lwpi    >8320
mov     @>8314, r10      // copy stack pointer from Pascal runtime workspace

mov     @n,r5           //get number of shifts
mov     @br,r7          //get pointer to bitboard2
mov     @b1,r6          //get pointer to bitboard1
mov     *r6+,r4         //transfer bitboard1 to regs 4-1
mov     *r6+,r3
mov     *r6+,r2
mov     *r6,r1
nxtshft srl     r1,1            //right shift r1-r4 sequentially 1 position
srl     r2,1
jnc     notset1         //transfer carry bit to previous register if set
ori     r1,>8000
notset1 srl     r3,1
jnc     notset2
ori     r2,>8000
notset2 srl     r4,1
jnc     notset3
ori     r3,>8000
notset3 dec     r5              //done with shifts?
jne     nxtshft
mov     r4,*r7+         //save shifted bitboard1 to bitboard2
mov     r3,*r7+
mov     r2,*r7+
mov     r1,*r7

lwpi    >8300
end;

//logically left shift a bitboard
//bitboard1 is logically left shifted intnum times
//the result is placed in bitboard2

procedure LShift(var b1, br : bitboard; n : integer);
assembler;
lwpi    >8320
mov     @>8314, r10      // copy stack pointer from Pascal runtime workspace

mov     @n,r5           //get number of shifts
mov     @br,r7          //get pointer to bitboard2
mov     @b1,r6          //get pointer to bitboard1
mov     *r6+,r4         //transfer bitboard1 to r4-r1
mov     *r6+,r3
mov     *r6+,r2
mov     *r6,r1
newshft sla     r4,1            //left shift r4-r1 in sequence 1 position
sla     r3,1
jnc     nocar1          //transfer carry bit to next register if set
ori     r4,>0001
nocar1  sla     r2,1
jnc     nocar2
ori     r3,>0001
nocar2  sla     r1,1
jnc     nocar3
ori     r2,>0001
nocar3  dec     r5              //done with shifts?
jne     newshft
mov     r4,*r7+         //save shifted bitboard1 to bitboard2
mov     r3,*r7+
mov     r2,*r7+
mov     r1,*r7

lwpi    >8300
end;


// TODO: force inclusion

var p: pointer;

begin
    p := addr (dummy)
end.
