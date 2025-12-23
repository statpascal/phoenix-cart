unit Move;

interface

uses globals;

procedure MoveGen (var board: TBoardRecord; lastMove: moverec; var finalMove: moverec;
                   var score: integer; alpha, beta: integer; ply, turn: integer);


implementation

uses scorepos, trimprocs, utility, resources, logger;

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
        piece, l, n, pLoc, epCapSquare: integer;
        posArray, moveArray: bitArray;
        currentMoveBoard, attackBoard, bits: bitboard;
        
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
        
    const
        EPBitboard: array [0..1] of TBitboardType = (WhitePawnCapture, BlackPawnCapture);
        
    begin
        checkCastling (board);
        for piece := Pawn to King do
            begin
                BitPos (board.side [turn].bitboards [piece], posArray);
                for l := 1 to posArray [0] do
                    begin
                        pLoc := posArray[l];
                        currentMoveBoard := Trim (turn, piece, pLoc, board, epCapSquare);
                        attackBoard := currentMoveBoard and board.side [1 - turn].pieces;
                        {re-add en passant capture squares}
                        if epCapSquare <> -1 then
                            setBit (attackBoard, epCapSquare);
//                            attackBoard := attackBoard or currentMoveBoard and getMovementBitboard (EPBitboard [turn], pLoc);
                            
                        createMoveNodes (true, piece, pLoc, attackBoard);
                        createMoveNodes (false, piece, pLoc, currentMoveBoard and not attackBoard)
                    end
            end
    end;
    
procedure MoveGen (var board: TBoardRecord; lastMove: moverec; var finalMove: moverec; var score: integer; alpha, beta: integer; ply, turn: integer);
    var 
        attackId, capId, bestScore, validMoveCount: integer;
        switchFlag: integer;
        evalScore, moveScore: integer;
        attackFlag, foundFlag: boolean;
        bestMove, tempMove: moverec;
        workBoard: TBoardRecord;
        savedMoveStackPointer: integer;
        
    procedure iterateMoveList;
        var
            attackMoves, haveAttackMove: boolean;
            currentMoveindex: integer;
        begin
            haveAttackMove := false;
            for attackMoves := true downto false do
                for currentMoveIndex := savedMoveStackPointer to pred (moveStackPointer) do
                    begin
                        readMoveStack (currentMoveIndex, attackFlag, tempMove.id, tempMove.startSq, tempMove.endSq);
                        if attackFlag = attackMoves then
                            begin
                                workBoard := board;
                                enterMove (turn, ord (attackFlag), attackId, capId, foundFlag, workBoard, tempMove);
                                
                                
                                // alternative: activate QS if any capturing move is possbible
//                                if attackMoves then
//                                    haveAttackMove := true;
                                haveAttackMove := foundFlag;
                                
                                {check if own king in check after current move}
                                if not isKingChecked (turn, workBoard) then 
                                    begin
                                        moveScore := evaluateMove (turn, board, attackMoves, tempMove, capId);
                                        inc (validMoveCount);
                                        if not haveAttackMove and (ply <= 1) or (ply = plyQS) then
                                            {terminal node check}
                                            begin
                                                {update number of positions evaluated}
                                                inc (moveNumLo);
                                                if (moveNumLo = 1000) then
                                                    begin
                                                        moveNumLo := 0;
                                                        inc (moveNumHi)
                                                    end;
//                                                evalScore := EvaluatePosition (cMoveFlag, ord (attackFlag), attackId, capId, lastMove, tempMove, workBoard, turn);
                                                evalScore := EvaluatePosition (turn, workBoard, tempMove);
                                                if doLogging then begin   
                                                    indent (ply - 1); 
                                                    printMove (logFile, tempMove); 
                                                    if turn = 0 then
                                                        writeln (logFile, ': ', evalScore + moveScore: 6)
                                                    else
                                                        writeln (logFile, ': ', evalScore - moveScore: 6)
                                                end
                                            end
                                        else
                                            begin
                                                MoveGen (workBoard, tempMove, finalMove, evalScore, alpha, beta, pred (ply), 1 - turn);
                                            end;

                                        {alpha/beta selection}
                                        if turn = 0 then
                                            begin
                                                inc (evalScore, moveScore);
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
                                                dec (evalScore, moveScore);
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
                    end
        end;
        

    begin
        savedMoveStackPointer := moveStackPointer;

        if doLogging then begin
            if ply = gamePly then
                begin
                    printBoard (board);
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
            printMove (logFile, finalMove); 
            writeln (logfile, ': ', score:6)
        end;

        moveStackPointer := savedMoveStackPointer;
    end;

begin
    moveStackPointer := 0
end.
