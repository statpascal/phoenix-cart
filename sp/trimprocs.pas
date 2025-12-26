unit trimprocs;

interface

uses bitops, globals;

function Trim (turn, piece, iLoc: integer; var board: TBoardRecord; var epCapSquare: integer): bitboard;
function combineTrimSide (isBlack: boolean; var board: TBoardRecord): bitboard;


implementation

uses resources;

function makeMovementBitboard (pos, ptype: integer; var ownPieces, opponentPieces: bitboard): bitboard;

    const
        LeftVal =  $0A17;	// sla r7, 1
        RightVal = $0917;	// srl r7, 1
        ZeroVal =  $10F1;	// jmp makeray_1
        
{$ifdef ti99}        
    procedure makeRay (var b: bitboard; pos, dy, dx: integer; var ownPieces, opponentPieces: bitboard); assembler;
            lwpi >8320
            mov  @>8314, r10      // copy stack pointer from Pascal runtime workspace
           
            mov  *r10+, r1	// b
            mov  *r10+, r4	// pos
            mov  *r10+, r5	// dy
            mov  *r10+, r6	// dx
            mov  *r10+, r2	// pointer to ownPieces
            mov  *r10, r3	// pointer to oppentPieces
           
            mov  r4, r0
            srl  r0, 3		// r0: row
            
            a    r0, r1		// r1: pointer to row in result bitboard
            a    r0, r2		// r2: pointer to row in ownpieces
            a    r0, r3		// r3: pointer to row in opponentpieces
           
            clr  r8
            clr  r7
            andi r4, 7
            movb @bitmasks(r4), r7	// bitmask in high byte of r7
           
        makeray_1:
            movb *r2, r8
            coc  r7, r8			
            jeq  makeray_2		// own piece reached: exit
            
            socb r7, *r1		// can move to square
            
            movb *r3, r8
            coc  r7, r8
            jeq  makeray_2		// opponent piece captured: exit
                    
            a    r5, r0
            ci   r0, 7
            jh   makeray_2		// off board top or bottom: exit
            a    r5, r1			// add dy to borad pointers
            a    r5, r2
            a    r5, r3
            
            x    r6			// left/right shift of r7 or jump to makeray_1
            movb r7, r7			// check if high byte zero: off board left or right
            jne  makeray_1
            
        makeray_2:            
            lwpi >8300
    end;
{$endif}    
        
{$ifdef fpc}        
    procedure makeRay (var b: bitboard; pos, dy, dx: integer; var ownPieces, opponentPieces: bitboard);
        var row, bitval: integer;
        begin
            row := pos shr 3;
            bitval := 1 shl (7 - pos and 7);
            
            repeat
                if bytearray (ownPieces) [row] and bitval <> 0 
                    then exit;
                bytearray (b) [row] := bytearray (b) [row] or bitval;
                if bytearray (opponentPieces) [row] and bitval <> 0
                    then exit;
                    
                inc (row, dy);
                if dx = LeftVal then
                    bitval := bitval shl 1
                else if dx = RightVal then
                    bitval := bitval shr 1
            until (row < 0) or (row >= 8) or (bitval > 128) or (bitval = 0) 
        end;
{$endif}        
        
    begin
        clearBitboard (result);
        if ptype <> Bishop then 
            begin
                if pos < 56 then
                    makeRay (result, pos + 8, 1, ZeroVal, ownPieces, opponentPieces);		// up
                if pos > 7 then
                    makeRay (result, pos - 8, -1, ZeroVal, ownPieces, opponentPieces);		// down
                if pos and 7 <> 0 then
                    makeRay (result, pos - 1, 0, LeftVal, ownPieces, opponentPieces);	// left
                if succ (pos) and 7 <> 0 then
                    makeRay (result, pos + 1, 0, RightVal, ownPieces, opponentPieces)	// right
            end;
        if ptype <> Rook then
            begin
                if pos and 7 <> 0 then
                    begin
                        if pos < 56 then
                            makeRay (result, pos + 7, 1, LeftVal, ownPieces, opponentPieces);	// left up
                        if pos > 7 then
                            makeRay (result, pos - 9, -1, LeftVal, ownPieces, opponentPieces)	// left down
                    end;
                if succ (pos) and 7 <> 0 then
                    begin
                        if pos < 56 then
                            makeRay (result, pos + 9, 1, RightVal, ownPieces, opponentPieces);	// right up
                        if pos > 7 then
                            makeRay (result, pos - 7, -1, RightVal, ownPieces, opponentPieces)	// right down
                    end
            end
    end;
    

function Trim (turn, piece, iLoc: integer; var board: TBoardRecord; var epCapSquare: integer): bitboard;
    var 
        row: integer;
        bits: bitboard;
    begin
        epCapSquare := -1;
        if piece = Pawn then
            begin
                row := iLoc shr 3;
                result := getPawnMovementBitboard (turn, iLoc) and not board.allPieces or
                          getPawnCaptureBitboard (turn, iLoc) and board.sides [1 - turn].pieces;
                if turn = 0 then
                    begin
                        if (row = 1) and (getBit (result, iLoc + 8) = 0) then
                            clearBit (result, iLoc + 16)
                    end
                else
                    begin
                        if (row = 6) and (getBit (result, iLoc - 8) = 0) then
                            clearBit (result, iLoc - 16)
                    end;

                { check for en passant capture }
                if (board.castleFlags and epMoveFlag <> 0) and (row = 4 - turn) then
                    begin
                        bits := getEnpassantBitboard (turn = 0, board.castleFlags and epColBitmask);
                        epCapSquare := 16 + board.castleFlags and epColBitmask + 24 * ord (board.castleFlags and epWhiteFlag = 0);
                        if getBit (bits, iLoc) <> 0 then
                            setBit (result, epCapSquare)
                        else
                            epCapSquare := -1
                    end
                end
        else 
            case piece of
                Knight:
                    result := getKnightMovementBitboard (iLoc) and not board.sides [turn].pieces;
                King:
                    result := getKingMovementBitboard (iLoc) and not board.sides [turn].pieces
                else
                    result := makeMovementBitboard (iLoc, piece, board.sides [turn].pieces, board.sides [1 - turn].pieces)
            end;
    end;
    
function combineTrimSide (isBlack: boolean; var board: TBoardRecord): bitboard;
    var
        pieceType, j: integer;
        posArray: bitarray;
        epCapDummy: integer;
        bit: bitboard;
    begin
        clearBitboard (result);
        for pieceType := Pawn to King do
            begin
                BitPos (board.sides [ord (isBlack)].bitboards [pieceType], posArray);
                for j := 1 to posArray [0] do
                    result := result or Trim (ord (isBlack), pieceType, posArray [j], board, epCapDummy)
            end
    end;        

end.
