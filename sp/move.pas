unit Move;

interface

uses globals;

procedure MoveGen(lastMove: moverec; var finalMove: moverec;
                  var score: integer; aVal, bVal, cMoveFlag: integer);

implementation

uses scorepos, trimprocs, pmove;

procedure checkBackRowInterposing;
    var 
        offset, offset1, offset2: integer;
    begin
        if ((turn = 0) and (wCastleFlag = 0)) or
           ((turn = 1) and (bCastleFlag = 0)) then
            begin
                offset := APIECES;
                DataOps(2, startPage, dataSize, offset, bit1);
                if turn = 0 then
                    begin
               {white}
                        offset1 := WRCMASK;
                        offset2 := WLCMASK;
               {right side}
                        if (wRAFlag = 0) and (wRookRFlag = 0) then
                            begin
                                DataOps(2, startPage, dataSize, offset1, bit2);
                                BitAnd(bit1, bit2, bit2);
                                if not(IsClear(bit2)) then
                                    wRAFlag := 1;
                            end;
               {left side}
                        if (wLAFlag = 0) and (wRookLFlag = 0) then
                            begin
                                DataOps(2, startPage, dataSize, offset2, bit2);
                                BitAnd(bit1, bit2, bit2);
                                if not(IsClear(bit2)) then
                                    wLAFlag := 1;
                            end;
                    end
                else
                    begin
               {black}
                        offset1 := BRCMASK;
                        offset2 := BLCMASK;
               {right side}
                        if (bRAFlag = 0) and(bRookRFlag = 0) then
                            begin
                                DataOps(2, startPage, dataSize, offset1, bit2);
                                BitAnd(bit1, bit2, bit2);
                                if not(IsClear(bit2)) then
                                    bRAFlag := 1;
                            end;
               {left side}
                        if (bLAFlag = 0) and (bRookLFlag = 0) then
                            begin
                                DataOps(2, startPage, dataSize, offset2, bit2);
                                BitAnd(bit1, bit2, bit2);
                                if not(IsClear(bit2)) then
                                    bLAFlag := 1;
                            end;
                    end;
            end;
    end;

procedure checkRookMissing;
    var offset: integer;
    begin
        if turn = 0 then
            begin
                offset := TWRO;
                DataOps(2, startPage, dataSize, offset, bit1);
       {check left home square}
                offset := PIECELOC;
                DataOps(2, startPage, dataSize, offset, bit2);
                BitAnd(bit1, bit2, bit6);
                if IsClear(bit6) then
                    wLAFlag := 1;
       {check right home square}
                offset := PIECELOC + 56;
                DataOps(2, startPage, dataSize, offset, bit2);
                BitAnd(bit1, bit2, bit6);
                if IsClear(bit6) then
                    wRAFlag := 1;
            end
        else
            begin
                offset := TBRO;
                DataOps(2, startPage, dataSize, offset, bit1);
       {check left home square}
                offset := PIECELOC + 448;
                DataOps(2, startPage, dataSize, offset, bit2);
                BitAnd(bit1, bit2, bit6);
                if IsClear(bit6) then
                    bLAFlag := 1;
       {check right home square}
                offset := PIECELOC + 504;
                DataOps(2, startPage, dataSize, offset, bit2);
                BitAnd(bit1, bit2, bit6);
                if IsClear(bit6) then
                    bRAFlag := 1;
            end;
    end;

