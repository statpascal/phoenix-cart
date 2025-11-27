unit bitops;

interface

type 
    bitboard = array [0..3] of integer;
    bitarray = array [0..64] of integer;


procedure BitTrim (var b1: bitboard;  pos, ptype, opponent: integer);
procedure BitPos (var b1: bitboard; var posarray: bitarray);

procedure BitNot (var b1, br: bitboard);
procedure BitAnd (var b1, b2, br: bitboard);
procedure BitAndNot (var b1, b2, br: bitboard); assembler;
procedure BitOr (var b1, b2, br: bitboard);
procedure RShift (var b1, br: bitboard; n: integer);
procedure LShift (var b1, br: bitboard; n: integer);

procedure clearBit (var b: bitboard; n: integer);
procedure setBit (var b: bitboard; n: integer);
function getBit (var b: bitboard; n: integer): integer;

implementation

uses bitopsorig, globals;

procedure BitTrim (var b1: bitboard;  pos, ptype, opponent: integer);

    type 
        bitboard_byte = array [0..7] of uint8;
        
    procedure trimRay (var b: bitboard_byte; pos, dy, dxOp, oponent: integer); assembler;
            mov  @pos, r0
            li   r8, >8000
            andi r0, 7
            jeq  trimrayasm_0
            srl  r8, 0		// r8: bitval in high byte
            
        trimrayasm_0
            mov  @pos, r0
            srl  r0, 3		// r0: row
            clr	 r12		// clearing = false
            
        trimrayasm_1:
            mov  @b, r13
            a    r0, r13	// r13 points to b [row]
            
            mov  r12, r12
            jeq  trimrayasm_2	// jump if clearing = false
            
            szcb r8, *r13	// clear bit
            jmp  trimrayasm_3	// next row
            
        trimrayasm_2:
            movb *r13, r14
            coc  r8, r14	// test b [row] and bitval 
            jeq  trimrayasm_3	// bit is set, next row
        
            inc  r12		// clearing = true
            mov  @oponent, r14
            jeq  trimrayasm_3	// next row if opoenent = false
            
            socb r8, *r13	// capture the piece
            
        trimrayasm_3:
            a    @dy, r0
            ci   r0, 7
            jh   trimrayasm_4	// next row and exit when off board
            
            mov  @dxOp, r14
            jeq  trimrayasm_1	// dx is 0, continue with next row
            
            x    r14		// execute left or right shift of R8
            movb r8, r8		// check if high byte is zero
            jne  trimrayasm_1   // continue with next row if bitval is in board
            
        trimrayasm_4:
    end;

    const
        LeftVal = $0A18;	// sla r8, 1
        RightVal = $0918;	// srl r9, 1
        
    procedure trimRayPascal (var b: bitboard_byte; pos, dy, dx, oponent: integer);
        var row, bitval: integer;
            clearing: boolean;
        begin
            clearing := false;
            row := pos shr 3;
            bitval := 1 shl (7 - pos and 7);
            
            repeat
                if clearing then
                    b [row] := b [row] and not bitval
                else if b [row] and bitval = 0 then
                    begin
                        clearing := true;
                        if oponent = 1 then	// capture the piece
                            b [row] := b [row] or bitval
                    end;
                    
                inc (row, dy);
                if dx = LeftVal then
                    bitval := bitval shl 1
                else if dx = RightVal then
                    bitval := bitval shr 1
            until (row < 0) or (row >= 8) or (bitval > 128) or (bitval = 0) 
        end;
            
//    var
//        checkLeft, checkRight, checkUp, checkDown: boolean;
        
    begin
//        checkLeft := pos and 7 <> 0;
//        checkRight := succ (pos) and 7 <> 0;
//        checkUp := pos < 56;
//        checkDown := pos > 7;
        
        if ptype <> Bishop then 
            begin
                if pos < 56 then
                    trimRay (bitboard_byte (b1), pos + 8, 1, 0, opponent);		// up
                if pos > 7 then
                    trimRay (bitboard_byte (b1), pos - 8, -1, 0, opponent);		// down
                if pos and 7 <> 0 then
                    trimRay (bitboard_byte (b1), pos - 1, 0, LeftVal, opponent);	// left
                if succ (pos) and 7 <> 0 then
                    trimRay (bitboard_byte (b1), pos + 1, 0, RightVal, opponent)	// right
            end;
        if ptype <> Rook then
            begin
                if pos and 7 <> 0 then
                    begin
                        if pos < 56 then
                            trimRay (bitboard_byte (b1), pos + 7, 1, LeftVal, opponent);	// left up
                        if pos > 7 then
                            trimRay (bitboard_byte (b1), pos - 9, -1, LeftVal, opponent)	// left down
                    end;
                if succ (pos) and 7 <> 0 then
                    begin
                        if pos < 56 then
                            trimRay (bitboard_byte (b1), pos + 9, 1, RightVal, opponent);	// right up
                        if pos > 7 then
                            trimRay (bitboard_byte (b1), pos - 7, -1, RightVal, opponent)	// right down
                    end
            end
    end;

