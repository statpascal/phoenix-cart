unit trimprocs;

interface

uses {$U chesslib.code} globals;

//procedure Trim(j, iLoc, sideOffset: integer; lastMove: moverec; var bit2: bitboard);

function Trim (turn, piece, iLoc: integer; lastMove: moverec; whitePieces, blackPieces, allPieces: integer; var epCapFlag: integer): bitboard;
procedure CombineTrim (var whiteTrim, blackTrim: bitboard; lastMove: moverec);

implementation

uses resources;


function Trim(turn, piece, iLoc: integer; lastMove: moverec; whitePieces, blackPieces, allPieces: integer; var epCapFlag: integer): bitboard;
    var 
        ownPieces, opponentPieces: integer;
        row, bitmask, epCapSquare: integer;
        bit2, bit3, bit5, bit6: bitboard;
    begin
        dataSize := 8;
        if turn = 0 then 
            begin
                ownPieces := whitePieces;
                opponentPieces := blackPieces
            end
        else
            begin
                ownPieces := blackPieces;
                opponentPieces := whitePieces
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
                DataOps(2, BASE, 8, allPieces, bit3);
                BitNot(bit3, bit3);
                BitAnd(bit2, bit3, bit2);
                
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
                DataOps(2, BASE, 8, opponentPieces, bit3);
                BitAnd(bit6, bit3, bit6);
                
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
                DataOps(2, BASE, 8, ownPieces, bit3);
                BitNot(bit3, bit3);
                BitAnd(bit2, bit3, bit2);
            end
        else
            {trim sliding pieces movement rays past blocking pieces}
            begin
                {trim to opponent pieces}
                DataOps(2, BASE, 8, opponentPieces, bit3);
                BitNot(bit3, bit3);
                BitAnd(bit2, bit3, bit5);
                BitTrim(bit5, iLoc, piece, 1);

                {trim to own pieces}
                DataOps(2, BASE, 8, ownPieces, bit3);
                BitNot(bit3, bit3);
                BitAnd(bit2, bit3, bit2);
                BitTrim(bit2, iLoc, piece, 0);

                {merge all trimmed boards}
                BitAnd(bit2, bit5, bit2)
            end;
        Trim := bit2
    end;