procedure checkCastling (var moveList: listPointer);
    var currentMove: listPointer;
    begin
        if (wCastleFlag = 0) and (turn = 0) then
            begin
                if (wLAFlag = 0) and (wRookLFlag = 0) then
                    begin
                        new(currentMove);
                        currentMove^.id := 8;
                        currentMove^.startSq := 0;
                        currentMove^.endSq := 3;
                        currentMove^.link := moveList;
                        moveList := currentMove;
                        new(currentMove);
                        currentMove^.id := 40;
                        currentMove^.startSq := 4;
                        currentMove^.endSq := 2;
                        currentMove^.link := moveList;
                        moveList := currentMove;
                    end;
                if (wRAFlag = 0) and (wRookRFlag = 0) then
                    begin
                        new(currentMove);
                        currentMove^.id := 8;
                        currentMove^.startSq := 7;
                        currentMove^.endSq := 5;
                        currentMove^.link := moveList;
                        moveList := currentMove;
                        new(currentMove);
                        currentMove^.id := 40;
                        currentMove^.startSq := 4;
                        currentMove^.endSq := 6;
                        currentMove^.link := moveList;
                        moveList := currentMove;
                    end;
            end
        else
            if (bCastleFlag = 0) and (turn = 1) then
                begin
                    if (bLAFlag = 0) and (bRookLFlag = 0) then
                        begin
                            new(currentMove);
                            currentMove^.id := 8;
                            currentMove^.startSq := 56;
                            currentMove^.endSq := 59;
                            currentMove^.link := moveList;
                            moveList := currentMove;
                            new(currentMove);
                            currentMove^.id := 40;
                            currentMove^.startSq := 60;
                            currentMove^.endSq := 58;
                            currentMove^.link := moveList;
                            moveList := currentMove;
                        end;
                    if (bRAFlag = 0) and (bRookRFlag = 0) then
                        begin
                            new(currentMove);
                            currentMove^.id := 8;
                            currentMove^.startSq := 63;
                            currentMove^.endSq := 61;
                            currentMove^.link := moveList;
                            moveList := currentMove;
                            new(currentMove);
                            currentMove^.id := 40;
                            currentMove^.startSq := 60;
                            currentMove^.endSq := 62;
                            currentMove^.link := moveList;
                            moveList := currentMove;
                        end;
                end;
    end;

procedure checkOwnBackRowAttack (var lastMove: moveRec);
    var offset1, offset2: integer;
    begin
         {check if own back row attacked}
        if ((turn = 0) and (wCastleFlag = 0)) or
           ((turn = 1) and (bCastleFlag = 0)) then
            begin
           {generate combined opposite movement trim board}
           
                {save the main boards}
                DataOps(2, BASE, 120, WPO, buffer);
                DataOps(1, BASE2, 120, SWPO, buffer);
                
                {replace main boards with temp boards for current move}
                DataOps(2, BASE, 120, TWPO, buffer);
                DataOps(1, BASE, 120, WPO, buffer);
                   
                CombineTrim(bit3, bit5, lastMove);
                
                {restore main boards}
                DataOps(2, BASE2, 120, SWPO, buffer);
                DataOps(1, BASE, 120, WPO, buffer);
 

           {check right and left back rows}
                if turn = 0 then
                    begin
                        offset1 := WRBRMASK;
                        offset2 := WLBRMASK;
                        if (wRAFlag = 0) and (wRookRFlag = 0) then
                            begin
                                DataOps(2, startPage, dataSize, offset1, bit6);
                                BitAnd(bit5, bit6, bit6);
                                if not(IsClear(bit6)) then
                                    wRAFlag := 1;
                            end;

                        if (wLAFlag = 0) and (wRookLFlag = 0) then
                            begin
                                DataOps(2, startPage, dataSize, offset2, bit6);
                                BitAnd(bit5, bit6, bit6);
                                if not(IsClear(bit6)) then
                                    wLAFlag := 1;
                            end;
                    end
                else
                    begin
                        offset1 := BRBRMASK;
                        offset2 := BLBRMASK;
                        if (bRAFlag = 0) and (bRookRFlag = 0) then
                            begin
                                DataOps(2, startPage, dataSize, offset1, bit6);
                                BitAnd(bit3, bit6, bit6);
                                if not(IsClear(bit6)) then
                                    bRAFlag := 1;
                            end;

                        if (bLAFlag = 0) and (bRookLFlag = 0) then
                            begin
                                DataOps(2, startPage, dataSize, offset2, bit6);
                                BitAnd(bit3, bit6, bit6);
                                if not(IsCLear(bit6)) then
                                    bLAFlag := 1;
                            end;
                    end;
            end;
    end;

