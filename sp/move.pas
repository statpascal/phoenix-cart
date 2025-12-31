unit Move;

interface

uses globals, board;

procedure MoveGen (var board: TBoardRecord; lastMove: moverec; var finalMove: moverec;
                   var score: integer; aggMoveScores, alpha, beta, ply, turn: integer);


implementation

uses scorepos, trimprocs, 
{$ifdef ti99}
utility, 
{$endif}
resources, logger, bitops;

(* encoding of moves on move stack:

   15    $8000    attack flag
   14-12 $7000    piece type (0 - pawn to 5 - king)
   11-06 $0FC0    start square
   05-00 $003f    end square
*)   

const
    MoveStackSize = 4095;

var
{$ifdef ti99}
    moveStack: array [0..MoveStackSize] of integer absolute $2000;
{$endif}
{$ifdef fpc}
    moveStack: array [0..MoveStackSize] of integer;
{$endif}
    moveStackPointer: integer;
    
procedure pushMoveStack (attackFlag: boolean; id, startSq, endSq: integer);
    begin
        if moveStackPointer <= moveStackSize then
            begin
                moveStack [moveStackPointer] := ord (attackFlag) shl 15 + id shl 12 + startSq shl 6 + endSq;
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
        id := (val shr 12) and $7;
        attackFlag := boolean (val shr 15 and 1)
    end;

procedure loopAllPieces (var board: TBoardRecord; turn: integer; var lastMove: moverec);
    var 
        piece, l, pLoc, epCapSquare: integer;
        posArray: bitArray;
        currentMoveBoard, attackBoard: bitboard;
        
    procedure createMoveNodes (attackFlag: boolean; id, startSq: integer; endSquares: bitboard);
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
                    if castleRights and whiteLeftCastle <> 0 then
                        pushMoveStack (false, King, 4, 2);
                    if castleRights and whiteRightCastle <> 0 then
                        pushMoveStack (false, King, 4, 6)
                end
            else
                begin
                    if castleRights and blackLeftCastle <> 0 then
                        pushMoveStack (false, King, 60, 58);
                    if castleRights and blackRightCastle <> 0 then
                        pushMoveStack (false, King, 60, 62)
                end
        end;
        
    begin
        checkCastling (board);
        for piece := Pawn to King do
            begin
                BitPos (board.sides [turn].bitboards [piece], posArray);
                for l := 1 to posArray [0] do
                    begin
                        pLoc := posArray[l];
                        currentMoveBoard := Trim (turn, piece, pLoc, board, epCapSquare);
                        attackBoard := currentMoveBoard and board.sides [1 - turn].pieces;
                        {re-add en passant capture squares}
                        if epCapSquare <> -1 then
                            setBit (attackBoard, epCapSquare);
                            
                        createMoveNodes (true, piece, pLoc, attackBoard);
                        createMoveNodes (false, piece, pLoc, currentMoveBoard and not attackBoard)
                    end
            end
    end;
    
function iterateMoveList (var board: TBoardRecord; turn, ply, startIndex, endIndex, aggMoveScores, alpha, beta: integer; var validMoveCount, bestScore: integer; var bestMove: moverec): boolean;
    var
        attackFlag, foundFlag: boolean;
        attackMoves: boolean;
        attackId, capId, currentMoveindex: integer;
        evalScore, evalMove, moveScore: integer;
        resultMove, tempMove: moverec;
        workBoard: TBoardRecord;
    begin
        iterateMoveList := true;
        for attackMoves := true downto false do
            for currentMoveIndex := startIndex to endIndex do
                begin
                    readMoveStack (currentMoveIndex, attackFlag, tempMove.id, tempMove.startSq, tempMove.endSq);
                    if attackFlag = attackMoves then
                        begin
                            workBoard := board;
                            enterMove (turn, ord (attackFlag), attackId, capId, foundFlag, workBoard, tempMove);
                            
                            {check if own king in check after current move}
                            if not isKingChecked (turn, workBoard) then 
                                begin
                                    evalMove := evaluateMove (turn, board, attackFlag, tempMove, capId);
                                    if turn = 0 then
                                        moveScore := aggMoveScores + evalMove
                                    else
                                        moveScore := aggMoveScores - evalMove;
                                        
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
                                            evalScore := EvaluatePosition (turn, workBoard, tempMove) + moveScore;
                                            if doLogging then begin   
                                                indent (ply - 1); 
                                                printMove (logFile, tempMove); 
                                                writeln (logFile, ': ', evalScore: 6)
                                            end
                                        end
                                    else
                                        begin
                                            MoveGen (workBoard, tempMove, resultMove, evalScore, moveScore, alpha, beta, pred (ply), 1 - turn);
                                        end;

                                    {alpha/beta selection}
                                    if turn = 0 then
                                        begin
                                            if evalScore >= bestScore then
                                                begin
                                                    bestScore := evalScore;
                                                    bestMove := tempMove
                                                end;
                                            if not disableAlphaBetaPruning and (bestScore > beta) then
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
                                            if not disableAlphaBetaPruning and (bestScore < alpha) then
                                                exit
                                            else
                                                if bestScore < beta then
                                                    beta := bestScore;
                                        end
                                end
                        end
                end;
        iterateMoveList := false
    end;
    
procedure MoveGen (var board: TBoardRecord; lastMove: moverec; var finalMove: moverec;
                   var score: integer; aggMoveScores, alpha, beta, ply, turn: integer);
    var 
        bestScore, validMoveCount: integer;
        switchFlag: integer;
        bestMove: moverec;
        savedMoveStackPointer: integer;
        pruned: boolean;
    begin
        savedMoveStackPointer := moveStackPointer;

        if doLogging then begin
            if ply = gamePly then
                begin
                    printBoard (logFile, board);
                    write (logFile, 'Last move: ');
                    printMove (logFile, lastMove);
                    writeln (logFile)
                end
            else
                begin                    
                    indent (ply); 
                    printMove (logFile, lastmove); 
                    writeln (logFile, ': alpha = ', alpha, ' beta = ', beta)
                end
        end;

        loopAllPieces (board, turn, lastMove);
        bestMove.id := InvalidPiece;

        if turn = 0 then
            bestScore := -20000
        else
            bestScore := 20000;

        validMoveCount := 0;
        pruned := iterateMoveList (board, turn, ply, savedMoveStackPointer, pred (moveStackPointer), aggMoveScores, alpha, beta, validMoveCount,  bestScore, bestMove);

        {stalemate condition}
        if (validMoveCount = 0) and not isKingChecked (turn, board) then
            begin
                if ply = gamePly then
                    begin
{$ifdef ti99}                    
                        gotoxy(20, 1);
                        write(chr(7), chr(7), 'stalemate!');
                        readln;
                        Utility(switchFlag);
                        // TODO: where to go from here
{$endif}                        
                    end
                else
                    score := 0;
                exit
            end;

        finalMove := bestMove;
        score := bestScore;
        
        if doLogging then begin
            indent (pred (ply)); 
            if pruned then
                writeln (logFile, 'Pruned')
            else
                begin
                    write (logFile, 'Best: '); 
                    printMove (logFile, finalMove); 
                    writeln (logfile, ': ', score:6)
                end
        end;

        moveStackPointer := savedMoveStackPointer;
    end;

begin
    moveStackPointer := 0
end.