//extract the board positions of each piece on the board
//intarray will have number of pieces at index 0
//and a sequential list of positions for each piece
//starting at index 1 and board position 

procedure BitPos(var b1 : bitboard; var posarray : bitarray); assembler;
        mov    	@posarray, r13  
        inct   	r13		// R13: data pointer
        mov    	@b1, r14	// R14: pointer to bitboard
        
        clr	r0		// R0: piece positition (0-63)
        li     	r15, 4		// R0: loop counter over bitboard words
        
    bitpos_1:
        mov	*r14+, r8	// R8: content of bitboard block
        jeq	bitpos_4	// skip if 0
        li	r12, 16		// loop over 16 bits
        
    bitpos_2:
        sla	r8, 1
        jnc     bitpos_3
        
        mov	r0, *r13+
        
    bitpos_3:
        inc	r0
        dec 	r12		// bit bounter
        jne	bitpos_2
        jmp	bitpos_5
        
    bitpos_4:
        ai	r0, 16

    bitpos_5:
        dec	r15		// word counter
        jne	bitpos_1
        
        mov    	@posarray, r12  // r12: pointer to posarray
        s	r12, r13
        dect	r13
        srl	r13, 1		// calculate number of pieces
        mov	r13, *r12	// store number of pieces at begin of posarray
end;

// complements a bitboard
// the complement of bitboard1 will be stored in bitboard2

procedure BitNot(var b1, br : bitboard); assembler;
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

// br := b1 and b2

procedure BitAnd(var b1, b2, br : bitboard); assembler;
        mov     @br, r15        //get pointer to bitboard3
        mov     @b2, r14        //get pointer to bitboard2
        mov     @b1, r13        //get pointer to bitboard1
        
        mov 	*r13+, r0
        mov	*r14+, r12
        inv	r12
        szc	r12, r0
        mov	r0, *r15+
        
        mov 	*r13+, r0
        mov	*r14+, r12
        inv	r12
        szc	r12, r0
        mov	r0, *r15+
        
        mov 	*r13+, r0
        mov	*r14+, r12
        inv	r12
        szc	r12, r0
        mov	r0, *r15+

        mov 	*r13, r0
        mov	*r14, r12
        inv	r12
        szc	r12, r0
        mov	r0, *r15
(*        
        mov 	*r13+, *r15
        mov	*r14+, r12
        inv	r12
        szc	r12, *r15+
        
        mov 	*r13+, *r15
        mov	*r14+, r12
        inv	r12
        szc	r12, *r15+
        
        mov 	*r13+, *r15
        mov	*r14+, r12
        inv	r12
        szc	r12, *r15+
        
        mov 	*r13, *r15
        mov	*r14, r12
        inv	r12
        szc	r12, *r15
*)
end;

// br := b1 and not b2

procedure BitAndNot (var b1, b2, br : bitboard); assembler;
        mov     @br, r15        //get pointer to bitboard3
        mov     @b2, r14        //get pointer to bitboard2
        mov     @b1, r13        //get pointer to bitboard1
        
        mov 	*r13+, r0
        szc	*r14+, r0
        mov	r0, *r15+
        
        mov 	*r13+, r0
        szc	*r14+, r0
        mov	r0, *r15+
        
        mov 	*r13+, r0
        szc	*r14+, r0
        mov	r0, *r15+

        mov 	*r13, r0
        szc	*r14, r0
        mov	r0, *r15
end;

//logicaly OR two bitboards
//bitboard1 and bitboard2 are ORed and the result placed in bitboard3

procedure BitOr(var b1, b2, br : bitboard); assembler;
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

procedure RShift(var b1, br : bitboard; n : integer); assembler;
        lwpi    >8320
        mov     @>8314, r10      // copy stack pointer from Pascal runtime workspace

        mov     @n,r5           //get number of shifts
        mov     @br,r7          //get pointer to bitboard2
        mov     @b1,r6          //get pointer to bitboard1
        mov     *r6+,r4         //transfer bitboard1 to regs 4-1
        mov     *r6+,r3
        mov     *r6+,r2
        mov     *r6,r1
    nxtshft 
        srl     r1,1            //right shift r1-r4 sequentially 1 position
        srl     r2,1
        jnc     notset1         //transfer carry bit to previous register if set
        ori     r1,>8000
    notset1 
        srl     r3,1
        jnc     notset2
        ori     r2,>8000
    notset2 
        srl     r4,1
        jnc     notset3
        ori     r3,>8000
    notset3 	
        dec     r5              //done with shifts?
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

