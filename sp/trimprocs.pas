unit trimprocs;

interface

uses globals;


function Trim (turn, piece, iLoc: integer; lastMove: moverec; var board: TBoardRecord; var epCapFlag: integer): bitboard;
procedure CombineTrim (var whiteTrim, blackTrim: bitboard; lastMove: moverec; var board: TBoardRecord);

implementation

uses resources;


function Trim(turn, piece, iLoc: integer; lastMove: moverec; var board: TBoardRecord; var epCapFlag: integer): bitboard;
    var 
        ownPieces, opponentPieces: bitboard;
        row, bitmask, epCapSquare: integer;
        bit2, bit3, bit5, bit6: bitboard;
    begin
        dataSize := 8;
        if turn = 0 then 
            begin
                ownPieces := board.whitePieces;
                opponentPieces := board.blackPieces
            end
        else
            begin
                ownPieces := board.blackPieces;
                opponentPieces := board.whitePieces
            end;

        {trim piece movement to obstructions}
        if piece = 0 then
            if turn = 0 then
                bit2 := getMovementBitboard (WhitePawnMove, iLoc)
            else
                bit2 := getMovementBitboard (BlackPawnMove, iLoc)
        else
            bit2 := getMovementBitboard (TBitboardType ((piece - 8) shr 3), iLoc);

        {eliminate blocking squares from movement}
        if piece = 0 then
            begin
                {trim forward movement to any piece}
//                DataOps(2, BASE, 8, allPieces, bit3);
                BitAndNot(bit2, board.allPieces, bit2);
                
                row := iLoc shr 3;
                if (row = 1) or (row = 6) then
                    begin
                        bitMask := 128 shr (iLoc and 7);
                        if (row = 1) and (bit2 [1] and (bitmask shl 8) = 0) then
                            bit2 [1] := bit2 [1] and not bitmask
                        else if (row = 6) and (bit2 [2] and bitmask = 0) then
                            bit2[2] := bit2 [2] and not (bitmask shl 8)
                    end;
                    
                {trim diagonal movement if no opposite piece to capture}
                if turn = 0 then
                    bit6 := getMovementBitboard (WhitePawnCapture, iLoc)
                else
                    bit6 := getMovementBitboard (BlackPawnCapture, iLoc);
//                DataOps(2, BASE, 8, opponentPieces, bit3);
                BitAnd(bit6, opponentPieces, bit6);
                
                BitOr(bit2, bit6, bit2);

                { check for en passant capture }
                if (lastMove.id = 0) and (abs (lastMove.endSq - lastMove.startSq) = 16) and
                   ((turn = 0) and (row = 4) or (turn = 1) and (row = 3)) then
                    begin
                        if turn = 0 then
                            begin
                                DataOps (2, BASE1, 8, BEP + (lastMove.startSq * 8) - 384, bit3);
                                epCapSquare := lastMove.startSq - 8
                            end
                        else
                            begin
                                DataOps (2, BASE1, 8, WEP + (lastMove.startSq * 8) - 64, bit3);
                                epCapSquare := lastMove.startSq + 8
                            end;
                        {check if pawn on an EP square}
                        bit1 := getPieceLocationBitboard (iLoc);
                        BitAnd(bit1, bit3, bit3);
                        if not IsClear(bit3) then
                            begin
                                {add capture square to move bitboard}
                                epCapFlag := 1;
                                bit6 := getPieceLocationBitboard (epCapSquare);
                                BitOr(bit2, bit6, bit2)
                            end
                    end
                end
        else if (piece = 16) or (piece = 40) then	// knight, king
            begin
//                DataOps(2, BASE, 8, ownPieces, bit3);
                BitAndNot(bit2, ownPieces, bit2);
            end
        else
            {trim sliding pieces movement rays past blocking pieces}
            begin
                {trim to opponent pieces}
//                DataOps(2, BASE, 8, opponentPieces, bit3);
                BitAndNot(bit2, opponentPieces, bit5);
                BitTrim(bit5, iLoc, piece, 1);

                {trim to own pieces}
//                DataOps(2, BASE, 8, ownPieces, bit3);
                BitAndNot(bit2, ownPieces, bit2);
                BitTrim(bit2, iLoc, piece, 0);

                {merge all trimmed boards}
                BitAnd(bit2, bit5, bit2)
            end;
        Trim := bit2
    end;

procedure CombineTrim (var whiteTrim, blackTrim: bitboard; lastMove: moverec; var board: TBoardRecord);
    var 
        i, j: integer;
        posArray: bitarray;
        epCapDummy: integer;
        bit1, bit2: bitboard;
    begin
        ClearBitboard (whiteTrim);
        for i := 0 to 5 do
            begin
//                DataOps(2, BASE, 8, WPO + (i * 8), bit1);
                BitPos (board.white.bitboards [i], posArray);
                for j := 1 to posArray [0] do
                    begin
                        bit2 := Trim(0, i * 8, posArray[j], lastMove, board, epCapDummy);
                        BitOr (bit2, whiteTrim, whiteTrim)
                    end
            end;

        ClearBitboard (blackTrim);
        for i := 0 to 5 do
            begin
//                DataOps(2, BASE, 8, BPO + (i * 8), bit1);
                BitPos (board.black.bitboards [i], posArray);
                for j := 1 to posArray [0] do
                    begin
                        bit2 := Trim(1, i * 8, posArray[j], lastMove, board, epCapDummy);
                        BitOr(bit2, blackTrim, blackTrim)
                    end
            end
    end;

end.
