
unit genmove;

interface

uses globals, board
{$ifdef fpc}
, math
{$endif}
;

const
    infinity = 19970;
    
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

procedure setMaxMoves (val: integer);    
procedure createAllMoves (var board: TBoardRecord; ply, turn, moveStackBegin: integer);

function generateMove (ply, turn: integer; var board: TBoardRecord): TMoveScoreRecord;
(* if no valid move can be generated, move.pieceType is set to InvalidPiece and score
   indicates the cause:
   abs (move.score) >= infinity : checkmate
   move.score = 0 : draw (stalemate)
*)


implementation

uses scorepos, trimprocs, 
{$ifdef ti99}
utility, 
{$endif}
resources, logger, bitops, openbook;

var
    maxMoves: integer;
    isDeepening: boolean;
    
procedure setMaxMoves (val: integer);
    begin
        maxMoves := val
    end;

procedure pushMoveStack (var move: TMoveRecord); overload;
    begin
        if moveStackPointer <= moveStackSize then
            begin
                moveStack [moveStackPointer] := move;
                inc (moveStackPointer)
            end
    end;
    
const
    MinPly = -5;
    
var
    valueCaptureBoard: array [Pawn..Bishop] of bitboard;
    killerMoves: array [MinPly..MaxPly, 0..1] of TMoveRecord;
    jmpbuf: jmp_buf;

procedure createAllMoves (var board: TBoardRecord; ply, turn, moveStackBegin: integer);
    const
        MaxMoves = 218;
    var 
        piece, l, pLoc, epCapSquare: integer;
        posArray: bitArray;
        currentMoveBoard, attackBoard: bitboard;
        attackMoves, moves: array [0..MaxMoves] of TMoveRecord;
        killers: array [0..1] of TMoveRecord;
        attackMoveCount, moveCount, killerMoveCount: integer;
    
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
                        killers [killerMoveCount] := move;
                        inc (killerMoveCount)
                    end
                else
                    begin
                        moves [moveCount] := move;
                        inc (moveCount)
                    end
        end;
        
    procedure createMoveNodes (attackFlag: boolean; id, startSq: integer; endSquares: bitboard);
        var
            k, piece: integer;
            move: TMoveRecord;
            moveArray: bitArray;
            
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
        var 
            castleRights: integer;
            
        procedure registerCastling (startSq, endSq: integer);
            var
                move: TMoveRecord;
            begin
                move.flags := 0;
                move.pieceType := King;
                move.startSq := startSq;
                move.endSq := endSq;
                registerMove (false, move)
            end;
            
            
        begin
            castleRights := checkCastleRights (board, turn);
            if castleRights = 0 then
                exit;
            if turn = 0 then
                begin
                    if castleRights and whiteLeftCastle <> 0 then
                        registerCastling (4, 2);
                    if castleRights and whiteRightCastle <> 0 then
                        registerCastling (4, 6)
                end
            else
                begin
                    if castleRights and blackLeftCastle <> 0 then
                        registerCastling (60, 58);
                    if castleRights and blackRightCastle <> 0 then
                        registerCastling (60, 62)
                end
        end;
        
    begin
        valueCaptureBoard [Pawn] := board.sides [1 - turn].pieces and not board.sides [1 - turn].pawnBitboard;
        valueCaptureBoard [Rook] := board.sides [1 - turn].queenBitboard;
        valueCaptureBoard [Knight] := board.sides [1 - turn].rookBitboard or board.sides [1 - turn].queenBitboard;
        valueCaptureBoard [Bishop] := valueCaptureBoard [Knight];
        
        attackMoveCount := 0;
        moveCount := 0;
        killerMoveCount := 0;
        
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
            end;
            
        move (attackMoves, moveStack [moveStackPointer], min (MoveStackSize - moveStackPointer, attackMoveCount) * sizeof (TMoveRecord));
        move (killers, moveStack [moveStackPointer + attackMoveCount], min (MoveStackSize - moveStackPointer, killerMoveCount) * sizeof (TMoveRecord));
        move (moves, moveStack [moveStackPointer + attackMoveCount + killerMoveCount], min (MoveStackSize - moveStackPointer, moveCount) * sizeof (TMoveRecord));
        inc (moveStackPointer, attackMoveCount + moveCount + killerMoveCount);
        
    end;

procedure logResult (ply, turn: integer; isPruned: boolean; var result: TMoveScoreRecord);
    begin
        indent (pred (ply)); 
        if isPruned then
            writeln (logFile, 'Pruned')
        else if result.move.pieceType <> InvalidPiece then
            begin            
                write (logFile, 'Best: '); 
                printMove (logFile, result.Move); 
                if turn = 0 then
                    writeln (logfile, ': ', result.score:6)
                else
                    writeln (logfile, ': ', -result.score:6)
            end
        else if result.score = 0 then
            writeln (logFile, 'Draw')
        else
            writeln (logFile, 'Mate')
    end;
    
