(* version 10-30-25 v1.7 *)
(* MinMax, no iterative deepening, capture evaluation bonus *)
(* fixed castling when rook has moved bug *)

(* adjustments to scorepos
   - modified the mobility bonus
   - decreased opposite check to 100
   - modified the capture bonus table
   - removed the pawn count factor for bishops
   - increased the castling bonus to 500
   - increased pawn support bonus to 20
   - reduced pawn en-passant capture penalty to 20
   - added doubled pawns penalty *)
(* cMoveFlag set only on initial ply *)
(* reset the castling obstruction flags with every turn *)
(* lastMove variable now local only *)
(* capture flags only set on topmost ply *)
(* fixed castling at ply > 2 *)
(* fixed impending mate detection *)
(* removed randomization of bestScore in MinMax *)
(* replaced bitgen with direct file load *)
(* fixed checkmate bug when attacking piece can be captured *)
(* fixed bug in the BitTrim routine *)
(* added pawn promotion piece choice for human side *)
(* fixed discovery check bug *)
(* moved Update routine to an Include file *)
(* added mating move check during move generation *)
(* reduced maximum ply to 5 *)
(* fixed bugs with the GetBoards, matecheck and matechk routines *)
(* removed move skipping when king in check during move generation *)
(* added game moves saving to SAMS card *)
(* added penalty for moving king when castling possible *)
(* fixed bug in board update after en passant capture *)
(* fixed bug in queen movement trimming *)
(* fixed back row threat detection during castling *)
(* added 3-fold repetition draw detection *)
(* added game status storage to SAMS card *)
(* fixed en-passant capture risk detection *)
(* fixed stalemate function and added the resign function *)
(* added the utility menu *)
(* fixed bug in opening move *)
(* Added rook move penalty before castling *)
(* adjusted end game conditions *)
(* added check condition evaluation to position setup *)
(* ignored moves that did not eliminate own check *)
(* 10-19-25: Fixed castling when rook not present *)
(* 10-19-25: Adjusted the resign parameters *)
(* 10-30-25: Added capture bonus in scorepos *)

unit Main;

interface

procedure chainMain;

implementation
// uses random,

uses 
    globals, move, trimprocs, ui, pmove;

var 
    i, j, moveScore, offset, found, aVal, bVal, ans: integer;
    sideOffset, offset1, offset2, cFlag, tempPointer: integer;
    humanFlag, cmFlag, checkFlag, promFlag, repFlag: boolean;
    moveArray: bitarray;
    lastMove, playMove, moveStore, tempMove: moverec;
    bit8: bitboard;

