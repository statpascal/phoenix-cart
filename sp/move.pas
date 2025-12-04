unit Move;

interface

uses globals;

procedure MoveGen (var board: TBoardRecord; lastMove: moverec; var finalMove: moverec;
                   var score: integer; alpha, beta: integer; cMoveFlag, ply, turn: integer);

procedure dumpBitBoard (var b: bitboard);

implementation

uses scorepos, trimprocs, utility, resources;

procedure indent (ply: integer);
    begin
        write (logFile, ' ' : 4 * (gameply - ply))
    end;        

procedure dumpBitBoard (var b: bitboard);
    var
        i, j, k, val: integer;
    begin
        for i := 3 downto 0 do
            begin
                val := b [i];
                for j := 1 to 2 do
                    begin
                        for k := 0 to 7 do
                            write (logFile, ord (val and (1 shl (7 - k)) <> 0));
                        writeln (logFile);
                        val := val shr 8;
                    end
            end
    end;


procedure printBoard (var board: TBoardRecord);
    const 
        figure: array [0..1, 0..5] of char = (('^', 'R', 'N', 'B', 'Q', 'K'),
                                              ('v', 'r', 'n', 'b', 'q', 'k'));
    var
        s: array [0..7] of string [8];
        side, piece, i, j: integer;
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
                    if side = 0 then
                        BitPos (board.white.bitboards [piece], pos)
                    else
                        BitPos (board.black.bitboards [piece], pos);
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
        else
            write (logFile, 'None')
    end;

procedure loopAllPieces (var board: TBoardRecord; turn: integer; var lastMove: moverec; attackIndex, tailIndex: listPointer; ply: integer);
    var 
        j, l, n, pLoc, epCapFlag: integer;
        posArray, moveArray: bitArray;
        currentMoveBoard, attackBoard, bit3, bit5, bit8, bit9: bitboard;
        
    procedure appendMove (var list: listPointer; id, startSq, endSq: integer);
        begin
            new (list^.link);
            list^.id := id;
            list^.startSq := startSq;
            list^.endSq := endSq;
            list := list^.link;
            list^.link := nil
        end;
        
    procedure createMoveNodes (var list: listPointer; id, startSq: integer; var endSquares: bitboard);
        var
            k: integer;
            moveArray: bitArray;
        begin
            BitPos (endSquares, moveArray);
            for k := 1 to moveArray [0] do
                appendMove (list, id, startSq, moveArray [k])
        end;
        
    procedure checkCastling (var board: TBoardRecord; var moveList: listPointer);
        var castleRights: integer;
        begin
            castleRights := checkCastleRights (board, turn);
            if castleRights = 0 then
                exit;
            if turn = 0 then
                begin
                    if castleRights and whiteLeftCastleRight <> 0 then
                        appendMove (moveList, King, 4, 2);
                    if castleRights and whiteRightCastleRight <> 0 then
                        appendMove (moveList, King, 4, 6)
                end
            else
                begin
                    if castleRights and blackLeftCastleRight <> 0 then
                        appendMove (moveList, King, 60, 58);
                    if castleRights and blackRightCastleRight <> 0 then
                        appendMove (moveList, King, 60, 62)
                end
        end;
        
    begin
        checkCastling (board, tailIndex);
        j := 0;
        repeat
            if turn = 0 then
                BitPos (board.white.bitboards [j shr 3], posArray)
            else
                BitPos (board.black.bitboards [j shr 3], posArray);
            for l := 1 to posArray [0] do
                begin
                    {loop through all existing pieces of current type}
                    pLoc := posArray[l];
                    epCapFlag := 0;
                    currentMoveBoard := Trim (turn, j, pLoc, lastMove, board, epCapFlag);

                    {skip king move if no valid move on first ply}
                    {allows for stalemate detection}
                    if (j = 40) and (ply = gamePly) then
                        begin
                            CombineTrim(bit3, bit5, lastMove, board);
                            
                            {check if king movement overlaps opposite pieces combined movement}
                            if turn = 0 then 
                                BitAnd(currentMoveBoard, bit5, bit8)
                            else
                                BitAnd(currentMoveBoard, bit3, bit8);
                                
                            BitPos(bit8, moveArray);
                            n := moveArray[0];
                            BitPos(currentMoveBoard, moveArray);
                            if n = moveArray[0] then
                                exit	// all pieces done - return
                        end;

                    {find potential captures and add to attack list}
                    if turn = 0 then
                        BitAnd (currentMoveBoard, board.blackPieces, attackBoard)
                    else
                        BitAnd (currentMoveBoard, board.whitePieces, attackBoard);

                    {re-add any en passant capture squares}
                    if epCapFlag = 1 then
                        begin
                            if turn = 0 then
                                bit5 := getMovementBitboard (WhitePawnCapture, pLoc)
                            else
                                bit5 := getMovementBitboard (BlackPawnCapture, pLoc);
                            BitAnd(currentMoveBoard, bit5, bit5);
                            BitOr(attackBoard, bit5, attackBoard);
                        end;

                    createMoveNodes (attackIndex, j, pLoc, attackBoard);

                    {find non-capture moves and add to move list}
                    BitAndNot (currentMoveBoard, attackBoard, currentMoveBoard);
                    createMoveNodes (tailIndex, j, pLoc, currentMoveBoard)
                end;
            inc (j, 8)
        until j > 40;
        
    end;
    
