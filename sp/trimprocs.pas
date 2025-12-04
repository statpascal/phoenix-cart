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
                if turn = 0 then
                    result := getMovementBitboard (WhitePawnMove, iLoc)
                else
                    result := getMovementBitboard (BlackPawnMove, iLoc);
                    
                {trim forward movement to any piece}
                BitAndNot (result, board.allPieces, result);
                
                row := iLoc shr 3;
(*                
                if (row = 1) or (row = 6) then
                    begin
                        bitMask := 128 shr (iLoc and 7);
                        if (row = 1) and (result [1] and (bitmask shl 8) = 0) then
                            result [1] := result [1] and not bitmask
                        else if (row = 6) and (result [2] and bitmask = 0) then
                            result [2] := result [2] and not (bitmask shl 8)
                    end;
*)
                if (turn = 0) and (row = 1) and (getBit (result, iLoc + 8) = 0) then
                    clearBit (result, iLoc + 16);
                if (turn = 1) and (row = 6) and (getBit (result, iLoc - 8) = 0) then
                    clearBit (result, iLoc - 16);
                    
                {trim diagonal movement if no opposite piece to capture}
                if turn = 0 then
                    begin
                        bit1 := getMovementBitboard (WhitePawnCapture, iLoc);
                        BitAnd (bit1, board.blackPieces, bit1)
                    end
                else
                    begin
                        bit1 := getMovementBitboard (BlackPawnCapture, iLoc);
                        BitAnd (bit1, board.whitePieces, bit1)
                    end;
                
                BitOr (result, bit1, result);

                { check for en passant capture }
                if (lastMove.id = 0) and (abs (lastMove.endSq - lastMove.startSq) = 16) and (row = 4 - turn) then
//                   ((turn = 0) and (row = 4) or (turn = 1) and (row = 3)) then
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
                        bit1 := getPieceLocationBitboard (iLoc);
                        BitAnd (bit1, bit2, bit1);
                        if not IsClear(bit1) then
                            begin
                                {add capture square to move bitboard}
                                epCapFlag := 1;
                                bit1 := getPieceLocationBitboard (epCapSquare);
                                BitOr (result, bit1, result)
                            end
                    end
                end
        else 
            begin
                bit1 := getMovementBitboard (TBitboardType ((piece - 8) shr 3), iLoc);
                if (piece = Knight) or (piece = King) then
                    begin
                        if turn = 0 then 
                            BitAndNot (bit1, board.whitePieces, result)
                        else
                            BitAndNot (bit1, board.blackPieces, result)
                    end
                else
                    {trim sliding pieces movement rays past blocking pieces}
                    begin
                        {trim to white pieces - turn indicates if this is opponent/own}
                        BitAndNot (bit1, board.whitePieces, bit2);
                        BitTrim (bit2, iLoc, piece, turn);

                        {trim to black pieces pieces, with turn inverted}
                        BitAndNot (bit1, board.blackPieces, bit3);
                        BitTrim (bit3, iLoc, piece, 1 - turn);

                        {merge both trimmed boards}
                        BitAnd (bit2, bit3, result)
                    end
            end;
    end;
    
function combineTrimSide (isBlack: boolean; var lastMove: moverec; var board: TBoardRecord): bitboard;
    var
        i, j: integer;
        posArray: bitarray;
        epCapDummy: integer;
        bit: bitboard;
        p: ^bitboard;
    begin
        clearBitboard (result);
        if isBlack then 
            p := addr (board.black.bitboards [0])
        else
            p := addr (board.white.bitboards [0]);
        for i := 0 to 5 do
            begin
                BitPos (p^, posArray);
                for j := 1 to posArray [0] do
                    begin
                        bit := Trim (ord (isBlack), i * 8, posArray[j], lastMove, board, epCapDummy);
                        BitOr (result, bit, result)
                    end;
                inc (p)
            end
    end;        
        

procedure CombineTrim (var whiteTrim, blackTrim: bitboard; var lastMove: moverec; var board: TBoardRecord);
    begin
        whiteTrim := combineTrimSide (false, lastmove, board);
        blackTrim := combineTrimSide (true, lastmove, board)
    end;

end.