{update main boards with current move}
procedure UpdateMove(var playMove: moverec);
    var 
        offset1, offset2, offset3, offset4, qCastleFlag, kCastleFlag, ans: integer;
    begin
        qCastleFlag := 0;
        kCastleFlag := 0;

     {check for castling move}
        if (gameSide = 0) and (wCastleFlag = 0) or
           (gameSide = 1) and (bCastleFlag = 0) then
            begin
                if  (playMove.id = 40) and (abs(playMove.startSq - playMove.endSq) = 2) then
                    begin
                        if playMove.startSq - playMove.endSq > 0 then
                            qCastleFlag := 1
                        else
                            kCastleFlag := 1;
                    end;
            end;

     {check if rooks have moved from home square}
        if (gameSide = 0) and (wCastleFlag = 0) and (playMove.id = 8) then
            begin
                if (playMove.startSq = 0) and (qCastleFlag = 0) then
                    wRookLFlag := 1
                else
                    if (playMove.startSq = 7) and (kCastleFlag = 0) then
                        wRookRFlag := 1;
            end
        else
            if (gameSide = 1) and (bCastleFlag = 0) and (playMove.id = 8) then
                begin
                    if (playMove.startSq = 58) and (qCastleFlag = 0) then
                        bRookLFlag := 1
                    else
                        if (playMove.startSq = 63) and (kCastleFlag = 0) then
                            bRookRFlag := 1;
                end;

        promFlag := FALSE;

     {check for pawn promotion}
        if (playMove.id = 0) and ((playMove.endSq in[56..63]) or
           (playMove.endSq in[0..7])) then
            begin
                promFlag := TRUE;
                if turn = 0 then
                    offset := WPO
                else
                    offset := BPO;

                DataOps(2, startPage, dataSize, offset, bit1);
                offset1 := PIECELOC + (playMove.endSq * 8);
                DataOps(2, startPage, dataSize, offset1, bit2);
                BitNot(bit2, bit2);
                BitAnd(bit1, bit2, bit1);
                DataOps(1, startPage, dataSize, offset, bit1);
            end;

     {erase initial position}
        offset := PIECELOC + (playMove.startSq * 8);
        DataOps(2, startPage, dataSize, offset, bit1);
        offset := APIECES;
        DataOps(2, startPage, dataSize, offset, bit2);
        BitNot(bit1, bit1);
        BitAnd(bit1, bit2, bit2);
        DataOps(1, startPage, dataSize, offset, bit2);

        if gameSide = 0 then
            begin
                offset := WPO + playMove.id;
                offset1 := WPIECES;
                offset4 := BPIECES;
                if qCastleFlag = 1 then
                    begin
                        wCastleFlag := 1;
                        offset2 := PIECELOC;
                        offset3 := WRO;
                    end
                else
                    if kCastleFlag = 1 then
                        begin
                            wCastleFlag := 1;
                            offset2 := PIECELOC + 56;
                            offset3 := WRO;
                        end;
            end
        else
            begin
                offset := BPO + playMove.id;
                offset1 := BPIECES;
                offset4 := WPIECES;
                if qCastleFlag = 1 then
                    begin
                        bCastleFlag := 1;
                        offset2 := PIECELOC + 448;
                        offset3 := BRO;
                    end
                else
                    if kCastleFlag = 1 then
                        begin
                            bCastleFlag := 1;
                            offset2 := PIECELOC + 504;
                            offset3 := BRO;
                        end;
            end;

        DataOps(2, startPage, dataSize, offset, bit2);
        BitAnd(bit1, bit2, bit2);
        DataOps(1, startPage, dataSize, offset, bit2);
        DataOps(2, startPage, dataSize, offset1, bit2);
        BitAnd(bit1, bit2, bit2);
        DataOps(1, startPage, dataSize, offset1, bit2);

        if (kCastleFlag = 1) or (qCastleFlag = 1) then
            begin
                DataOps(2, startPage, dataSize, offset2, bit1);
                BitNot(bit1, bit1);
                DataOps(2, startPage, dataSize, offset3, bit2);
                BitAnd(bit1, bit2, bit2);
                DataOps(1, startPage, dataSize, offset3, bit2);
                DataOps(2, startPage, dataSize, offset1, bit2);
                BitAnd(bit1, bit2, bit2);
                DataOps(1, startPage, dataSize, offset1, bit2);
                offset := APIECES;
                DataOps(2, startPage, dataSize, offset, bit2);
                BitAnd(bit1, bit2, bit2);
                DataOps(1, startPage, dataSize, offset, bit2);
            end;

     {erase any potential captures}
        offset := PIECELOC + (playMove.endSq * 8);
        DataOps(2, startPage, dataSize, offset, bit1);
        bit3 := bit1;
        BitNot(bit1, bit1);

        if gameSide = 0 then
            offset := BPO
        else
            offset := WPO;

        i := 0;
        found := 0;
        repeat
            offset1 := offset + i;
            DataOps(2, startPage, dataSize, offset1, bit2);
            BitAnd(bit3, bit2, bitRes);
            if not(IsClear(bitRes)) then
                begin
                    found := 1;
                    if (wCastleFlag = 0) and (offset1 = WRO) then
                        begin
                            if playMove.endSq = 0 then
                                begin
                                    wRookLFlag := 1;
                                end;
                            if playMove.endSq = 7 then
                                begin
                                    wRookRFlag := 1;
                                end;
                        end;
                    if (bCastleFlag = 0) and (offset1 = BRO) then
                        begin
                            if playMove.endSq = 56 then
                                begin
                                    bRookLFlag := 1;
                                end;
                            if playMove.endSq = 63 then
                                begin
                                    bRookRFlag := 1;
                                end;
                        end;
                end;
            BitAnd(bit1, bit2, bit2);
            DataOps(1, startPage, dataSize, offset1, bit2);
            i := i + 8;
        until i > 40;

     {en passant capture handling}
        if (found = 0) and (playMove.id = 0) then
            begin
                if abs(playMove.startSq - playMove.endSq) in[7, 9] then
                    begin
                        if gameSide = 0 then
                            offset1 := PIECELOC + ((playMove.endSq - 8) * 8)
                        else
                            offset1 := PIECELOC + ((playMove.endSq + 8) * 8);
                        DataOps(2, startPage, dataSize, offset1, bit3);
                        BitNot(bit3, bit3);
                        DataOps(2, startPage, dataSize, offset, bit2);
                        BitAnd(bit3, bit2, bit2);
                        DataOps(1, startPage, dataSize, offset, bit2);
                        offset1 := APIECES;
                        DataOps(2, startPage, dataSize, offset1, bit2);
                        BitAnd(bit3, bit2, bit2);
                        DataOps(1, startPage, dataSize, offset1, bit2);
                        if gameSide = 0 then
                            offset1 := BPIECES
                        else
                            offset1 := WPIECES;
                        DataOps(2, startPage, dataSize, offset1, bit2);
                        BitAnd(bit3, bit2, bit2);
                        DataOps(1, startPage, dataSize, offset1, bit2);
                    end;
            end;

        DataOps(2, startPage, dataSize, offset4, bit2);
        BitAnd(bit1, bit2, bit2);
        DataOps(1, startPage, dataSize, offset4, bit2);

     {promote pawn if applicable}
        if (promFlag) and (sPage = 1) then
            begin
                ans := GetKeyInt;
                gotoxy(20, 8);
                writeln(chr(7),'promote pawn to');
                gotoxy(22, 9);
                writeln('1- rook');
                gotoxy(22, 10);
                writeln('2- knight');
                gotoxy(22, 11);
                writeln('3- bishop');
                gotoxy(22, 12);
                writeln('4- queen');
                repeat
                    ans := GetKeyInt
                until ans in[49..52];
                playMove.id := (ans - 48) * 8;
            end
        else
            if (promFlag) and (sPage = 0) then
                playMove.id := 32;

     {update new piece position}
        offset := PIECELOC + (playMove.endSq * 8);
        DataOps(2, startPage, dataSize, offset, bit1);
        offset := APIECES;
        DataOps(2, startPage, dataSize, offset, bit2);
        BitOr(bit1, bit2, bit2);
        DataOps(1, startPage, dataSize, offset, bit2);

        if gameSide = 0 then
            begin
                offset := WPO + playMove.id;
                offset1 := WPIECES;
                if qCastleFlag = 1 then
                    offset2 := PIECELOC + 24;
                if kCastleFlag = 1 then
                    offset2 := PIECELOC + 40;
            end
        else
            begin
                offset := BPO + playMove.id;
                offset1 := BPIECES;
                if qCastleFlag = 1 then
                    offset2 := PIECELOC + 472;
                if kCastleFlag = 1 then
                    offset2 := PIECELOC + 488;
            end;

        DataOps(2, startPage, dataSize, offset, bit2);
        BitOr(bit1, bit2, bit2);
        DataOps(1, startPage, dataSize, offset, bit2);
        DataOps(2, startPage, dataSize, offset1, bit2);
        BitOr(bit1, bit2, bit2);
        DataOps(1, startPage, dataSize, offset1, bit2);
        if (qCastleFlag = 1) or (kCastleFlag = 1) then
            begin
                DataOps(2, startPage, dataSize, offset2, bit1);
                DataOps(2, startPage, dataSize, offset3, bit2);
                BitOr(bit1, bit2, bit2);
                DataOps(1, startPage, dataSize, offset3, bit2);
                DataOps(2, startPage, dataSize, offset1, bit2);
                BitOr(bit1, bit2, bit2);
                DataOps(1, startPage, dataSize, offset1, bit2);
                offset := APIECES;
                DataOps(2, startPage, dataSize, offset, bit2);
                BitOr(bit1, bit2, bit2);
                DataOps(1, startPage, dataSize, offset, bit2);
            end;
    end;