procedure loopAllPieces (initOffset, sideOffset: integer; var lastMove: moverec; attackIndex,
                         tailIndex: listPointer);
    label 
        l_3;
    var 
        j, k, l, n, offset, offset1, offset2, offset4, pLoc, epCapFlag: integer;
        posArray, moveArray: bitArray;
        bit8, bit9: bitboard;
        currentMove: listPointer;
    begin
        j := 0;
        repeat
          {loop through all pieces bitboards}
            offset := initOffset + j;
            DataOps(2, startPage, dataSize, offset, bit1);
          {check if current piece type exists on current square}
            if not(IsClear(bit1)) then
                begin
                    BitPos(bit1, posArray);
                    l := 1;
            {loop through all existing pieces of current type}
                    repeat
                        pLoc := posArray[l];
             {get corresponding movement bitboard for current piece and square}
                        offset := posArray[l] * 8;
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
                                epCapFlag := 0;
               {trim forward movement to any piece}
                                offset1 := TAPIECES;
                                DataOps(2, startPage, dataSize, offset1, bit3);
                                BitNot(bit3, bit3);
                                BitAnd(bit2, bit3, bit2);
               {add diagonal movement if opposite piece capture possible}
                                dataSize := 8;
                                if turn = 0 then
                                    begin
                                        offset1 := TBPIECES;
                                        offset2 := WPDIAG + offset - 64;
                                    end
                                else
                                    begin
                                        offset1 := TWPIECES;
                                        offset2 := BPDIAG + offset;
                                    end;
                                DataOps(2, startPage, dataSize, offset1, bit3);
                                DataOps(2, sPage, dataSize, offset2, bit6);
                                BitAnd(bit6, bit3, bit6);
                                BitOr(bit2, bit6, bit2);
                                k := 8;
                                case turn of 
                                    0: if (pLoc > 7) and (pLoc <16) then
                                            BitTrim(bit2, bit4, pLoc, k, 0);
                                    1: if (pLoc > 47) and (pLoc < 56) then
                                            BitTrim(bit2, bit4, pLoc, k, 0);
                                end;

               {check for en passant capture}
               {check if pawn in position for en passant capture}
                                if ((turn = 0) and (offset -200 in[56..112])) or
                                   ((turn = 1) and (offset in[192..248])) then
                                    begin
                 {check if last move was a pawn}
                                        if lastMove.id = 0 then
                                            begin
                   {check if last move was a double move}
                                                if abs(lastMove.endSq - lastMove.startSq) = 16 then
                                                    begin
                                                        if turn = 0 then
                                                            begin
                                                                offset1 := BEP + (lastMove.startSq * 8)
                                                                           - 384;
                                                                offset2 := PIECELOC + ((lastMove.startSq
                                                                           - 8) * 8);
                                                            end
                                                        else
                                                            begin
                                                                offset1 := WEP + (lastMove.startSq * 8)
                                                                           - 64;
                                                                offset2 := PIECELOC + ((lastMove.startSq
                                                                           + 8) * 8);
                                                            end;
                     {check if pawn on an EP square}
                                                        DataOps(2, sPage, dataSize, offset1, bit3);
                                                        BitAnd(bit1, bit3, bit3);
                                                        if not(IsClear(bit3)) then
                                                            begin
                       {add capture square to move bitboard}
                                                                epCapFlag := 1;
                                                                DataOps(2, startPage, dataSize, offset2,
                                                                        bit6);
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

                        bit9 := bit1;
             {trim sliding pieces movement rays past blocking pieces}
                        if j in[8, 24, 32] then
                            begin
               {trim to opponent pieces}
                                if turn = 0 then
                                    offset4 := TBPIECES
                                else
                                    offset4 := TWPIECES;
                                DataOps(2, startPage, dataSize, offset4, bit3);
                                BitNot(bit3, bit3);
                                BitAnd(bit2, bit3, bit5);
                                BitTrim(bit5, bit4, pLoc, j, 1);

               {trim to own pieces}
                                DataOps(2, startPage, dataSize, sideOffset, bit3);
                                BitNot(bit3, bit3);
                                BitAnd(bit2, bit3, bit2);
                                BitTrim(bit2, bit4, pLoc, j, 0);

               {merge all trimmed boards}
                                BitAnd(bit2, bit5, bit2);
                            end;

           {bit2 now has the trimmed move list for the current piece}

           {skip king move if no valid move on first ply}
           {allows for stalemate detection}
                        if (j = 40) then
                            begin
             {get the combined trim boards}
                                bit8 := bit2;
                                
                                
                               {save the main boards}
                                DataOps(2, BASE, 120, WPO, buffer);
                                DataOps(1, BASE2, 120, SWPO, buffer);
                                
                                {replace main boards with temp boards for current move}
                                DataOps(2, BASE, 120, TWPO, buffer);
                                DataOps(1, BASE, 120, WPO, buffer);
                                                        
                                CombineTrim(bit3, bit5, lastMove);
                                
                                {restore main boards}
                                DataOps(2, BASE2, 120, SWPO, buffer);
                                DataOps(1, BASE, 120, WPO, buffer);
                                
                                bit1 := bit9;
                                bit2 := bit8;

             {check if king movement overlaps opposite pieces combined movement}
                                if turn = 0 then
                                    BitAnd(bit2, bit5, bit8)
                                else
                                    BitAnd(bit2, bit3, bit8);
                                BitPos(bit8, moveArray);
                                n := moveArray[0];
                                BitPos(bit2, moveArray);
                                if n = moveArray[0] then
                                    goto l_3;
                            end;

           {add up mobility score for side}
