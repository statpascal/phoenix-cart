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
    
procedure setMaxMoves (val: integer);    

function generateMove (ply: integer; var board: TBoardRecord): TMoveScoreRecord;
(* if no valid move can be generated, move.pieceType is set to InvalidPiece and score
   indicates the cause:
   abs (move.score) >= infinity : checkmate
   move.score = 0 : draw (stalemate)
*)

function isMovingSideMate (var board: TBoardRecord): boolean;


implementation

uses scorepos, trimprocs, dtmtables,
{$ifdef ti99}
utility, 
{$endif}
resources, logger, bitops, openbook;

var
{$ifdef ti99}
    moveStack: array [0..MoveStackSize] of TMoveRecord absolute $2000;
{$endif}
{$ifdef fpc}
    moveStack: array [0..MoveStackSize] of TMoveRecord;
{$endif}
    moveStackPointer: integer;
    isDeepening: boolean;

procedure setMaxMoves (val: integer);
    begin
        limitMovesHi := val;
        limitMovesLo := 0;
        deepenFactor := 0
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
    killerMoves: array [MinPly..MaxPly, 0..1] of TMoveRecord;
    jmpbuf: jmp_buf;

procedure createAllMoves (var board: TBoardRecord; ply, turn, moveStackBegin: integer);
    const
        MaxMoves = 218;
        MaxCaptures = 65;
        
    type
        TAttackRecord = record
            move: TMoveRecord;
            score: integer
        end;
        
    var 
        piece, l, pLoc, epCapSquare: integer;
        posArray: bitArray;
        currentMoveBoard, attackBoard: bitboard;
        attackMoves: array [0..MaxCaptures] of TAttackRecord;
        moves: array [0..MaxMoves] of TMoveRecord;
        killers: array [0..1] of TMoveRecord;
        attackMoveCount, moveCount, killerMoveCount: integer;
        
    procedure sortAttackMoves (count: integer);
        var
            mScore, i, j: integer;
            h: TAttackRecord;
        begin
            for i := 0 to pred (count) do
                begin
                    mScore := i;
                    for j := succ (i) to count do
                        if attackMoves [j].score > attackMoves [mScore].score then
                            mScore := j;
                    if mScore <> i then
                        begin
                            h := attackMoves [i];
                            attackMoves [i] := attackMoves [mScore];
                            attackMoves [mScore] := h
                        end
                end
        end;
    
    procedure registerMove (attackFlag: boolean; var move: TMoveRecord);
        var
            attackedPiece: integer;
        const
            pieceScore: array [Pawn..InvalidPiece] of integer = (PawnValue, RookValue, KnightValue, BishopValue, QueenValue, KingValue, PawnValue);
        begin
            if attackFlag then
                begin
                    attackMoves [attackMoveCount].move := move;
                    attackedPiece := findPieceType (board, 1 - turn, move.endSq);
                    { returns InvalidPiece if EP capture }
                    attackMoves [attackMoveCount].score := 16 * pieceScore [attackedPiece] - pieceScore [move.pieceType];
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
            
        if attackMoveCount > 1 then

            sortAttackMoves (pred (attackMoveCount));
        for l := 0 to pred (attackMoveCount) do
            moveStack [moveStackPointer + l] := attackMoves [l].move;
        move (killers, moveStack [moveStackPointer + attackMoveCount], min (MoveStackSize - moveStackPointer, killerMoveCount) * sizeof (TMoveRecord));
        move (moves, moveStack [moveStackPointer + attackMoveCount + killerMoveCount], min (MoveStackSize - moveStackPointer, moveCount) * sizeof (TMoveRecord));
        inc (moveStackPointer, attackMoveCount + moveCount + killerMoveCount)
    end;
    
function searchDTM (var board: TBoardRecord; turn, pieceType: integer): TMoveRecord;
    var
        strongKing, weakKing, piece, best, i, dtm: integer;
        workBoard: TBoardRecord;        
        
    begin
        moveStackPointer := 0;
        createAllMoves (board, gamePly, turn, 0);
        weakKing := BitPosition (board.sides [1 - turn].kingBitboard);
        best := 1000;
        result.pieceType := InvalidPiece;	// indicate draw
        
        for i := 0 to pred (moveStackPointer) do
            begin
                workBoard := board;
                enterMoveSimple (workBoard, moveStack [i]);
                strongKing := BitPosition (workboard.sides [turn].kingBitboard);
                piece := BitPosition (workboard.sides [turn].bitboards [pieceType]);
                if pieceType = Queen then
                    dtm := getDtmKqk (strongKing, weakKing, piece)
                else
                    dtm := getDtmKrk (strongKing, weakKing, piece);
                
//                printMove (logFile, moveStack [i]);
//                writeln (logFile, ', DTM: ', dtm);
                
                if dtm < best then 
                    begin
                        result := moveStack [i];
                        best := dtm
                    end
            end
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
    
function hasNonPawnMaterial (var board: TBoardRecord; turn: integer): boolean;
    begin
        hasNonPawnMaterial :=
            not IsClear (board.sides [turn].knightBitboard) or
            not IsClear (board.sides [turn].bishopBitboard) or
            not IsClear (board.sides [turn].rookBitboard)   or
            not IsClear (board.sides [turn].queenBitboard)
    end;     
    
