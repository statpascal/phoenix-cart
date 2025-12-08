unit Move;

interface

uses globals;

procedure MoveGen (var board: TBoardRecord; lastMove: moverec; var finalMove: moverec;
                   var score: integer; alpha, beta: integer; cMoveFlag, ply, turn: integer);

procedure dumpBitBoard (var b: bitboard);

implementation

uses scorepos, trimprocs, utility, resources;

(* encoding of moves on move stack:

   15    $8000    attack flag
   14-12 $7000    piece type (0 - pawn to 5 - king)
   11-06 $0FC0    start square
   05-00 $003f    end square
*)   

const
    MoveStackSize = 4095;

var
    moveStack: array [0..MoveStackSize] of integer absolute $2000;
    moveStackPointer: integer;
    
procedure pushMoveStack (attackFlag: boolean; id, startSq, endSq: integer);
    begin
        if moveStackPointer <= moveStackSize then
            begin
                moveStack [moveStackPointer] := ord (attackFlag) shl 15 + (id shr 3) shl 12 + startSq shl 6 + endSq;
                inc (moveStackPointer)
            end
    end;
    
procedure readMoveStack (index: integer; var attackFlag: boolean; var id, startSq, endSq: integer);
    var
        val: integer;
    begin
        val := moveStack [index];
        endSq := val and $3f;
        startSq := (val shr 6) and $3f;
        id := (val shr 12) and $7 shl 3;
        attackFlag := boolean (val shr 15 and 1)
    end;

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
        if move.id <> InvalidPiece then
            begin
                write (logFile, pieceName [succ (move.id shr 3)]);
                writeCoord (move.startSq);
                write (logFile, '-');
                writecoord (move.endSq)
            end
        else
            write (logFile, 'None')
    end;

procedure loopAllPieces (var board: TBoardRecord; turn: integer; var lastMove: moverec);
    var 
        j, l, n, pLoc, epCapFlag: integer;
        posArray, moveArray: bitArray;
        currentMoveBoard, attackBoard, bit3, bit5, bit8, bit9: bitboard;
        
    procedure createMoveNodes (attackFlag: boolean; id, startSq: integer; var endSquares: bitboard);
        var
            k: integer;
            moveArray: bitArray;
        begin
            BitPos (endSquares, moveArray);
            for k := 1 to moveArray [0] do
                pushMoveStack (attackFlag, id, startSq, moveArray [k])
        end;
        
    procedure checkCastling (var board: TBoardRecord);
        var castleRights: integer;
        begin
            castleRights := checkCastleRights (board, turn);
            if castleRights = 0 then
                exit;
            if turn = 0 then
                begin
                    if castleRights and whiteLeftCastleRight <> 0 then
                        pushMoveStack (false, King, 4, 2);
                    if castleRights and whiteRightCastleRight <> 0 then
                        pushMoveStack (false, King, 4, 6)
                end
            else
                begin
                    if castleRights and blackLeftCastleRight <> 0 then
                        pushMoveStack (false, King, 60, 58);
                    if castleRights and blackRightCastleRight <> 0 then
                        pushMoveStack (false, King, 60, 62)
                end
        end;
        
    begin
        checkCastling (board);
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

                    createMoveNodes (true, j, pLoc, attackBoard);

                    {find non-capture moves and add to move list}
                    BitAndNot (currentMoveBoard, attackBoard, currentMoveBoard);
                    createMoveNodes (false, j, pLoc, currentMoveBoard)
                end;
            inc (j, 8)
        until j > 40;
        
    end;
    
procedure MoveGen (var board: TBoardRecord; lastMove: moverec; var finalMove: moverec; var score: integer; alpha, beta: integer; cMoveFlag, ply, turn: integer);
    var 
        i, attackId, capId, bestScore, validMoveCount: integer;
        switchFlag: integer;
        evalScore: integer;
        attackFlag, foundFlag: boolean;
        bestMove, tempMove: moverec;
        workBoard: TBoardRecord;
        savedMoveStackPointer: integer;
        
    procedure iterateMoveList;
        var
            attackMoves: boolean;
            currentMoveindex: integer;
        begin
            for attackMoves := true downto false do
                for currentMoveIndex := savedMoveStackPointer to pred (moveStackPointer) do
                    begin
                        readMoveStack (currentMoveIndex, attackFlag, tempMove.id, tempMove.startSq, tempMove.endSq);
                        if attackFlag = attackMoves then
                            begin
                                workBoard := board;
                                enterMove (turn, ord (attackFlag), attackId, capId, foundFlag, workBoard, tempMove);
                                // TODO: do not set castle flags for decision tree
                                workBoard.castleFlags := board.castleFlags;
                                
                                {check for castling move}
                                if (tempMove.id = 40) and (ply = gamePly) and (abs (tempMove.startSq - tempMove.endSq) = 2) then
                                    cMoveFlag := 1;

                                {check if own king in check after current move}
                                if not isKingChecked (turn, workBoard) then 
                                    begin
                                        inc (validMoveCount);
                                        if not foundFlag and (ply <= 1) or (ply = plyQS) then
                                            {terminal node check}
                                            begin
                                                {update number of positions evaluated}
                                                inc (moveNumLo);
                                                if (moveNumLo = 1000) then
                                                    begin
                                                        moveNumLo := 0;
                                                        inc (moveNumHi)
                                                    end;
                                                evalScore := Evaluate (cMoveFlag, ord (attackFlag), attackId, capId, lastMove, tempMove, workBoard, turn);
                                                if doLogging then begin   
                                                    indent (ply - 1); 
                                                    printMove (tempMove); 
                                                    writeln (logFile, ': ', evalScore: 6)
                                                end
                                            end
                                        else
                                            begin
                                                MoveGen (workBoard, tempMove, finalMove, evalScore, alpha, beta, cMoveFlag, pred (ply), 1 - turn);
                                                if ply = gamePly then
                                                    cMoveFlag := 0
                                            end;

                                        {alpha/beta selection}
                                        if turn = 0 then
                                            begin
                                                if evalScore >= bestScore then
                                                    begin
                                                        bestScore := evalScore;
                                                        bestMove := tempMove
                                                    end;
                                                if bestScore > beta then
                                                    exit
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
                                                    exit
                                                else
                                                    if bestScore < beta then
                                                        beta := bestScore;
                                            end
                                    end
                            end
                    end
        end;
        

    begin
        savedMoveStackPointer := moveStackPointer;

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

        loopAllPieces (board, turn, lastMove);
//        if doLogging then begin
//            indent (ply); writeln (logFile, 'Move stack: ', moveStackPointer, ' positions')
//        end;
        bestMove.id := InvalidPiece;

        if turn = 0 then
            bestScore := -20000
        else
            bestScore := 20000;

        validMoveCount := 0;
        iterateMoveList;

        {stalemate condition}
        if (validMoveCount = 0) and not isKingChecked (turn, board) then
            begin
                if ply = gamePly then
                    begin
                        gotoxy(20, 1);
                        write(chr(7), chr(7), 'stalemate!');
                        i := GetKeyInt;
                        readln;
                        Utility(switchFlag);
                        // TODO: where to go from here
                    end
                else
                    score := 0;
                exit
            end;

        finalMove := bestMove;
        score := bestScore;
        
        if doLogging then begin
            indent (pred (ply)); 
            write (logFile, 'Best: '); 
            printMove (finalMove); 
            writeln (logfile, ': ', score:6)
        end;

        moveStackPointer := savedMoveStackPointer;
    end;

begin
    moveStackPointer := 0
end.