(*           
                        if ply <= 2 then
                            begin
                                BitPos(bit2, moveArray);
                                if turn = 0 then
                                    wMobility := wMobility + moveArray[0]
                                else
                                    bMobility := bMobility + moveArray[0];
                            end;
*)                            

           {update move list}
           {find potential captures and add to attack list}
                        if turn = 0 then
                            offset1 := TBPIECES
                        else
                            offset1 := TWPIECES;
                        DataOps(2, startPage, dataSize, offset1, bit3);
                        BitAnd(bit2, bit3, bit3);

           {re-add any en passant capture squares}
                        if epCapFlag = 1 then
                            begin
                                if turn = 0 then
                                    offset2 := WPDIAG + (pLoc * 8)
                                else
                                    offset2 := BPDIAG + (pLoc * 8);
                                DataOps(2, sPage, dataSize, offset2, bit5);
                                BitAnd(bit2, bit5, bit5);
                                BitOr(bit3, bit5, bit3);
                            end;

                        if not(IsClear(bit3)) then
                            begin
                                BitPos(bit3, moveArray);
                                for k := 1 to moveArray[0] do
                                    begin
                                        new(currentMove);
                                        attackIndex^.id := j;
                                        attackIndex^.startSq := pLoc;
                                        attackIndex^.endSq := moveArray[k];
                                        attackIndex^.link := currentMove;
                                        attackIndex := currentMove;
                                        attackIndex^.link := nil;
                                    end;
                            end;

            {find non-capture moves and add to move list}
                        if not(IsClear(bit2)) then
                            begin
                                BitNot(bit3, bit3);
                                BitAnd(bit2, bit3, bit3);
                                BitPos(bit3, moveArray);
                                for k := 1 to moveArray[0] do
                                    begin
                                        new(currentMove);
                                        tailIndex^.id := j;
                                        tailIndex^.startSq := pLoc;
                                        tailIndex^.endSq := moveArray[k];
                                        tailIndex^.link := currentMove;
                                        tailIndex := currentMove;
                                        tailIndex^.link := nil;
                                    end;
                            end;
                        l := succ(l);
                    until l > posArray[0];
                end;
            l_3: 
            j := j + 8;
        until j > 40;
    end;
    