function NegaMax (var board: TBoardRecord; moveScore: TMoveScore; alpha, beta, ply, turn: integer): TMoveScoreRecord;
    const 
        NullReduction = 2;
    var 
        evalScore, savedMoveStackPointer, capId, currentMoveindex: integer;
        hasValidMove, isQuiet, isAttack, isPruned: boolean;
        workBoard: TBoardRecord;
        workMoveScore: TMoveScore;
        tempMove: TMoveRecord;
        
    begin
        { --- null-move pruning --- }
        if not disableAlphaBetaPruning
          and (beta < infinity)
          and (pred (ply) - NullReduction > plyQS)                 { keep reduced depth above qsearch (R = 2) }
          and not isKingChecked (turn, board)
          and hasNonPawnMaterial (board, turn) then     { zugzwang guard }
            begin
                workBoard := board;
                toggleMoveFlag (workBoard);
                if doLogging then
                    begin
                        indent (pred (ply));
                        writeln (logFile, 'Check null move')
                        { TODO: log viewer needs to handle multiple ident levels }
                    end; 
                evalScore := -NegaMax (workBoard, moveScore, -beta, -beta + 1, ply - 1 - NullReduction, 1 - turn).score;
                if evalScore >= beta then
                    begin
                        result.score := beta;
                        result.move.pieceType := InvalidPiece;
                        if doLogging then 
                            logResult (ply, turn, true, result);
                        exit
                    end;
                if doLogging then
                    begin
                        indent (pred (ply));
                        writeln (logFile, 'No pruning')
                    end
            end;         

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
            workBoard := board;
            workMoveScore := moveScore;

            isAttack := tempMove.flags and AttackMove <> 0;
            
            enterMove (turn, isAttack, capId, workBoard, tempMove);
            pushPositionHash (tempMove, workBoard.hash);
            
            {check if own king in check after current move}
            if not isKingChecked (turn, workBoard) then 
                begin
                    isQuiet := not isAttack and (tempMove.flags = 0) and not isKingChecked (1 - turn, workBoard);
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
                            evaluateMove (turn, board, isAttack, tempMove, ply, capId, workMoveScore);
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
                                        end;
                                    if isDeepening and (moveNumHi = limitMovesHi) and (moveNumLo = limitMovesLo)  then
                                        longjmp (jmpbuf, 1)
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
                    if evalScore > result.score then
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
    
function generateMove (ply: integer; var board: TBoardRecord): TMoveScoreRecord;
    const
        alpha = -20000;
        beta = 20000;
        pieceValue: array [Pawn..Queen] of integer = (PawnValue, RookValue, KnightValue, BishopValue, QueenValue);
    var
        moveScore: TMoveScore;
        result1: TMoveScoreRecord;
        sel, weights, i, totalValue, turn, side, piece, savedHashCount, movesHi, movesLo: integer;
        moves: TBookMoves;
        
    begin
        turn := ord (board.flags and moveBlackFlag <> 0);
        moveNumLo := 0;
        moveNumHi := 0;
       
        if (BitCount (board.allPieces) = 3) then
            if not isClear (board.sides [turn].queenBitboard) then
                begin
                    result.score := 0;
                    result.move := searchDTM (board, turn, Queen);
                    exit
                end
            else if not isClear (board.sides [turn].rookBitboard) then
                begin
                    result.score := 0;
                    result.move := searchDTM (board, turn, Rook);
                    exit
                end;
        
        moves := searchMove (board.hash);
        result.move.pieceType := InvalidPiece;
        if moves [0] <> 0 then
            begin
                i := 0;
                weights := 0;
                while (i < MaxMoves) and (moves [i] <> 0) do
                    begin
                        inc (weights, (moves [i] shr 12) and $0f);
                        inc (i)
                    end;
                sel := Random (weights);
//                gotoxy (0, 0); write ('sel: ', sel, ', total: ', weights, ' ');
                i := 0;
                weights := (moves [i] shr 12) and $0f;
                while weights <= sel do
                    begin
                        inc (i);
                        inc (weights, (moves [i] shr 12) and $0f);
                    end;
                result.score := 0;
                result.move := makeMoveRecord (board, moves [i] shr 6 and $3f, moves [i] and $3f)
            end;
            
            
        if result.move.pieceType = InvalidPiece then
            begin
                fillChar (killerMoves, sizeof (killerMoves), 0);
                fillChar (moveScore, sizeof (moveScore), 0);
                totalValue := 0;
                moveStackPointer := 0;
                
                if isClear (board.white.rookBitboard) and isClear (board.black.rookBitboard) then
                    begin
                        for piece := Rook to Queen do
                            for side := 0 to 1 do 
                                inc (totalValue, pieceValue [piece] * BitCount (board.sides [side].bitboards [piece]));
                        if totalValue <= EndGameReached then
                            moveScore.flags := MoveEndGame
                    end;
        
                if doLogging then
                    printBoard (logFile, board);
                    
                isDeepening := false;
                result := NegaMax (board, moveScore, alpha, beta, ply, turn);
                
                movesHi := deepenFactor * moveNumHi + deepenFactor * moveNumLo div 1000;
                movesLo := deepenFactor * moveNumLo mod 1000;
                
                if movesHi > limitMovesHi then
                    limitMovesHi := movesHi;
                if (movesHi = limitMovesHi) and (movesLo > limitMovesLo) then
                    limitMovesLo := movesLo;
                
                if (moveNumHi < limitMovesHi) or
                   (moveNumHi = limitMovesHi) and (moveNumLo < limitMovesLo) then
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
                    end;
                if turn = 1 then
                    result.score := -result.score
            end
    end;
    
function isMovingSideMate (var board: TBoardRecord): boolean;
    var
        tempBoard: TBoardRecord;
        turn: integer;
    begin
        result := true;
        turn := ord (board.flags and moveBlackFlag <> 0);
        moveStackPointer := 0;
        createAllMoves (board, 1, turn, 0);
        while result and (moveStackPointer > 0) do
            begin
                tempBoard := board;
                dec (moveStackPointer);
                enterMoveSimple (tempBoard, moveStack [moveStackPointer]);
                result := isKingChecked (turn, tempBoard)
            end
    end;
    
end.