function NegaMax (var board: TBoardRecord; moveScore: TMoveScore; alpha, beta, ply, turn: integer): TMoveScoreRecord;
    var 
        evalScore, savedMoveStackPointer, capId, currentMoveindex: integer;
        hasValidMove, isQuiet, isAttack, isPruned: boolean;
        workBoard: TBoardRecord;
        workMoveScore: TMoveScore;
        tempMove: TMoveRecord;
        
    begin
        savedMoveStackPointer := moveStackPointer;
        createAllMoves (board, ply, turn, savedMoveStackPointer);
        
        result.move.pieceType := InvalidPiece;
        result.score := -infinity - ply;

        hasValidMove := false;
        isPruned := false;
        currentMoveIndex := savedMoveStackPointer;
        repeat
            tempMove := moveStack [currentMoveIndex];
            inc (currentMoveIndex);
            isAttack := tempMove.flags and AttackMove <> 0;
            isQuiet := not isAttack;        // TODO: add check as condition
            workBoard := board;
            workMoveScore := moveScore;
            
            enterMove (turn, isAttack, capId, workBoard, tempMove);
            pushPositionHash (tempMove, workBoard.hash);
            
            {check if own king in check after current move}
            if not isKingChecked (turn, workBoard) then 
                begin
                    hasValidMove := true;
                    if doLogging then begin   
                        indent (pred (ply)); 
                        printMove (logFile, tempMove)
                    end;
                    
                    if isThreeFoldRepetition then
                        begin
                            evalScore := 0;
                            if doLogging then
                                writeln (logfile, ': ', 0:6, ' (3 rep)')
                        end
                    else
                        begin
                            evaluateMove (turn, board, isAttack, tempMove, capId, workMoveScore);
                            if isQuiet and (ply <= 1) or (ply = plyQS) then
                                {terminal node check - the original NegaMax does another recursive call}
                                begin
                                    evalScore := evaluatePosition (workBoard, workMoveScore);
                                    if doLogging then
                                        writeln (logFile, ': ', evalScore: 6);
                                    if turn = 1 then
                                        evalScore := -evalScore;

                                    {update number of positions evaluated}
                                    inc (moveNumLo);
                                    if (moveNumLo = 1000) then
                                        begin
                                            moveNumLo := 0;
                                            inc (moveNumHi);
                                            if isDeepening and (moveNumHi >= maxMoves) then
                                                longjmp (jmpbuf, 1)
                                        end
                                end
                            else
                                begin
                                    if doLogging then
                                        if turn = 0 then
                                            writeln (logFile, ': alpha = ', alpha, ' beta = ', beta)
                                        else
                                            writeln (logFile, ': alpha = ', -beta, ' beta = ', -alpha);
                                    evalScore := -NegaMax (workBoard, workMoveScore, -beta, -alpha, pred (ply), 1 - turn).score
                                end
                        end;

                    {alpha/beta selection}
                    if evalScore >= result.score then
                        begin
                            result.Score := evalScore;
                            result.Move := tempMove
                        end;
                    if not disableAlphaBetaPruning and (result.Score > beta) then
                        begin
                            {save killer move}
                            if not isAttack and (ply >= MinPly) and (compareByte (tempMove, killerMoves [ply, 0], sizeof (TMoveRecord)) <> 0) then
                                begin
                                    killerMoves [ply, 1] := killerMoves [ply, 0];
                                    killerMoves [ply, 0] := tempMove;
                                end;
                            isPruned := true
                        end
                    else
                        if result.Score > alpha then
                            alpha := result.Score;
                end;
                
            popPositionHash
        until isPruned or (currentMoveIndex = moveStackPointer);
        moveStackPointer := savedMoveStackPointer;
        
        if not hasValidMove and not isKingChecked (turn, board) then
            result.score := 0;
        if doLogging then 
            logResult (ply, turn, isPruned, result)
    end;
    
function generateMove (ply, turn: integer; var board: TBoardRecord): TMoveScoreRecord;
    const
        alpha = -20000;
        beta = 20000;
        pieceValue: array [Pawn..Queen] of integer = (PawnValue, RookValue, KnightValue, BishopValue, QueenValue);
    var
        moveScore: TMoveScore;
        result1: TMoveScoreRecord;
        i, totalValue, side, piece, savedHashCount: integer;
        moves: TBookMoves;
        
    begin
        moves := searchMove (board.hash);
        result.move.pieceType := InvalidPiece;
        if moves [0] <> 0 then
            begin
                i := 1;
                while (i < MaxMoves) and (moves [i] <> 0) do
                    inc (i);
                i := Random (i);
                result.score := 0;
                result.move := makeMoveRecord (board, turn, moves [i] shr 6, moves [i] and $3f)
            end;
            
        if result.move.pieceType = InvalidPiece then
            begin
                fillChar (killerMoves, sizeof (killerMoves), 0);
                fillChar (moveScore, sizeof (moveScore), 0);
                totalValue := 0;
                moveStackPointer := 0;
                
                for piece := Pawn to Queen do
                    for side := 0 to 1 do 
                        inc (totalValue, pieceValue [piece] * BitCount (board.sides [side].bitboards [piece]));
                if totalValue <= EndGameReached then
                    moveScore.flags := MoveEndGame;
        
                if doLogging then
                    printBoard (logFile, board);
                    
                moveNumLo := 0;
                moveNumHi := 0;
                isDeepening := false;
                result := NegaMax (board, moveScore, alpha, beta, ply, turn);

                if maxMoves <> 0 then
                    begin
                        isDeepening := true;
                        savedHashCount := getPositionHashCount;                
                        if setjmp (jmpbuf) = 0 then
                            repeat
                                inc (ply);
                                result1 := NegaMax (board, moveScore, alpha, beta, ply, turn);
                                // Only use if we do not break out with longjmp
                                result := result1;
                            until false;
                        setPositionHashCount (savedHashCount)
                    end
            end
    end;

begin
    maxMoves := 0;
end.