(*

procedure Trim(j, iLoc, sideOffset: integer; lastMove: moverec; var bit2: bitboard);
    var 
        k, offset, offset1, offset2, offset3, sPage: integer;
    begin
        startPage := BASE;
        sPage := BASE1;
        dataSize := 8;

     {trim piece movement to obstructions}
        offset := iLoc * 8;

     {get the SIDES bitboard for pawn movement trimming}
//        offset1 := SIDES;
//        DataOps(2, startPage, dataSize, offset1, bit4);

        case j of 
            0 : if turn = 0 then
                     offset1 := offset + WPMOVE - 64
            else
                offset1 := offset + BPMOVE;
            8 : offset1 := offset + RMOVE;
            16: offset1 := offset + NMOVE;
            24: offset1 := offset + BMOVE;
            32: offset1 := offset + QMOVE;
            40: offset1 := offset + KMOVE;
        end;

        if j = 24 then
            DataOps(2, sPage, dataSize, offset1, bit2)
        else
            DataOps(2, startPage, dataSize, offset1, bit2);

     {eliminate blocking squares from movement}
     {pawns special handling}

        if j = 0 then
            begin
       {trim forward movement to any piece}
                offset1 := APIECES;
                DataOps(2, startPage, dataSize, offset1, bit3);
                BitNot(bit3, bit3);
                BitAnd(bit2, bit3, bit2);

       {trim diagonal movement if no opposite piece to capture}
                dataSize := 8;
                if turn = 0 then
                    begin
                        offset1 := BPIECES;
                        offset2 := WPDIAG + offset - 64;
                    end
                else
                    begin
                        offset1 := WPIECES;
                        offset2 := BPDIAG + offset;
                    end;
                DataOps(2, startPage, dataSize, offset1, bit3);
                DataOps(2, sPage, dataSize, offset2, bit6);
                BitAnd(bit6, bit3, bit6);
                BitOr(bit2, bit6, bit2);
                k := 8;
                case turn of 
                    0: if (iLoc > 7) and (iLoc <16) then
                            BitTrim(bit2, iLoc, k, 0);
                    1: if (iLoc > 47) and (iLoc < 56) then
                            BitTrim(bit2, iLoc, k, 0);
                end;

       {check for en passant capture}
       {check if pawn in position for en passant capture}
                if ((turn = 0) and (offset >= 256) and (offset <= 312)) or
                   ((turn = 1) and (offset >= 192) and (offset <= 248)) then
                    begin
         {check if last move was a pawn}
                        if lastMove.id = 0 then
                            begin
           {check if last move was a double move}
                                if abs(lastMove.endSq - lastMove.startSq) = 16 then
                                    begin
                                        if turn = 0 then
                                            begin
                                                offset1 := BEP + (lastMove.startSq * 8) - 384;
                                                offset2 := PIECELOC + ((lastMove.startSq - 8) * 8);
                                                offset3 := WPO;
                                            end
                                        else
                                            begin
                                                offset1 := WEP + (lastMove.startSq * 8) - 64;
                                                offset2 := PIECELOC + ((lastMove.startSq + 8) * 8);
                                                offset3 := BPO;
                                            end;
             {check if pawn on an EP square}
                                        DataOps(2, sPage, dataSize, offset1, bit3);
                                        DataOps(2, startPage, dataSize, offset3, bit1);
                                        BitAnd(bit1, bit3, bit3);
                                        if not(IsClear(bit3)) then
                                            begin
               {add capture square to move bitboard}
                                                DataOps(2, startPage, dataSize, offset2, bit6);
                                                BitOr(bit2, bit6, bit2);
                                            end;
                                    end;
                            end;
                    end;
            end
        else
            begin
                if j in[16, 40] then
                    begin
                        DataOps(2, startPage, dataSize, sideOffset, bit3);
                        BitNot(bit3, bit3);
                        BitAnd(bit2, bit3, bit2);
                    end;
            end;

     {trim sliding pieces movement rays past blocking pieces}
        if j in[8, 24, 32] then
            begin
       {trim to opponent pieces}
                if turn = 0 then
                    offset3 := BPIECES
                else
                    offset3 := WPIECES;
                DataOps(2, startPage, dataSize, offset3, bit3);
                BitNot(bit3, bit3);
                BitAnd(bit2, bit3, bit5);
                BitTrim(bit5, iLoc, j, 1);

       {trim to own pieces}
                DataOps(2, startPage, dataSize, sideOffset, bit3);
                BitNot(bit3, bit3);
                BitAnd(bit2, bit3, bit2);
                BitTrim(bit2, iLoc, j, 0);

       {merge all trimmed boards}
                BitAnd(bit2, bit5, bit2);

            end;
    end; {trim}
    
*)    

procedure CombineTrim (var whiteTrim, blackTrim: bitboard; lastMove: moverec);
    var 
        i, j: integer;
        posArray: bitarray;
        epCapDummy: integer;
        bit1, bit2: bitboard;
    begin
        ClearBitboard (whiteTrim);
        for i := 0 to 5 do
            begin
                DataOps(2, BASE, 8, WPO + (i * 8), bit1);
                BitPos(bit1, posArray);
                for j := 1 to posArray [0] do
                    begin
                        bit2 := Trim(0, i * 8, posArray[j], lastMove, WPIECES, BPIECES, APIECES, epCapDummy);
                        BitOr(bit2, whiteTrim, whiteTrim)
                    end
            end;

        ClearBitboard (blackTrim);
        for i := 0 to 5 do
            begin
                DataOps(2, BASE, 8, BPO + (i * 8), bit1);
                BitPos(bit1, posArray);
                for j := 1 to posArray [0] do
                    begin
                        bit2 := Trim(1, i * 8, posArray[j], lastMove, WPIECES, BPIECES, APIECES, epCapDummy);
                        BitOr(bit2, blackTrim, blackTrim)
                    end
            end
    end;

end.
