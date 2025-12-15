unit Move;

interface

uses globals;

procedure MoveGen (var board: TBoardRecord; lastMove: moverec; var finalMove: moverec;
                   var score: integer; alpha, beta: integer; cMoveFlag, ply, turn: integer);


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

procedure loopAllPieces (var board: TBoardRecord; turn: integer; var lastMove: moverec);
    var 
        j, l, n, pLoc, epCapFlag: integer;
        posArray, moveArray: bitArray;
        currentMoveBoard, attackBoard, bits: bitboard;
        
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
                                bits := getMovementBitboard (WhitePawnCapture, pLoc)
                            else
                                bits := getMovementBitboard (BlackPawnCapture, pLoc);
                            BitAnd(currentMoveBoard, bits, bits);
                            BitOr(attackBoard, bits, attackBoard);
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
                                // TODO: do not set castle flags for decision tree
                                workBoard.castleFlags := board.castleFlags;
                                
                                // alternative: activate QS if any capturing move is possbible
//                                if attackMoves then
//                                    haveAttackMove := true;
                                haveAttackMove := foundFlag;
                                
                                {check for castling move}
                                if (tempMove.id = King) and (ply = gamePly) and (abs (tempMove.startSq - tempMove.endSq) = 2) then
                                    cMoveFlag := 1;

                                {check if own king in check after current move}
                                if not isKingChecked (turn, workBoard) then 
                                    begin
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
                                                evalScore := Evaluate (cMoveFlag, ord (attackFlag), attackId, capId, lastMove, tempMove, workBoard, turn);
                                                if doLogging then begin   
                                                    indent (ply - 1); 
                                                    printMove (logFile, tempMove); 
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
            printMove (logFile, finalMove); 
            writeln (logfile, ': ', score:6)
        end;

        moveStackPointer := savedMoveStackPointer;
    end;

begin
    moveStackPointer := 0
end.