procedure SaveBoards;
    var 
        offset, i: integer;
    begin
        startPage := BASE;
        dataSize := 120;

        offset := WPO;
        DataOps(2, startPage, dataSize, offset, buffer);
        offset := TWPO;
        DataOps(1, startPage, dataSize, offset, buffer);
        dataSize := 8;
    end;

procedure GetBoards;
    var 
        offset: integer;
    begin
        startPage := BASE;
        dataSize := 120;

        offset := TWPO;
        DataOps(2, startPage, dataSize, offset, buffer);
        offset := WPO;
        DataOps(1, startPage, dataSize, offset, buffer);
        dataSize := 8;
end;

procedure SaveMove;
    var 
        offset, offset1, storeBase, storePtr: integer;
    begin
     {retrieve the storePtr and storeBase variables}
        startPage := BASE2;
        dataSize := 2;
        offset := 4000;
        DataOps(2, startPage, dataSize, offset, storePtr);
        offset := 4002;
        DataOps(2, startPage, dataSize, offset, storeBase);

        offset1 := WPO;
        offset := storePtr;
        if offset > 4079 then
            begin
                storeBase := succ(storeBase);
                storePtr := 0;
                offset := 0;
            end;
        dataSize := 120;
        startPage := BASE;
        DataOps(2, startPage, dataSize, offset1, buffer);
        DataOps(1, storeBase, dataSize, offset, buffer);
        offset := offset + 120;
        dataSize := 2;
        DataOps(1, storeBase, dataSize, offset, wCastleFlag);
        offset := offset + 2;
        DataOps(1, storeBase, dataSize, offset, bCastleFlag);
        offset := offset + 2;
        DataOps(1, storeBase, dataSize, offset, wRookLFlag);
        offset := offset + 2;
        DataOps(1, storeBase, dataSize, offset, wRookRFlag);
        offset := offset + 2;
        DataOps(1, storeBase, dataSize, offset, bRookLFlag);
        offset := offset + 2;
        DataOps(1, storeBase, dataSize, offset, bRookRFlag);
        offset := offset + 2;
        DataOps(1, storeBase, dataSize, offset, cWarning);
        offset := offset + 2;
        DataOps(1, storeBase, dataSize, offset, gameMove);
        offset := offset + 2;
        storePtr := offset;

     {save the storePtr and storeBase variables}
        startPage := BASE2;
        offset := 4000;
        DataOps(1, startPage, dataSize, offset, storePtr);
        offset := 4002;
        DataOps(1, startPage, dataSize, offset, storeBase);

        startPage := BASE;
        dataSize := 8;
    end;