procedure MoveGen (var board: TBoardRecord; lastMove: moverec; var finalMove: moverec; var score: integer; alpha, beta: integer; cMoveFlag, ply, turn: integer);
    var 
        i, attackId, capId, bestScore: integer;
        switchFlag: integer;
        attackFlag, evalScore: integer;
        foundFlag, pruneFlag, ignoreMove: boolean;
        bestMove, tempMove: moverec;
        moveList, attackList, tailIndex, attackIndex, currentMove: listPointer;
        workBoard: TBoardRecord;
        heap: pointer;

    begin
        mark (heap);

        if doLogging then begin
            if ply = gamePly then
                begin
                    printBoard (board);
                    write (logFile, 'Last move: ');
                    printMove (lastMove);
                    writeln (logFile)
                end
            else
                begin                    
                    indent (ply); 
                    printMove (lastmove); 
                    writeln (logFile, ': alpha = ', alpha, ' beta = ', beta)
                end
        end;

        pruneFlag := false;
        ignoreMove := false;

        new(moveList);
        new(attackList);
        moveList^.link := nil;
        attackList^.link := nil;
        tailIndex := moveList;
        attackIndex := attackList;

        loopAllPieces (board, turn, lastMove, attackIndex, tailIndex, ply);
        bestMove.id := 99;

        if turn = 0 then
            bestScore := -20000
        else
            bestScore := 20000;

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

        repeat
            tempMove := currentMove^;
            workBoard := board;
            enterMove (turn, attackFlag, attackId, capId, foundFlag, workBoard, tempMove);
            // TODO: do not set castle flags for decision tree
            workBoard.castleFlags := board.castleFlags;
            
            {check for castling move}
            if (currentMove^.id = 40) and (ply = gamePly) and (abs (currentMove^.startSq - currentMove^.endSq) = 2) then
                cMoveFlag := 1;

            {check if own king in check after current move}
//            if (cWarning = 1) and (ply = gamePly) then
            ignoreMove := isKingChecked (turn, workBoard);

            if not ignoreMove then 
                begin
                    if not foundFlag and (ply <= 1) or (ply = -1) then
                        {terminal node check}
                        begin
                            {update number of positions evaluated}
                            inc (moveNumLo);
                            if (moveNumLo = 1000) then
                                begin
                                    moveNumLo := 0;
                                    inc (moveNumHi)
                                end;
                            evalScore := Evaluate (cMoveFlag, attackFlag, attackId, capId, lastMove, tempMove, workBoard, turn);
                            if doLogging then begin   
                                indent (ply - 1); 
                                printMove (tempMove); 
                                writeln (logFile, ': ', evalScore: 6)
                            end
                        end
                    else
                        begin
  //                          turn := 1 - turn;
                            MoveGen (workBoard, tempMove, finalMove, evalScore, alpha, beta, cMoveFlag, pred (ply), 1 - turn);
                            if ply = gamePly then
                                cMoveFlag := 0
                        end;

                    {alpha/beta selection}
                    pruneFlag := false;
                    if turn = 0 then
                        begin
                            if evalScore >= bestScore then
                                begin
                                    bestScore := evalScore;
                                    bestMove := tempMove
                                end;
                            if bestScore > beta then
                                pruneFlag := true
                            else
                                if bestScore > alpha then
                                    alpha := bestScore;
                        end
                    else
                        begin
                            if evalScore <= bestScore then
                                begin
                                    bestScore := evalScore;
                                    bestMove := tempMove
                                end;
                            if bestScore < alpha then
                                pruneFlag := true
                            else
                                if bestScore < beta then
                                    beta := bestScore;
                        end
                end;

            currentMove := currentMove^.link;
            if (currentMove^.link = nil) and (attackFlag = 1) then
                begin
                    attackFlag := 0;
                    currentMove := moveList;
                end
        until (currentMove^.link = nil) or pruneFlag;

        finalMove := bestMove;
        score := bestScore;
        
        if doLogging then begin
            indent (pred (ply)); 
            write (logFile, 'Best: '); 
            printMove (finalMove); 
            writeln (logfile, ': ', score:6)
        end;

        {up 1 ply}
//        turn := 1 - turn;
        release (heap)
    end;

end.
