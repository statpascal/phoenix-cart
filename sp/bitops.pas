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

uses bitopsorig, globals;


procedure BitTrimPascal (var b1, b2: bitboard; var n, ptype: integer; flg: integer); 

    type 
        bitboard_byte = array [0..7] of uint8;
        
    procedure trimRay (var b: bitboard_byte; pos, dy, dx, oponent: integer);
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
                if dx = -1 then
                    bitval := bitval shl 1
                else if dx = 1 then
                    bitval := bitval shr 1
            until (row < 0) or (row >= 8) or (bitval > 128) or (bitval = 0) 
        end;
            
    const
        Bishop = 24;
        Rook = 8;
            
    var
        checkLeft, checkRight, checkUp, checkDown: boolean;
        
    begin
        checkLeft := n and 7 <> 0;
        checkRight := succ (n) and 7 <> 0;
        checkUp := n < 56;
        checkDown := n > 7;
        
        if ptype <> Bishop then 
            begin
                if checkUp then
                    trimRay (bitboard_byte (b1), n + 8, 1, 0, flg);		// up
                if checkDown then
                    trimRay (bitboard_byte (b1), n - 8, -1, 0, flg);		// down
                if checkLeft then
                    trimRay (bitboard_byte (b1), n - 1, 0, -1, flg);		// left
                if checkRight then
                    trimRay (bitboard_byte (b1), n + 1, 0, 1, flg)		// right
            end;
        if ptype <> Rook then
            begin
                if checkLeft then
                    begin
                        if checkUp then
                            trimRay (bitboard_byte (b1), n + 7, 1, -1, flg);	// left up
                        if checkDown then
                            trimRay (bitboard_byte (b1), n - 9, -1, -1, flg)	// left down
                    end;
                if checkRight then
                    begin
                        if checkUp then
                            trimRay (bitboard_byte (b1), n + 9, 1, 1, flg);	// right up
                        if checkDown then
                            trimRay (bitboard_byte (b1), n - 7, -1, 1, flg)	// right down
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
        li	r12, 16		// loop over 16 bits
        
    bitpos_2:
        sla	r8, 1
        jnc     bitpos_3
        
        mov	r0, *r13+
        
    bitpos_3:
        inc	r0
        dec 	r12		// bit bounter
        jne	bitpos_2
        
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

// logically AND 2 bitboards
// bitboard1 and bitboard2 are ANDed and the result placed in bitboard3

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


var
    f: text;
    

procedure dumpBoard (var b: bitboard);
    var
        i, j, k: integer;
        help, val: integer;
    begin
        for i := 3 downto 0 do
            begin
                help := b [i];
                for j := 1 to 2 do
                    begin
                        val := help and $ff;
                        for k := 0 to 7 do
                            write (f, ord (val and (1 shl (7 - k)) <> 0));
                        writeln (f);
                        help := help shr 8;
                    end
            end
    end;


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
                    writeln (f, 'Regrssion:');
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
end.
