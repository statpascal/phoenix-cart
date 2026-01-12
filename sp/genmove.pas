unit genmove;

interface

uses globals, board;

procedure generateMove (ply, turn: integer; var board: TBoardRecord; var move: TMoveRecord; var score: integer); 

implementation

uses scorepos, trimprocs, 
{$ifdef ti99}
utility, 
{$endif}
resources, logger, bitops;

const
    MoveStackSize = 2047;

var
{$ifdef ti99}
    moveStack: array [0..MoveStackSize] of TMoveRecord absolute $2000;
{$endif}
{$ifdef fpc}
    moveStack: array [0..MoveStackSize] of TMoveRecord;
{$endif}
    moveStackPointer: integer;
    
procedure pushMoveStack (var move: TMoveRecord); overload;
    begin
        if moveStackPointer <= moveStackSize then
            begin
                moveStack [moveStackPointer] := move;
                inc (moveStackPointer)
            end
    end;
    
procedure pushMoveStack (attack: boolean; pieceType, startSq, endSq: integer); overload;
    var
        move: TMoveRecord;
    begin
        move.startSq := startSq;
        move.endSq := endSq;
        move.pieceType := pieceType;
        move.flags := ord (attack);
        pushMoveStack (move)
    end;
    
const
    MinPly = -5;
    
var
    valueCaptureBoard: array [Pawn..Bishop] of bitboard;
    killerMoves: array [MinPly..MaxPly, 0..1] of TMoveRecord;

procedure loopAllPieces (var board: TBoardRecord; ply, turn, moveStackBegin: integer);
    const
        MaxMoves = 218;
    var 
        piece, l, pLoc, epCapSquare: integer;
        posArray: bitArray;
        currentMoveBoard, attackBoard: bitboard;
        attackMoves, moves: array [0..MaxMoves] of TMoveRecord;
        attackMoveCount, moveCount: integer;
    
    procedure createMoveNodes (attackFlag: boolean; id, startSq: integer; endSquares: bitboard);
        var
            k, piece: integer;
            move: TMoveRecord;
            moveArray: bitArray;
            
        procedure registerMove (attackFlag: boolean; var move: TMoveRecord);
            begin
                if attackFlag then
                    if (move.pieceType <= Bishop) and (getBit (valueCaptureBoard [move.pieceType], move.endSq) <> 0) then
                        pushMoveStack (move)
                    else
                        begin
                            attackMoves [attackMoveCount] := move;
                            inc (attackMoveCount)
                        end
                else
                    if (ply >= MinPly) and ((compareByte (move, killerMoves [ply, 0], sizeof (TMoveRecord)) = 0) or (compareByte (move, killerMoves [ply, 1], sizeof (TMoveRecord)) = 0)) then
                        begin
                            attackMoves [attackMoveCount] := move;
                            inc (attackMoveCount)
                        end
                    else
                        begin
                            moves [moveCount] := move;
                            inc (moveCount)
                        end
            end;
            
        begin
            move.startSq := startSq;
            move.pieceType := id;
            move.flags := ord (attackFlag);
            
            BitPos (endSquares, moveArray);
            for k := 1 to moveArray [0] do
                begin
                    move.endSq := moveArray [k];
                    if (id = Pawn) and (move.endSq in [0..7, 56..63]) then
                        for piece := Rook to Queen do
                            begin
                                move.flags := piece shl 4 or ord (attackFlag);
                                registerMove (attackFlag, move)
                            end
                    else
                        registerMove (attackFlag, move)
                end
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
        
        valueCaptureBoard [Pawn] := board.sides [1 - turn].pieces and not board.sides [1 - turn].pawnBitboard;
        valueCaptureBoard [Rook] := board.sides [1 - turn].queenBitboard;
        valueCaptureBoard [Knight] := board.sides [1 - turn].rookBitboard or board.sides [1 - turn].queenBitboard;
        valueCaptureBoard [Bishop] := valueCaptureBoard [Knight];
        
        attackMoveCount := 0;
        moveCount := 0;
        
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
            end;
            
        move (attackMoves, moveStack [moveStackPointer], attackMoveCount * sizeof (TMoveRecord));
        move (moves, moveStack [moveStackPointer + attackMoveCount], moveCount * sizeof (TMoveRecord));
        inc (moveStackPointer, attackMoveCount + moveCount);
        
    end;
    
