unit bitops;

interface

type 
    bitboard = uint64;
    bytearray = array [0..7] of uint8;
    
    bitarray = array [0..64] of integer;


procedure BitPos (var b1: bitboard; var posarray: bitarray);
function BitCount (var b: bitboard): integer;

procedure clearBit (var b: bitboard; n: integer);
procedure setBit (var b: bitboard; n: integer); overload;
function getBit (var b: bitboard; n: integer): integer;
procedure setBit (var b: bitboard; pos, val: integer); overload;

procedure ClearBitboard (var b: bitboard);
function IsClear (var b: bitboard): boolean;


implementation

uses globals;

{$ifdef fpc}

var
    bitm: array [0..63] of uint64;
    
procedure initBitmask;
    var 
        i: 0..63;
    begin
        for i := 0 to 63 do
            bitm [(i and $f8) or (7 - i and 7)] := uint64 (1) shl i
        end;

procedure BitPos (var b1: bitboard; var posarray: bitarray);
    var
        i, count: integer;
    begin
        count := 0;
        for i := 0 to 63 do
            if b1 and bitm [i] <> 0 then
                begin
                    inc (count);
                    posarray [count] := i
                end;
        posarray [0] := count
    end;
    
function BitCount (var b: bitboard): integer;
    var
        val: uint64;
        count: integer;
    begin
        count := 0;
        val := b;
        while val <> 0 do 
            begin
                inc (count);
                val := val and pred (val)
            end;
        BitCount := count
    end;
    
procedure clearBit (var b: bitboard; n: integer);
    begin
        b := b and not bitm [n]
    end;
    
procedure setBit (var b: bitboard; n: integer);
    begin
        b := b or bitm [n]
    end;
    
function getBit (var b: bitboard; n: integer): integer;
    begin
        getBit := ord (b and bitm [n] <> 0)
    end;

{$endif}

//extract the board positions of each piece on the board
//intarray will have number of pieces at index 0
//and a sequential list of positions for each piece
//starting at index 1 and board position 

{$ifdef ti99}
procedure BitPos(var b1 : bitboard; var posarray : bitarray); assembler;
        mov  @posarray, r13  
        mov  r13, r12        // R12: first word in posarray: counter
        clr  *r13+           // R13: data pointer
        mov  @b1, r14        // R14: pointer to bitboard
        
        clr  r15             // R0: loop counter over bitboard words
        
    bitpos_1:
        mov  *r14+, r8       // R8: content of bitboard block
        jeq  bitpos_4        // skip if 0
        
        mov  r15, r0
        sla  r0, 4           // piece position (9 - 63)
        
    bitpos_2:
        sla  r8, 1
        joc  bitpos_3
        
        inc  r0
        jmp  bitpos_2
        
    bitpos_3:
        mov  r0, *r13+
        inc  *r12
        inc  r0
        mov  r8, r8          // check if another bit to handle
        jne  bitpos_2
        
    bitpos_4:
        inc  r15
        ci   r15, 4          // word counter
        jne  bitpos_1
end;

function BitCount (var b: bitboard): integer; assembler;
        mov  @b, r0
        li   r12, 4
        clr  r13
        
    bitcount_1:
        mov  *r0+, r14
        
    bitcount_2:
        mov  r14, r15
        jeq  bitcount_3
        dec  r15
        inv  r15
        szc  r15, r14           // r14 = r14 and (r14 - 1) clears rightmost bit
        inc  r13
        jmp  bitcount_2
        
    bitcount_3:
        dec  r12
        jne  bitcount_1
        
        mov  *r10, r12          // store result
        mov  r13, *r12
end;

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
        movb *r12, r12  // byte to check
        mov  *r10, r13  // pointer to result
        clr  *r13       
        sla  r12, 0
        jnc  getbit_1
        
        inc  *r13       // return 1
    getbit_1:        
end;
{$endif}

procedure setBit (var b: bitboard; pos, val: integer);
    begin
        if val = 0 then
            clearBit (b, pos)
        else
            setBit (b, pos)
    end;
    
procedure ClearBitboard (var b: bitboard);
    begin
        fillChar (b, sizeof (b), 0)
    end; 

{$ifdef ti99}
function IsClear(var b: bitboard): boolean; assembler;
        clr  r14
        mov  @b, r12
        mov  *r12+, r13
        soc  *r12+, r13
        soc  *r12+, r13
        soc  *r12, r13
        jne  isclear_done
        li   r14, >0100
    isclear_done:
        mov  *r10, r12
        movb r14, *r12
end;
{$endif}

{$ifdef fpc}
function IsClear(var b: bitboard): boolean;
    begin
        isClear := b = 0
    end;
{$endif}

{$ifdef fpc}
begin
    initBitMask
{$endif}
    
end.
