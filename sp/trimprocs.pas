unit trimprocs;

interface

uses {$U chesslib.code} globals;

//procedure Trim(j, iLoc, sideOffset: integer; lastMove: moverec; var bit2: bitboard);
procedure Trim(j, iLoc: integer; lastMove: moverec; var bit2: bitboard; whitePieces, blackPieces, allPieces: integer; var epCapFlag: integer);
procedure CombineTrim(var bit3, bit5: bitboard; lastMove: moverec);

implementation

uses movement;


procedure Trim(j, iLoc: integer; lastMove: moverec; var bit2: bitboard; whitePieces, blackPieces, allPieces: integer; var epCapFlag: integer);
    var 
        k, offset, offset1, offset2, offset3, sPage, sideOffset: integer;
    begin
        startPage := BASE;
        sPage := BASE1;
        dataSize := 8;
        if turn = 0 then 
            sideOffset := whitePieces
        else
            sideOffset := blackPieces;

     {trim piece movement to obstructions}
        offset := iLoc * 8;

     {get the SIDES bitboard for pawn movement trimming}
//        offset1 := SIDES;
//        DataOps(2, startPage, dataSize, offset1, bit4);
(*
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
*)        
(*
        if j = 24 then
            DataOps(2, sPage, dataSize, offset1, bit2)
        else
            DataOps(2, startPage, dataSize, offset1, bit2);
*)            
            
        if j = 0 then
            if turn = 0 then
                bit2 := getMovementBitboard (WhitePawnMove, iLoc)
            else
                bit2 := getMovementBitboard (BlackPawnMove, iLoc)
        else
            bit2 := getMovementBitboard (TBitboardType ((j - 8) shr 3), iLoc);

     {eliminate blocking squares from movement}
     {pawns special handling}

        if j = 0 then
            begin
       {trim forward movement to any piece}
//                offset1 := APIECES;
                offset1 := allPieces;
                DataOps(2, startPage, dataSize, offset1, bit3);
                BitNot(bit3, bit3);
                BitAnd(bit2, bit3, bit2);

       {trim diagonal movement if no opposite piece to capture}
                dataSize := 8;
                if turn = 0 then
                    begin
//                        offset1 := BPIECES;
                        offset1 := blackPieces;
                        offset2 := WPDIAG + offset - 64;
                        bit6 := getMovementBitboard (WhitePawnCapture, iLoc)
                    end
                else
                    begin
//                        offset1 := WPIECES;
                        offset1 := whitePieces;
                        offset2 := BPDIAG + offset;
                        bit6 := getMovementBitboard (BlackPawnCapture, iLoc)
                    end;
                DataOps(2, startPage, dataSize, offset1, bit3);
//                DataOps(2, sPage, dataSize, offset2, bit6);
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
                if ((turn = 0) and (iLoc >= 32) and (iLoc <= 39)) or
                   ((turn = 1) and (iLoc >= 24) and (iLoc <= 31)) then
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
                                                epCapFlag := 1;
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
//                    offset3 := BPIECES
                    offset3 := blackPieces
                else
//                    offset3 := WPIECES;
                    offset3 := whitePieces;
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

procedure CombineTrim(var bit3, bit5: bitboard; lastMove: moverec);
    var 
        i, j, offset, sideOffset, iTurn: integer;
        posArray: bitarray;
        epCapDummy: integer;
    begin
        startPage := BASE;
        dataSize := 8;
        iTurn := turn;

        ClearBitboard(bitRes);
        sideOffset := WPIECES;
        turn := 0;

        for i := 0 to 5 do
            begin
                offset := WPO + (i * 8);
                DataOps(2, startPage, dataSize, offset, bit1);
                if not(IsClear(bit1)) then
                    begin
                        BitPos(bit1, posArray);
                        for j := 1 to posArray[0] do
                            begin
                                Trim(i * 8, posArray[j], lastMove, bit2, WPIECES, BPIECES, APIECES, epCapDummy);
                                BitOr(bit2, bitRes, bitRes);
                            end;
                    end;
            end;
        bit7 := BitRes;

        sideOffset := BPIECES;
        ClearBitboard(bitRes);
        turn := 1;

        for i := 0 to 5 do
            begin
                offset := BPO + (i * 8);
                DataOps(2, startPage, dataSize, offset, bit1);
                if not(IsClear(bit1)) then
                    begin
                        BitPos(bit1, posArray);
                        for j := 1 to posArray[0] do
                            begin
                                Trim(i * 8, posArray[j], lastMove, bit2, WPIECES, BPIECES, APIECES, epCapDummy);
                                BitOr(bit2, bitRes, bitRes);
                            end;
                    end;
            end;
        bit5 := bitRes;
        bit3 := bit7;

     {bit3 has white combined trim board}
     {bit5 has black combined trim board}
        turn := iTurn;
    end; {CombineTrim}

end.