procedure MoveGen (var board: TBoardRecord; lastMove: TMoveRecord; var finalMove: TMoveRecord;
                   var score: integer; aggMoveScores, alpha, beta, ply, turn: integer); forward;
                   
function iterateMoveList (var board: TBoardRecord; turn, ply, startIndex, endIndex, aggMoveScores, alpha, beta: integer; var validMoveCount, bestScore: integer; var bestMove: TMoveRecord): boolean;
    var
        attackMoves: boolean;
        capId, currentMoveindex: integer;
        evalScore, evalMove, moveScore: integer;
        resultMove, tempMove: TMoveRecord;
        workBoard: TBoardRecord;
    begin
        iterateMoveList := true;
        for attackMoves := true downto false do
            for currentMoveIndex := startIndex to endIndex do
                begin
                    tempMove := moveStack [currentMoveIndex];
                    if tempMove.flags and AttackMove = ord (attackMoves) then
                        begin
                            workBoard := board;
                            enterMove (turn, ord (AttackMoves), capId, workBoard, tempMove);
                            
                            {check if own king in check after current move}
                            if not isKingChecked (turn, workBoard) then 
                                begin
                                    evalMove := evaluateMove (turn, board, attackMoves, tempMove, capId);
                                    if turn = 0 then
                                        moveScore := aggMoveScores + evalMove
                                    else
                                        moveScore := aggMoveScores - evalMove;
                                        
                                    inc (validMoveCount);
                                    if not attackMoves and (ply <= 1) or (ply = plyQS) then
                                        {terminal node check}
                                        begin
                                            {update number of positions evaluated}
                                            inc (moveNumLo);
                                            if (moveNumLo = 1000) then
                                                begin
                                                    moveNumLo := 0;
                                                    inc (moveNumHi)
                                                end;
                                            evalScore := EvaluatePosition (turn, workBoard) + moveScore;
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
                                                begin
                                                    {save killer move}
                                                    if not attackMoves and (ply >= MinPly) and (compareByte (tempMove, killerMoves [ply, 0], sizeof (TMoveRecord)) <> 0) then
                                                        begin
//                                                            write ('ply: ', ply, ' '); printMove (output, tempMove); writeln;
                                                            killerMoves [ply, 1] := killerMoves [ply, 0];
                                                            killerMoves [ply, 0] := tempMove;
                                                        end;
                                                    exit
                                                end
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
                                                begin
                                                    {save killer move}
                                                    if not attackMoves and (ply >= MinPly) and (compareByte (tempMove, killerMoves [ply, 0], sizeof (TMoveRecord)) <> 0) then
                                                        begin
//                                                            write ('ply: ', ply, ' '); printMove (output, tempMove); writeln;
                                                            killerMoves [ply, 1] := killerMoves [ply, 0];
                                                            killerMoves [ply, 0] := tempMove;
                                                        end;
                                                    exit
                                                end
                                            else
                                                if bestScore < beta then
                                                    beta := bestScore;
                                        end
                                end
                        end
                end;
        iterateMoveList := false
    end;
    
procedure MoveGen (var board: TBoardRecord; lastMove: TMoveRecord; var finalMove: TMoveRecord;
                   var score: integer; aggMoveScores, alpha, beta, ply, turn: integer);
    var 
        bestScore, validMoveCount: integer;
        switchFlag: integer;
        bestMove: TMoveRecord;
        savedMoveStackPointer: integer;
        pruned: boolean;
    begin
        savedMoveStackPointer := moveStackPointer;

        if doLogging then begin
            if ply = gamePly then
                printBoard (logFile, board)
            else
                begin                    
                    indent (ply); 
                    printMove (logFile, lastmove); 
                    writeln (logFile, ': alpha = ', alpha, ' beta = ', beta)
                end
        end;

        loopAllPieces (board, ply, turn, savedMoveStackPointer);
        bestMove.pieceType := InvalidPiece;

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
    
procedure generateMove (ply, turn: integer; var board: TBoardRecord; var move: TMoveRecord; var score: integer);
    const
        alpha = -20000;
        beta = 20000;
    var
        dummyMove: TMoveRecord;
        i, j: integer;
    begin
        fillchar (dummyMove, sizeof (dummyMove), 0);
        for i := 0 to ply do
            for j := 0 to 1 do
                killerMoves [i, j] := dummyMove;
        MoveGen (board, dummyMove, move, score, 0, alpha, beta, ply, turn)
    end;

begin
    moveStackPointer := 0
end.
