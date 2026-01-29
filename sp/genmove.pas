unit genmove;

interface

uses globals, board
{$ifdef fpc}
, math
{$endif}
;

procedure generateMove (ply, turn: integer; var board: TBoardRecord; var move: TMoveRecord; var score: integer); 

implementation

uses scorepos, trimprocs, 
{$ifdef ti99}
utility, 
{$endif}
resources, logger, bitops, openbook;

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
    
procedure MoveGen (var board: TBoardRecord; var finalMove: TMoveRecord;
                   var score: integer; moveScore: TMoveScore; alpha, beta, ply, turn: integer); forward;
                   
function iterateMoveList (var board: TBoardRecord; turn, ply, startIndex, endIndex: integer; moveScore: TMoveScore; alpha, beta: integer; var validMoveCount, bestScore: integer; var bestMove: TMoveRecord): boolean;
    var
        attackMoves: boolean;
        capId, currentMoveindex: integer;
        evalScore, evalMove: integer;
        resultMove, tempMove: TMoveRecord;
        workBoard: TBoardRecord;
        workMoveScore: TMoveScore;
    begin
        iterateMoveList := true;
        for currentMoveIndex := startIndex to endIndex do
            begin
                tempMove := moveStack [currentMoveIndex];
                attackMoves := boolean (tempMove.flags and AttackMove);
                workBoard := board;
                workMoveScore := moveScore;
                enterMove (turn, ord (AttackMoves), capId, workBoard, tempMove);
                
                {check if own king in check after current move}
                if not isKingChecked (turn, workBoard) then 
                    begin
                        evaluateMove (turn, board, attackMoves, tempMove, capId, workMoveScore);
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
                                evalScore := EvaluatePosition (turn, workBoard, workMoveScore);
                                if doLogging then begin   
                                    indent (pred (ply)); 
                                    printMove (logFile, tempMove); 
                                    writeln (logFile, ': ', evalScore: 6)
                                end
                            end
                        else
                            begin
                                if doLogging then
                                    begin
                                        indent (pred (ply));
                                        printMove (logFile, tempmove); 
                                        writeln (logFile, ': alpha = ', alpha, ' beta = ', beta)
                                    end;
                                MoveGen (workBoard, resultMove, evalScore, workMoveScore, alpha, beta, pred (ply), 1 - turn);
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
            end;
        iterateMoveList := false
    end;
    
procedure MoveGen (var board: TBoardRecord; var finalMove: TMoveRecord;
                   var score: integer; moveScore: TMoveScore; alpha, beta, ply, turn: integer);
    var 
        bestScore, validMoveCount: integer;
        switchFlag: integer;
        bestMove: TMoveRecord;
        savedMoveStackPointer: integer;
        pruned: boolean;
    begin
        savedMoveStackPointer := moveStackPointer;
        loopAllPieces (board, ply, turn, savedMoveStackPointer);
        bestMove.pieceType := InvalidPiece;

        if turn = 0 then
            bestScore := -19970 - ply
        else
            bestScore := 19970 + ply;

        validMoveCount := 0;
        pruned := iterateMoveList (board, turn, ply, savedMoveStackPointer, pred (moveStackPointer), moveScore, alpha, beta, validMoveCount,  bestScore, bestMove);

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
        pieceValue: array [Pawn..Queen] of integer = (PawnValue, RookValue, KnightValue, BishopValue, QueenValue);
    var
        moveScore: TMoveScore;
        i, totalValue: integer;
        side, piece: integer;
        moves: TBookMoves;
        compressedBoard: TCompressedBoard;
        
    begin
        compressBoard (board, compressedBoard);
        if turn = 1 then
{$ifdef ti99}
            compressedBoard.flags := compressedBoard.flags or moveBlackFlag;
{$endif}            
{$ifdef fpc}
            compressedBoard.flags := compressedBoard.flags or swapEndian (uint16 (moveBlackFlag));
{$endif}            
        moves := searchMove (compressedBoard);
        if moves [0] <> 0 then
            begin
                i := 1;
                while (i < MaxMoves) and (moves [i] <> 0) do
                    inc (i);
                i := Random (i);
                move.startSq := moves [i] shr 6;
                move.endSq := moves [i] and $3f;
                move.pieceType := findPieceType (board, turn, move.startSq)
            end
        else
            begin
                fillChar (killerMoves, sizeof (killerMoves), 0);
                fillChar (moveScore, sizeof (moveScore), 0);
                totalValue := 0;
                for piece := Pawn to Queen do
                    for side := 0 to 1 do 
                        inc (totalValue, pieceValue [piece] * BitCount (board.sides [side].bitboards [piece]));
                if totalValue <= EndGameReached then
                    moveScore.flags := MoveEndGame;
        
                if doLogging then
                    printBoard (logFile, board);
                MoveGen (board, move, score, moveScore, alpha, beta, ply, turn)
            end
    end;

begin
    moveStackPointer := 0
end.