procedure indent (ply: integer);
    begin
        write (logFile, ' ' : 4 * (gameply - ply))
    end;        

procedure printBoard;
    const 
        baseaddr: array [0..1] of integer = (WPO, BPO);
        figure: array [0..1, 0..5] of char = (('^', 'R', 'N', 'B', 'Q', 'K'),
                                              ('v', 'r', 'n', 'b', 'q', 'k'));
    var
        s: array [0..7] of string [8];
        side, piece, i, j: integer;
        bit: bitboard;
        pos: bitarray;
    begin
        for i := 0 to 7 do
            if odd (i) then
                s [i] := ' = = = ='
            else
                s [i] := '= = = = ';
        for side := 0 to 1 do
            for piece := 0 to 5 do
                begin
                    DataOps (2, BASE, 8, baseaddr [side] + 8 * piece, bit);
                    BitPos (bit, pos);
                    for i := 1 to pos [0] do
                        s [pos [i] shr 3][succ (pos [i] and 7)] := figure [side, piece]
                end;
                
        writeln (logFile);
        writeln (logFile, '========================================');
        writeln (logFile, 'Move: ', gameMove);
        writeln (logFile);
        for i := 7 downto 0 do
            begin
                write (logFile, '|');
                for j := 1 to 8 do
                    write (logFile, s [i][j], '|');
                writeln (logFile);
            end;
        writeln (logFile)
    end;
                    
procedure printMove (var move: moverec);

    const
        pieceName: string = 'PRNBQK';
    
    procedure writeCoord (sq: integer);
        begin
            write (logFile, chr (65 + sq mod 8));
            write (logFile, chr (49 + sq div 8))
        end;
    
    begin
        if move.id <> 99 then
            begin
                write (logFile, pieceName [succ (move.id shr 3)]);
                writeCoord (move.startSq);
                write (logFile, '-');
                writecoord (move.endSq)
            end
    end;