procedure LShift(var b1, br : bitboard; n : integer); assembler;
        lwpi    >8320
        mov     @>8314, r10      // copy stack pointer from Pascal runtime workspace

        mov     @n,r5           //get number of shifts
        mov     @br,r7          //get pointer to bitboard2
        mov     @b1,r6          //get pointer to bitboard1
        mov     *r6+,r4         //transfer bitboard1 to r4-r1
        mov     *r6+,r3
        mov     *r6+,r2
        mov     *r6,r1
    newshft 
        sla     r4,1            //left shift r4-r1 in sequence 1 position
        sla     r3,1
        jnc     nocar1          //transfer carry bit to next register if set
        ori     r4,>0001
    nocar1  
        sla     r2,1
        jnc     nocar2
        ori     r3,>0001
    nocar2  
        sla     r1,1
        jnc     nocar3
        ori     r2,>0001
    nocar3  
        dec     r5              //done with shifts?
        jne     newshft
        mov     r4,*r7+         //save shifted bitboard1 to bitboard2
        mov     r3,*r7+
        mov     r2,*r7+
        mov     r1,*r7

        lwpi    >8300
end;

const
    bitmasks: array [0..7] of uint8 = ($80, $40, $20, $10, $08, $04, $02, $01);

procedure clearBit (var b: bitboard; n: integer); assembler;
        mov  @b, r12
        mov  @n, r13
        mov  r13, r14
        srl  r13, 3
        andi r14, 7
        a    r13, r12
        szcb @bitmasks(r14), *r12
end;

procedure setBit (var b: bitboard; n: integer); assembler;
        mov  @b, r12
        mov  @n, r13
        mov  r13, r14
        srl  r13, 3
        andi r14, 7
        a    r13, r12
        socb @bitmasks(r14), *r12
end;

function getBit (var b: bitboard; n: integer): integer; assembler;
        mov  @b, r12
        mov  @n, r13
        mov  r13, r0
        srl  r13, 3
        andi r0, 7
        inc  r0
        a    r13, r12
        movb *r12, r12	// byte to check
        mov  *r10, r13	// pointer to result
        clr  *r13	
        sla  r12, 0
        jnc  getbit_1
        
        inc  *r13	// return 1
    getbit_1:        
end;

(*

procedure dumpBoard (var b: bitboard);
    var
        i, j, k, val: integer;
    begin
        for i := 3 downto 0 do
            begin
                val := b [i];
                for j := 1 to 2 do
                    begin
                        for k := 0 to 7 do
                            write (f, ord (val and (1 shl (7 - k)) <> 0));
                        writeln (f);
                        val := val shr 8;
                    end
            end
    end;
    
var
    f: text;

procedure BitTrim (var b1, b2: bitboard; var n, ptype: integer; flg: integer);
    var
        i: integer;
        bin, bcopy: bitboard;
    begin

        if savePositions then
            begin
             
                bin := b1;   
                bcopy := b1;
                
                BittrimPascal (b1, b2, n, ptype, flg);
                BittrimOrig (bcopy, b2, n, ptype, flg);
                
                if not compareWord (b1, bcopy, 4) then begin
                    writeln (f, 'Regression:');
                    
                    write (f, 'IN:  ');
                    for i := 0 to 3 do
                        write (f, hexstr (bin [i]):5);
                    for i := 0 to 3 do
                        write (f, hexstr (b2 [i]):5);
                    writeln (f, n:3, ptype:3,flg:3);
                    
                    write (f, 'OUT orig: ');
                    for i := 0 to 3 do
                        write (f, hexstr (bcopy [i]):5);
                    for i := 0 to 3 do
                        write (f, hexstr (b2 [i]):5);
                    writeln (f, n:3, ptype:3,flg:3);
                    
                    write (f, 'OUT new:  ');
                    for i := 0 to 3 do
                        write (f, hexstr (b1 [i]):5);
                    for i := 0 to 3 do
                        write (f, hexstr (b2 [i]):5);
                    writeln (f, n:3, ptype:3,flg:3);
                end
            end
        else
            BittrimPascal (b1, b2, n, ptype, flg)
    end;
    
begin
    assign (f, 'DSK0.trimlog.txt');
    rewrite (f)
    
*)    
    
end.