procedure initGame;
    begin
//        clrscr;
        // Randomize;	// TODO
        turn := 0;
        gameSide := turn;
        gameMove := 1;
        wCastleFlag := 0;
        bCastleFlag := 0;
        wRookRFlag := 0;
        wRookLFlag := 0;
        bRookRFlag := 0;
        bRookLFlag := 0;
        lastMove.id := 99;
        lastMove.startSq := 0;
        lastMove.endSq := 0;
        lastMove.link := nil;
        moveStore.id := 99;
        moveStore.startSq := 99;
        moveStore.endSq := 99;
        wMobility := 0;
        bMobility := 0;
        gamePointer := 0;

             {initialize the game storage pointers}
        startPage := BASE2;
        dataSize := 2;

             {storePtr}
        offset := 4000;
        offset1 := 0;
        DataOps(1, startPage, dataSize, offset, offset1);
//        writeln ('STARTING');

             {storeBase}
        offset := 4002;
        offset1 := BASE4;
        DataOps(1, startPage, dataSize, offset, offset1);
        startPage := BASE;

             {initialize the game record}
        sPage := BASE2;
        dataSize := 6;
        offset := PLAYLIST;
        DataOps(1, sPage, dataSize, offset, moveStore);
        dataSize := 8;

        write(chr(7), 'enter ply: [2-6] ');
        repeat
            ans := GetKeyInt;
        until ans in[50..54];
        writeln(chr(ans));
        gamePly := ans - 48;
//        gamePly := ply;

        writeln(chr(7), 'select side to play: [w]hite/[b]lack');
        repeat
            ans := GetKeyInt;
        until ans in[66, 87];
        if ans = 66 then
            begin
                humanSide := 1;
                writeln('***playing as black***');
            end
        else
            begin
                humanSide := 0;
                writeln('***playing as white***');
            end;
            
        cWarning := 0;
        write(chr(7), 'enter position? (y/n)');
        repeat
            ans := GetKeyInt;
        until ans in[78, 89];
        if ans = 89 then
            begin
                EnterPos;
                gameSide := turn;
               {look for check condition}
                lastMove.id := 0;
                lastMove.startSq := 0;
                lastMove.endSq := 0;
                CombineTrim(bit3, bit5, lastMove);
                if gameSide = 0 then
                    offset := WKO
                else
                    offset := BKO;
                DataOps(2, startPage, dataSize, offset, bit1);
                if gameSide = 0 then
                    BitAnd(bit1, bit5, bit2)
                else
                    BitAnd(bit1, bit3, bit2);
                if not(IsClear(bit2)) then
                    cWarning := 1;
            end
        else
            begin
                turn := 0;
                gameSide := turn;
            end;

        writeln;            
        write(chr(7), 'debug log to DSK0.phoenix.log (y/n)');
        repeat
            ans := GetKeyInt;
        until ans in[78, 89];
        if ans = 89 then
            begin
                doLogging := true;
                assign (logFile, 'DSK0.phoenix.log');
                rewrite (logFile)
            end;
            
    end;