procedure MoveGen(lastMove: moverec; var finalMove: moverec; var score: integer; aVal, bVal, cMoveFlag: integer);
    label 
        l_1, l_3, l_5;
    var 
        i, j, k, l, n, offset, initOffset, bestScore: integer;
        sideOffset, offset1, offset2, offset3, offset4: integer;
        wCheckFlag, bCheckFlag, offset7, switchFlag: integer;
        offset5, offset6, attackFlag, evalScore: integer;
        pruneFlag, sPage2, mateFlag, alpha, beta: integer;
        foundFlag: boolean;
        bestMove, tempMove: moverec;
        moveList, attackList, tailIndex, attackIndex, currentMove: listPointer;
        bit8, bit9: bitboard;
        buffer: array[0..59] of integer;
        heap: pointer;

    begin
        mark (heap);

        if doLogging then begin
            if ply = gamePly then
                begin
                    printBoard;
                    write (logFile, 'Last move: ');
                    printMove (lastMove);
                    writeln (logFile)
                end
            else
                begin                    
                    indent (ply); 
                    printMove (lastmove); 
                    writeln (logFile, ': alpha = ', aVal, ' beta = ', bVal)
                end
        end;

        alpha := aVal;
        beta := bVal;

        if ply <= 2 then
            begin
                if turn = 0 then
                    wMobility := 0
                else
                    bMobility := 0;
            end;

        startPage := BASE;
        sPage := BASE1;

        if turn = 0 then
            begin
                initOffset := TWPO;
                sideOffset := TWPIECES;
            end
        else
            begin
                initOffset := TBPO;
                sideOffset := TBPIECES;
            end;

     {get the sides bitboard for movement trimming}
        offset1 := SIDES;
        DataOps(2, startPage, dataSize, offset1, bit4);

        new(moveList);
        new(attackList);
        moveList^.link := nil;
        attackList^.link := nil;
        tailIndex := moveList;
        attackIndex := attackList;

        loopAllPieces (initOffset, sideOffset, lastMove, attackIndex, tailIndex);

        checkBackRowInterposing;
        checkOwnBackRowAttack (lastMove);


     {check if either rook is missing from home square}
        checkRookMissing;


     {add castling moves to head of list if possible}
        checkCastling (moveList);


    (* move1 *)
        if turn = 0 then
            bestScore := -20000
        else
            bestScore := 20000;

        ClearBitboard(bit9);
     {iterate through move list}
        currentMove := attackList;
        attackFlag := 1;
        if currentMove^.link = nil then
            begin
                attackFlag := 0;
                currentMove := moveList;
            end;

     {stalemate condition}
        if (currentMove^.link = nil) and (attackFlag = 0) and (ply = gamePly) then
            begin
                gotoxy(20, 1);
                write(chr(7), chr(7), 'stalemate!');
                i := GetKeyInt;
                readln;
                Utility(switchFlag);
                // TODO: jump control
                exit;
            end;

     {save ply base bitboards}
        offset := TWPO;
        dataSize := 120;
        DataOps(2, startPage, dataSize, offset, buffer);
        offset := PLYBOARDS + ((ply + 3 ) * 120);
        
        DataOps(1, sPage, dataSize, offset, buffer);
        dataSize := 8;

        repeat
            foundFlag := false;
            tempMove.id := 99;
            l_1: 
      {update base bitboards with current move}
            if turn = 0 then
                begin
                    offset1 := TWPIECES;
                    offset5 := TBPO;
                    offset6 := TBPIECES;
                    offset := TWPO + currentMove^.id;
                end
            else
                begin
                    offset1 := TBPIECES;
                    offset5 := TWPO;
                    offset6 := TWPIECES;
                    offset := TBPO + currentMove^.id;
                end;

            offset4 := TAPIECES;
            offset2 := PIECELOC + (currentMove^.startSq * 8);
            offset3 := PIECELOC + (currentMove^.endSq * 8);

      {erase piece at starting position}
            DataOps(2, startPage, dataSize, offset, bit1);
            DataOps(2, startPage, dataSize, offset2, bit2);
            BitNot(bit2, bit2);
            BitAnd(bit1, bit2, bit1);
            DataOps(1, startPage, dataSize, offset, bit1);
            DataOps(2, startPage, dataSize, offset1, bit1);
            BitAnd(bit1, bit2, bit1);
            DataOps(1, startPage, dataSize, offset1, bit1);
            DataOps(2, startPage, dataSize, offset4, bit1);
            BitAnd(bit1, bit2, bit1);
            DataOps(1, startPage, dataSize, offset4, bit1);

      {remove attacked piece from opponent's bitboards}
            if attackFlag = 1 then
                begin
                    DataOps(2, startPage, dataSize, offset3, bit2);
                    bit3 := bit2;
                    BitNot(bit2, bit2);

                    j := 0;
                    repeat
                        offset2 := offset5 + j;
                        DataOps(2, startPage, dataSize, offset2, bit1);
                        BitAnd(bit1, bit3, bitRes);
                        if not(IsClear(bitRes)) then
                            begin
                                foundFlag := TRUE;
                                l := currentMove^.id;
                                n := j
                            end;
                        BitAnd(bit1, bit2, bit1);
                        DataOps(1, startPage, dataSize, offset2, bit1);
                        j := j + 8;
                    until (foundFlag) or (j > 40);

        {en passant capture handling}
                    if (foundFlag = FALSE) and (currentMove^.id = 0) then
                        begin
                            if abs(currentMove^.startSq - currentMove^.endSq) in[7, 9] then
                                begin
                                    if turn = 0 then
                                        offset7 := PIECELOC + ((currentMove^.endSq - 8) * 8)
                                    else
                                        offset7 := PIECELOC + ((currentMove^.endSq + 8) * 8);
                                    DataOps(2, startPage, dataSize, offset7, bit3);
                                    BitNot(bit3, bit3);
                                    DataOps(2, startPage, dataSize, offset5, bit1);
                                    BitAnd(bit3, bit1, bit1);
                                    DataOps(1, startPage, dataSize, offset5, bit1);
                                    offset5 := TAPIECES;
                                    DataOps(2, startPage, dataSize, offset5, bit1);
                                    BitAnd(bit3, bit1, bit1);
                                    DataOps(1, startPage, dataSize, offset5, bit1);
                                    if turn = 0 then
                                        offset5 := TBPIECES
                                    else
                                        offset5 := TWPIECES;
                                    DataOps(2, startPage, dataSize, offset5, bit1);
                                    BitAnd(bit3, bit1, bit1);
                                    DataOps(1, startPage, dataSize, offset5, bit1);
                                end;
                        end;

                    DataOps(2, startPage, dataSize, offset6, bit1);
                    BitAnd(bit1, bit2, bit1);
                    DataOps(1, startPage, dataSize, offset6, bit1);
                    DataOps(2, startPage, dataSize, offset4, bit1);
                    BitAnd(bit1, bit2, bit1);
                    DataOps(1, startPage, dataSize, offset4, bit1);
                end;

      {place piece at ending position}
            if (currentMove^.id = 0) and (currentMove^.endSq in[0..7, 56..63]) then
                begin
                    if turn = 0 then
                        offset := TWQO
                    else
                        offset := TBQO;
                end;
            DataOps(2, startPage, dataSize, offset, bit1);
            DataOps(2, startPage, dataSize, offset3, bit2);
            BitOr(bit1, bit2, bit1);
            DataOps(1, startPage, dataSize, offset, bit1);
            DataOps(2, startPage, dataSize, offset1, bit1);
            BitOr(bit1, bit2, bit1);
            DataOps(1, startPage, dataSize, offset1, bit1);
            DataOps(2, startPage, dataSize, offset4, bit1);
            BitOr(bit1, bit2, bit1);
            DataOps(1, startPage, dataSize, offset4, bit1);

      {check for castling move}
            if (attackFlag = 0) and (currentMove^.id = 40) then
                begin
                    if abs(currentMove^.startSq - currentMove^.endSq) = 2 then
                        begin
                            if ply = gamePly then
                                cMoveFlag := 1;
                            tempMove.id := currentMove^.id;
                            tempMove.startSq := currentMove^.startSq;
                            tempMove.endSq := currentMove^.endSq;
                            currentMove := currentMove^.link;
                            goto l_1;
                        end;
                end;

      {process non-castling move}
            if tempMove.id = 99 then
                begin
                    tempMove.id := currentMove^.id;
                    tempMove.startSq := currentMove^.startSq;
                    tempMove.endSq := currentMove^.endSq;
                end;

      {check if own king in check after current move}
//            if (cWarning = 1) and (ply = gamePly) then
            if ply = gamePly then
                begin
                    pruneFlag := 0;
        {save the main boards}
                    offset := WPO;
                    startPage := BASE;
                    dataSize := 120;
                    DataOps(2, startPage, dataSize, offset, buffer);
                    offset := SWPO;
                    startPage := BASE2;
                    DataOps(1, startPage, dataSize, offset, buffer);
        {replace main boards with temp boards for current move}
                    offset := WPO;
                    offset1 := TWPO;
                    startPage := BASE;
                    DataOps(2, startPage, dataSize, offset1, buffer);
                    DataOps(1, startPage, dataSize, offset, buffer);
        {generate combined trim boards}
                    dataSize := 8;
                    CombineTrim(bit3, bit5, lastMove);
        {restore main boards}
                    startPage := BASE2;
                    dataSize := 120;
                    offset := SWPO;
                    DataOps(2, startPage, dataSize, offset, buffer);
                    startPage := BASE;
                    offset := WPO;
                    DataOps(1, startPage, dataSize, offset, buffer);
                    dataSize := 8;
        {check if own king attacked by opposite trim board}
                    if turn = 0 then
                        offset := TWKO
                    else
                        offset := TBKO;
                    DataOps(2, startPage, dataSize, offset, bit1);
                    if not(IsClear(bit1)) then
                        begin
                            if turn = 0 then
                                BitAnd(bit1, bit5, bit1)
                            else
                                BitAnd(bit1, bit3, bit1);
                            if not(IsClear(bit1)) then
                                goto l_5; {ignore move if own king still in check}
                        end;
                end;

      {terminal node check}
            if not foundFlag and (ply = 1) or (ply = -1) then
                begin
        {update number of positions evaluated}
                    inc (moveNumLo);
                    if (moveNumLo = 1000) then
                        begin
                            moveNumLo := 0;
                            inc (moveNumHi)
                        end;

        {evaluate position}
                    evalScore := Evaluate(cMoveFlag, attackFlag, l, n, lastMove, tempMove);
                 
                    if doLogging then begin   
                        indent (ply - 1); printMove (tempMove); writeln (logFile, ': ', evalScore: 6);
                    end;
                    
                    pruneFlag := 0;
                    if turn = 0 then
                        begin
                            if evalScore >= bestScore then
                                begin
                                    bestScore := evalScore;
                                    bestMove.id := tempMove.id;
                                    bestMove.startSq := tempMove.startSq;
                                    bestMove.endSq := tempMove.endSq;
                                end;
                            if bestScore > beta then
                                pruneFlag := 1;
//                            else
                            if bestScore > alpha then
                                alpha := bestScore;
                        end
                    else
                        begin
                            if evalScore <= bestScore then
                                begin
                                    bestScore := evalScore;
                                    bestMove.id := tempMove.id;
                                    bestMove.startSq := tempMove.startSq;
                                    bestMove.endSq := tempMove.endSq;
                                end;
                            if bestScore < alpha then
                                pruneFlag := 1;
//                            else
                            if bestScore < beta then
                                beta := bestScore;
                        end;
                end
            else
                begin
        {next ply}
                    ply := pred(ply);
                    if turn = 0 then
                        turn := 1
                    else
                        turn := 0;

                    MoveGen(tempMove, finalMove, score, alpha, beta, cMoveFlag);

                    if ply = gamePly then
                        cMoveFlag := 0;

        {alpha/beta selection}
                    pruneFlag := 0;
                    if turn = 0 then
                        begin
                            if score >= bestScore then
                                begin
                                    bestScore := score;
                                    bestMove.id := tempMove.id;
                                    bestMove.startSq := tempMove.startSq;
                                    bestMove.endSq := tempMove.endSq;
                                end;
                            if bestScore > beta then
                                pruneFlag := 1;
//                            else
                            if bestScore > alpha then
                                alpha := bestScore;
                        end
                    else
                        begin
                            if score <= bestScore then
                                begin
                                    bestScore := score;
                                    bestMove.id := tempMove.id;
                                    bestMove.startSq := tempMove.startSq;
                                    bestMove.endSq := tempMove.endSq;
                                end;
                            if bestScore < alpha then
                                pruneFlag := 1;
//                            else
                            if bestScore < beta then
                                beta := bestScore;
                        end;
                end;

            l_5: 
      {restore the previous ply base bitboard}
            offset := PLYBOARDS + ((ply + 3) * 120);
            dataSize := 120;
            
            DataOps(2, sPage, dataSize, offset, buffer);
            offset := TWPO;
            DataOps(1, startPage, dataSize, offset, buffer);
            dataSize := 8;

            currentMove := currentMove^.link;
            if (currentMove^.link = nil) and (attackFlag = 1) then
                begin
                    attackFlag := 0;
                    currentMove := moveList;
                end;
        until (currentMove^.link = nil) or (pruneFlag = 1);

        finalMove := bestMove;
        score := bestScore;
        
        if doLogging then begin
            indent (pred (ply)); write (logFile, 'Best: '); printMove (finalMove); writeln (logfile, ': ', score:6)
        end;

     {up 1 ply}
        ply := succ(ply);
        if turn = 0 then
            turn := 1
        else
            turn := 0;
            
        release (heap);
    end;

end.
