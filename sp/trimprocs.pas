unit trimprocs;

interface

uses globals;

function Trim (turn, piece, iLoc: integer; var lastMove: moverec; var board: TBoardRecord; var epCapFlag: integer): bitboard;
function combineTrimSide (isBlack: boolean; var lastMove: moverec; var board: TBoardRecord): bitboard;

// procedure CombineTrim (var whiteTrim, blackTrim: bitboard; var lastMove: moverec; var board: TBoardRecord);


implementation

uses resources;

function makeMovementBitboard (pos, ptype: integer; var ownPieces, opponentPieces: bitboard): bitboard;

    const
        LeftVal =  $0A17;	// sla r7, 1
        RightVal = $0917;	// srl r7, 1
        ZeroVal =  $10F1;	// jmp makeray_1
        
    procedure makeRay (var b: bitboard; pos, dy, dx: integer; var ownPieces, opponentPieces: bitboard); assembler;
            lwpi >8320
            mov  @>8314, r10      // copy stack pointer from Pascal runtime workspace
           
            mov  @b, r1
            mov  @ownPieces, r2
            mov  @opponentPieces, r3
            mov  @pos, r4
            mov  @dy, r5
            mov  @dx, r6
           
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
        
    procedure makeRayPascal (var b: bitboard; pos, dy, dx: integer; var ownPieces, opponentPieces: bitboard);
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
    

function Trim (turn, piece, iLoc: integer; var lastMove: moverec; var board: TBoardRecord; var epCapFlag: integer): bitboard;
    var 
        row, epCapSquare: integer;
        bit1, bit2, bit3: bitboard;
    begin
        if piece = Pawn then
            begin
                {trim forward movement to any piece}
                row := iLoc shr 3;
                if turn = 0 then
                    begin
                        result := getMovementBitboard (WhitePawnMove, iLoc) and not board.allPieces or
                                  getMovementBitboard (WhitePawnCapture, iLoc) and board.black.pieces;
                        if (row = 1) and (getBit (result, iLoc + 8) = 0) then
                            clearBit (result, iLoc + 16)
                    end
                else
                    begin
                        result := getMovementBitboard (BlackPawnMove, iLoc) and not board.allPieces or 
                                  getMovementBitboard (BlackPawnCapture, iLoc) and board.white.pieces;
                        if (row = 6) and (getBit (result, iLoc - 8) = 0) then
                            clearBit (result, iLoc - 16)
                    end;

                { check for en passant capture }
                if (lastMove.id = Pawn) and (abs (lastMove.endSq - lastMove.startSq) = 16) and (row = 4 - turn) then
                    begin
                        if turn = 0 then
                            begin
                                bit2 := getEnpassantBitboard (true, lastMove.startSq and 7);
                                epCapSquare := lastMove.startSq - 8
                            end
                        else
                            begin
                                bit2 := getEnpassantBitboard (false, lastMove.startSq and 7);
                                epCapSquare := lastMove.startSq + 8
                            end;
                        {check if pawn on an EP square}
                        if getBit (bit2, iLoc) <> 0 then
                            begin
                                epCapFlag := 1;
                                setBit (result, epCapSquare)
                            end
                    end
                end
        else 
            begin
                if (piece = Knight) or (piece = King) then
                    result := getMovementBitboard (TBitboardType (pred (piece)), iLoc) and not board.side [turn].pieces
                else
                    result := makeMovementBitboard (iLoc, piece, board.side [turn].pieces, board.side [1 - turn].pieces)
            end;
    end;
    
function combineTrimSide (isBlack: boolean; var lastMove: moverec; var board: TBoardRecord): bitboard;
    var
        pieceType, j: integer;
        posArray: bitarray;
        epCapDummy: integer;
        bit: bitboard;
    begin
        clearBitboard (result);
        for pieceType := Pawn to King do
            begin
                BitPos (board.side [ord (isBlack)].bitboards [pieceType], posArray);
                for j := 1 to posArray [0] do
                    result := result or Trim (ord (isBlack), pieceType, posArray [j], lastMove, board, epCapDummy)
            end
    end;        

(*        
procedure CombineTrim (var whiteTrim, blackTrim: bitboard; var lastMove: moverec; var board: TBoardRecord);
    begin
        whiteTrim := combineTrimSide (false, lastmove, board);
        blackTrim := combineTrimSide (true, lastmove, board)
    end;
*)    

end.