procedure check3Rep;
    begin
            {check for 3-move repetition}
        if gameMove > 6 then
            begin
                repFlag := TRUE;
                sPage := BASE2;
                tempPointer := gamePointer;
                for i := 1 to 4 do
                    begin
                        tempPointer := tempPointer - 8;
                        offset := PLAYLIST + tempPointer;
                        DataOps(2, sPage, dataSize, offset, moveStore);
                        offset := PLAYLIST + tempPointer - 32;
                        DataOps(2, sPage, dataSize, offset, tempMove);
                        // TODO: 
                        //      if moveStore <> tempMove then
                        if not compareWord (moveStore, tempMove, 4) then
                            repFlag := FALSE;
                        offset := PLAYLIST + tempPointer - 64;
                        DataOps(2, sPage, dataSize, offset, tempMove);
                        // TODO
                        //      if moveStore <> tempMove then
                        if not compareWord (moveStore, tempMove, 4) then
                            repFlag := FALSE;
                    end;
                if repFlag then
               {3x repetition. Draw}
                    begin
                        gotoxy(20, 0);
                        write(chr(7), chr(7), 'draw by 3-fold repetition!');
                        ans := GetKeyInt;
                        readln;
                        Utility(i);
                        exit;
                    end;
            end;
    end;

procedure chainMain;
    label 
        l_0, l_1, l_2;
        // TODO: numeric labels in 9900 generator do not work
    var 
        epCapDummy: integer;
    begin
        initGame;

     {start game}
        BoardDisplay;
        gotoxy(10, 1);
        writeln('move: ', gameMove);
        if gameSide = 0 then
            write('turn: white')
        else
            write('turn: black');
        if cWarning = 1 then
            begin
                gotoxy(20, 1);
                write(chr(7), chr(7), 'check!');
            end;
        ans := GetKeyInt;

        repeat
            wLAFlag := 0;
            wRAFlag := 0;
            bLAFlag := 0;
            bRAFlag := 0;
            cFlag := 0;

      {transfer current board state to temp boards}
            dataSize := 120;
            offset := WPO;
            DataOps(2, startPage, dataSize, offset, buffer);
            offset := TWPO;
            DataOps(1, startPage, dataSize, offset, buffer);

            dataSize := 8;
            moveNumLo := 0;
            moveNumHi := 0;

            aVal := -20000;
            bVal := 20000;
            moveScore := 0;

            humanFlag := FALSE;

            i := 0;

            if humanSide = gameSide then
                begin
                    humanFlag := TRUE;

        {save current game state}
                    SaveMove;

                    playerMove(playMove, lastMove, gameSide);
                    if humanSide <> gameSide then
                        i := 1;
                    if pieceCount = -1 then
                        exit;
                    if i = 1 then
                        goto l_0;

     {check if opponent's back row attacked}
                    if ((turn = 0) and (bCastleFlag = 0)) or
                       ((turn = 1) and (wCastleFlag = 0)) then
                        begin
                            offset := PIECELOC + (playMove.endSq * 8);
                            DataOps(2, startPage, dataSize, offset, bit1);
                            if turn = 0 then
                                offset := WPIECES
                            else
                                offset := BPIECES;
                            bit2 := Trim(turn, playMove.id, playMove.endSq, lastMove, WPIECES, BPIECES, APIECES, epCapDummy);

       {combine piece location with trimmed move list}
                            BitOr(bit1, bit2, bit3);
       {check right and left back rows}
                            if turn = 0 then
                                begin
                                    offset := BRBRMASK;
                                    offset1 := BLBRMASK;
                                    if (bRAFlag = 0) and (bRookRFlag = 0) then
                                        begin
                                            DataOps(2, startPage, dataSize, offset, bit6);
                                            BitAnd(bit3, bit6, bit6);
                                            if not(IsClear(bit6)) then
                                                bRAFlag := 1;
                                        end;

                                    if (bLAFlag = 0) and (bRookLFlag = 0) then
                                        begin
                                            DataOps(2, startPage, dataSize, offset1, bit6);
                                            BitAnd(bit3, bit6, bit6);
                                            if not(IsClear(bit6)) then
                                                bLAFlag := 1;
                                        end;
                                end
                            else
                                begin
                                    offset := WRBRMASK;
                                    offset1 := WLBRMASK;
                                    if (wRAFlag = 0) and (wRookRFlag = 0) then
                                        begin
                                            DataOps(2, startPage, dataSize, offset, bit6);
                                            BitAnd(bit3, bit6, bit6);
                                            if not(IsClear(bit6)) then
                                                wRAFlag := 1;
                                        end;

                                    if (wLAFlag = 0) and (wRookLFlag = 0) then
                                        begin
                                            DataOps(2, startPage, dataSize, offset1, bit6);
                                            BitAnd(bit3, bit6, bit6);
                                            if not(IsCLear(bit6)) then
                                                wLAFlag := 1;
                                        end;
                                end;
                        end;


                    l_0: 
                end
            else
                begin
        {opening move selection}
                    if gameMove = 1 then
                        begin
                            moveScore := 0;
                            //      i := Rnd_Int(3);		TODO
                            i := 2;
                            if gameSide = 0 then
                                begin
                                    case i of 
                                        1: 
                                        begin
                                            playMove.id := 0;
                                            playMove.startSq := 12;
                                            playMove.endSq := 28;
                                        end;
                                        2: 
                                        begin
                                            playMove.id := 0;
                                            playMove.startSq := 11;
                                            playMove.endSq := 27;
                                        end;
                                        3: 
                                        begin
                                            playMove.id := 16;
                                            playMove.startSq := 6;
                                            playMove.endSq := 21;
                                        end;
                                    end;
                                end
                            else
                                begin
                                    case lastMove.endSq of 
                                        12: 
                                        begin
                                            playMove.id := 0;
                                            case i of 
                                                1: 
                                                begin
                                                    playMove.startSq := 52;
                                                    playMove.endSq := 44;
                                                end;
                                                2: 
                                                begin
                                                    playMove.startSq := 51;
                                                    playMove.endSq := 43;
                                                end;
                                                3: 
                                                begin
                                                    playMove.startSq := 51;
                                                    playMove.endSq := 35;
                                                end;
                                            end;
                                        end;
                                        11,21: 
                                        begin
                                            case i of 
                                                1: 
                                                begin
                                                    playMove.id := 0;
                                                    playMove.startSq := 51;
                                                    playMove.endSq := 35;
                                                end;
                                                2: 
                                                begin
                                                    playMove.id := 16;
                                                    playMove.startSq := 62;
                                                    playMove.endSq := 45;
                                                end;
                                                3: 
                                                begin
                                                    playMove.id := 0;
                                                    playMove.startSq := 50;
                                                    playMove.endSq := 34
                                                end;
                                            end;
                                        end;
                                    end;
                                    if not(lastMove.endSq in [11, 12, 21]) then
                                        begin
                                            playMove.id := 0;
                                            playMove.startSq := 51;
                                            playMove.endSq := 35;
                                        end;
                                end;
                        end
                    else
                        begin
                            gotoxy(20, 7);
                            write('thinking...');
                            MoveGen(lastMove, playMove, moveScore, aVal, bVal, cFlag, gamePly);
                        end;
                end;

    {update move list}
            sPage := BASE2;
            dataSize := 8;
            offset := PLAYLIST + gamePointer;
            DataOps(1, sPage, dataSize, offset, playMove);
            gamePointer := gamePointer + 8;
            moveStore.id := 99;
            offset := offset + 8;
            DataOps(1, sPage, dataSize, offset, moveStore);


            if i = 1 then
                goto l_2;

            lastMove := playMove;

            if humanFlag then
                sPage := 1
            else
                sPage := 0;

            UpdateMove(playMove);

            if (wCastleFlag = 0) and (gameSide = 0) then
                begin
                    if playMove.id = 40 then
                        wCastleFlag := 1;

                    if playMove.id = 8 then
                        begin
                            if playMove.startSq = 0 then
                                wRookLFlag := 1;
                            if playMove.startSq = 7 then
                                wRookRFlag := 1;
                        end;
                end;
            if (bCastleFlag = 0) and (gameSide = 1) then
                begin
                    if playMove.id = 40 then
                        bCastleFlag := 1;

                    if playMove.id = 8 then
                        begin
                            if playMove.startSq = 56 then
                                bRookLFlag := 1;
                            if playMove.startSq = 63 then
                                bRookRFlag := 1;
                        end;
                end;

      {convert move to coordinates}
            BoardDisplay;
            CombineTrim(bit3, bit5, lastMove);

      {look for check condition}
            checkFlag := FALSE;
            cWarning := 0;
            if gameSide = 0 then
                offset := BKO
            else
                offset := WKO;
            DataOps(2, startPage, dataSize, offset, bit1);
            if gameSide = 0 then
                BitAnd(bit1, bit3, bit2)
            else
                BitAnd(bit1, bit5, bit2);
            if not(IsClear(bit2)) then
                begin
                    gotoxy(20, 1);
                    write(chr(7), chr(7), 'check!');
                    checkFlag := TRUE;
                    cWarning := 1;
                end;

     {look for checkmate or stalemate condition}
            cmFlag := FALSE;
            if checkFlag then
                begin
                    SaveBoards;
                    if gameSide = 0 then
                        begin
                            turn := 1;
                            offset := BKO;
                            offset1 := WPIECES;
                            sideOffset := BPIECES;
                        end
                    else
                        begin
                            turn := 0;
                            offset := WKO;
                            offset1 := BPIECES;
                            sideOffset := WPIECES;
                        end;

        {get opposite king position}
                    DataOps(2, startPage, dataSize, offset, bit1);
                    BitPos(bit1, moveArray);

        {obtain list of all possible opposite king movement}
                    bit2 := Trim(turn, 40, moveArray[1], lastMove, WPIECES, BPIECES, APIECES, epCapDummy);

                    if not(IsCLear(bit2)) then
                        begin
                            BitPos(bit2, moveArray);
                            for i := 1 to moveArray[0] do
                                begin
            {get opposite king's current move}
                                    offset := PIECELOC + (moveArray[i] * 8);
                                    DataOps(2, startPage, dataSize, offset, bit2);

                                    if gameSide = 0 then
                                        offset := BKO
                                    else
                                        offset := WKO;

            {remove original opposite king from king board}
                                    DataOps(2, startPage, dataSize, offset, bit3);
                                    BitNot(bit3, bit3);

            {update opposite king board with king move}
                                    DataOps(1, startPage, dataSize, offset, bit2);

            {remove original king position from APIECES}
                                    offset := APIECES;
                                    DataOps(2, startPage, dataSize, offset, bit1);
                                    BitAnd(bit3, bit1, bit1);

            {add opposite king movement to APIECES}
                                    BitOr(bit2, bit1, bit1);
                                    DataOps(1, startPage, dataSize, offset, bit1);

            {remove own pieces captured by opposite king}
                                    BitNot(bit2, bit2);
                                    DataOps(2, startPage, dataSize, offset1, bit1);
                                    BitAnd(bit2, bit1, bit1);
                                    DataOps(1, startPage, dataSize, offset1, bit1);
                                    j := 0;
                                    if gameSide = 0 then
                                        offset := WPO
                                    else
                                        offset := BPO;

                                    repeat
                                        offset2 := offset + j;
                                        DataOps(2, startPage, dataSize, offset2, bit1);
                                        BitAnd(bit2, bit1, bit1);
                                        DataOps(1, startPage, dataSize, offset2, bit1);
                                        j := j + 8;
                                    until j > 32;

            {remove original king position from opposite pieces board}
                                    DataOps(2, startPage, dataSize, sideOffset, bit1);
                                    BitAnd(bit3, bit1, bit1);

            {add opposite king move to opposite pieces board}
                                    BitNot(bit2, bit2);

                                    BitOr(bit2, bit1, bit1);
                                    DataOps(1, startPage, dataSize, sideOffset, bit1);

            {check if opposite king attacked by own side}
                                    bit8 := bit2;

                                    CombineTrim(bit3, bit5, lastMove);

                                    if gameSide = 0 then
                                        BitAnd(bit8, bit3, bit2)
                                    else
                                        BitAnd(bit8, bit5, bit2);

                                    if IsClear(bit2) then
             {if clear then no checkmate. cmFlag still FALSE at this point}
                                        goto l_1;

                                    GetBoards;
                                end;
                        end;

        {get combined trim boards without the opposite king}
                    if gameSide = 0 then
                        offset := BKO
                    else
                        offset := WKO;

        {remove opposite king from all opposite boards}
                    DataOps(2, startPage, dataSize, offset, bit2);
                    BitNot(bit2, bit2);
                    ClearBitboard(bit1);
                    DataOps(1, startPage, dataSize, offset, bit1);
                    DataOps(2, startPage, dataSize, sideOffset, bit1);
                    BitAnd(bit2, bit1, bit1);
                    DataOps(1, startPage, dataSize, sideOffset, bit1);
                    offset := APIECES;
                    DataOps(2, startPage, dataSize, offset, bit1);
                    BitAnd(bit2, bit1, bit1);
                    DataOps(1, startPage, dataSize, offset, bit1);

                    CombineTrim(bit3, bit5, lastMove);

                    if gameSide = 0 then
                        bit8 := bit5
                    else
                        bit8 := bit3;

        {check if attacking piece can be captured}
                    offset := PIECELOC + (playMove.endSq * 8);
                    DataOps(2, startPage, dataSize, offset, bit3);
                    BitAnd(bit8, bit3, bit3);
                    if not(IsClear(bit3)) then
                        goto l_1;

        {generate trim board for attacking piece}
                    if gameSide = 0 then
                        begin
                            sideOffset := WPIECES;
                            turn := 0;
                        end
                    else
                        begin
                            sideOffset := BPIECES;
                            turn := 1;
                        end;
                    bit2 := Trim(turn, playMove.id, playMove.endSq, lastMove, WPIECES, BPIECES, APIECES, epCapDummy);

        {check if any opposite piece movement blocks it}
                    BitAnd(bit2, bit8, bit1);

        {update bitboards with opposite combined trim board}
                    offset := APIECES;
                    DataOps(2, startPage, dataSize, offset, bit3);
                    BitOr(bit1, bit3, bit2);
                    DataOps(1, startPage, dataSize, offset, bit2);
                    if gameSide = 0 then
                        offset := BPIECES
                    else
                        offset := WPIECES;
                    DataOps(2, startPage, dataSize, offset, bit3);
                    BitOr(bit1, bit3, bit2);
                    DataOps(1, startPage, dataSize, offset, bit2);

        {regenerate Trim board for attacking piece}
                    if gameSide = 0 then
                        begin
                            sideOffset := WPIECES;
                            offset := BKO;
                        end
                    else
                        begin
                            sideOffset := BPIECES;
                            offset := WKO;
                        end;
                    bit2 := Trim(turn, playMove.id, playMove.endSq, lastMove, WPIECES, BPIECES, APIECES, epCapDummy);

        {check if overalp with opposite king}
                    GetBoards;
                    DataOps(2, startPage, dataSize, offset, bit1);
                    BitAnd(bit2, bit1, bit1);
                    if not(IsCLear(bit1)) then
                        cmFlag := TRUE;

                    l_1: 
                    if cmFlag then
                        begin
                            gotoxy(20, 1);
                            write(chr(7), chr(7), 'checkmate!');
                            ans := GetKeyInt;
                            readln;
                            Utility(i);
                            exit;
                        end
                    else
                        GetBoards;
                end
            else
                begin
                    if abs(moveScore) = 20000 then
                        begin
                            gotoxy(20, 1);
                            write(chr(7), chr(7), 'resign!');
                            ans := GetKeyInt;
                            readln;
                            Utility(i);
                            exit;
                        end;
                end;

            if humanFlag then
                begin
                    gotoxy(20, 7);
                    write('thinking...');
                end;

            if gameSide = 0 then
                begin
                    gameSide := 1;
                    turn := 1;
                    gotoxy(0, 2);
                    write('turn: black');
                end
            else
                begin
                    gameSide := 0;
                    turn := 0;
                    gameMove := succ(gameMove);
                    gotoxy(0, 2);
                    write('turn: white');
                end;

            check3Rep;

            gotoxy(10, 1);
            writeln('move: ', gameMove);

            MoveCoord(moveScore, playMove.startSq, playMove.endSq, humanFlag);
            ans := GetKeyInt;
//            ply := gamePly;
            l_2: 
        until FALSE;
    end;

end.
