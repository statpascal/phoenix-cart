unit trimprocs;

interface

uses globals;

function Trim (turn, piece, iLoc: integer; var lastMove: moverec; var board: TBoardRecord; var epCapFlag: integer): bitboard;
function combineTrimSide (isBlack: boolean; var lastMove: moverec; var board: TBoardRecord): bitboard;

procedure CombineTrim (var whiteTrim, blackTrim: bitboard; var lastMove: moverec; var board: TBoardRecord);


implementation

uses resources;

function Trim (turn, piece, iLoc: integer; var lastMove: moverec; var board: TBoardRecord; var epCapFlag: integer): bitboard;
    var 
        row, col, bitmask, epCapSquare: integer;
        bit1, bit2, bit3: bitboard;
    begin
        if piece = Pawn then
            begin
                {trim forward movement to any piece}
                if turn = 0 then
                    result := getMovementBitboard (WhitePawnMove, iLoc) and not board.allPieces or
                              getMovementBitboard (WhitePawnCapture, iLoc) and board.black.pieces
                else
                    result := getMovementBitboard (BlackPawnMove, iLoc) and not board.allPieces or 
                              getMovementBitboard (BlackPawnCapture, iLoc) and board.white.pieces;
                    
                row := iLoc shr 3;
                if (turn = 0) and (row = 1) and (getBit (result, iLoc + 8) = 0) then
                    clearBit (result, iLoc + 16);
                if (turn = 1) and (row = 6) and (getBit (result, iLoc - 8) = 0) then
                    clearBit (result, iLoc - 16);
                    
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
                bit1 := getMovementBitboard (TBitboardType (pred (piece)), iLoc);
                if (piece = Knight) or (piece = King) then
                    result := bit1 and not board.side [turn].pieces
                else
                    {trim sliding pieces movement rays past blocking pieces}
                    begin
                        {trim to white pieces - turn indicates if this is opponent/own}
                        bit2 := bit1 and not board.white.pieces;
                        BitTrim (bit2, iLoc, piece, turn);

                        {trim to black pieces pieces, with turn inverted}
                        bit3 := bit1 and not board.black.pieces;
                        BitTrim (bit3, iLoc, piece, 1 - turn);

                        result := bit2 and bit3
                    end
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
        
procedure CombineTrim (var whiteTrim, blackTrim: bitboard; var lastMove: moverec; var board: TBoardRecord);
    begin
        whiteTrim := combineTrimSide (false, lastmove, board);
        blackTrim := combineTrimSide (true, lastmove, board)
    end;

end.
