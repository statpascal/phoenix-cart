unit Move;

interface

uses globals;

procedure MoveGen(lastMove: moverec; var finalMove: moverec;
                  var score: integer; alpha, beta: integer; cMoveFlag, ply: integer);

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


procedure printBoard;
    const 
        baseaddr: array [0..1] of integer = (WPO, BPO);
        figure: array [0..1, 0..5] of char = (('^', 'R', 'N', 'B', 'Q', 'K'),
                                              ('v', 'r', 'n', 'b', 'q', 'k'));
    var
        s: array [0..7] of string [8];
        side, piece, i, j: integer;
        bit: bitboard;
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
                    DataOps (2, BASE, 8, baseaddr [side] + 8 * piece, bit);
                    BitPos (bit, pos);
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
    end;

procedure checkBackRowInterposing;
    begin
        if (turn = 0) and (wCastleFlag = 0) then
            begin
                if (wRookRFlag = 0) and (tempBoard.allPieces [0] and $0600 <> 0) then
                    wRAFlag := 1;
                if (wRookLFlag = 0) and (tempBoard.allPieces [0] and $7000 <> 0) then
                    wLAFlag := 1
            end
        else if (turn = 1) and (bCastleFlag = 0) then
            begin
                if (bRookRFlag = 0) and (tempBoard.allPieces [3] and $0006 <> 0) then
                    bRAFlag := 1;
                if (bRookLFlag = 0) and (tempBoard.allPieces [3] and $0070 <> 0) then
                    bLAFlag := 1
            end
    end;
                
procedure checkRookMissing;
    begin
        if turn = 0 then
            begin
                if tempBoard.white.rookBitboard [0] and $8000 = 0 then
                    wLAFlag := 1;
                if tempBoard.white.rookBitboard [0] and $0100 = 0 then
                    wRAFlag := 1
            end
        else
            begin
                if tempBoard.black.rookBitboard [3] and $0080 = 0 then
                    bLAFlag := 1;
                if tempBoard.black.rookBitboard [3] and $0080 = 0 then
                    bRAFlag := 1
            end
    end;

procedure checkCastling (var moveList: listPointer);
    var currentMove: listPointer;
    begin
        if (wCastleFlag = 0) and (turn = 0) then
            begin
                if (wLAFlag = 0) and (wRookLFlag = 0) then
                    begin
                        new(currentMove);
                        currentMove^.id := 8;
                        currentMove^.startSq := 0;
                        currentMove^.endSq := 3;
                        currentMove^.link := moveList;
                        moveList := currentMove;
                        new(currentMove);
                        currentMove^.id := 40;
                        currentMove^.startSq := 4;
                        currentMove^.endSq := 2;
                        currentMove^.link := moveList;
                        moveList := currentMove;
                    end;
                if (wRAFlag = 0) and (wRookRFlag = 0) then
                    begin
                        new(currentMove);
                        currentMove^.id := 8;
                        currentMove^.startSq := 7;
                        currentMove^.endSq := 5;
                        currentMove^.link := moveList;
                        moveList := currentMove;
                        new(currentMove);
                        currentMove^.id := 40;
                        currentMove^.startSq := 4;
                        currentMove^.endSq := 6;
                        currentMove^.link := moveList;
                        moveList := currentMove;
                    end;
            end
        else
            if (bCastleFlag = 0) and (turn = 1) then
                begin
                    if (bLAFlag = 0) and (bRookLFlag = 0) then
                        begin
                            new(currentMove);
                            currentMove^.id := 8;
                            currentMove^.startSq := 56;
                            currentMove^.endSq := 59;
                            currentMove^.link := moveList;
                            moveList := currentMove;
                            new(currentMove);
                            currentMove^.id := 40;
                            currentMove^.startSq := 60;
                            currentMove^.endSq := 58;
                            currentMove^.link := moveList;
                            moveList := currentMove;
                        end;
                    if (bRAFlag = 0) and (bRookRFlag = 0) then
                        begin
                            new(currentMove);
                            currentMove^.id := 8;
                            currentMove^.startSq := 63;
                            currentMove^.endSq := 61;
                            currentMove^.link := moveList;
                            moveList := currentMove;
                            new(currentMove);
                            currentMove^.id := 40;
                            currentMove^.startSq := 60;
                            currentMove^.endSq := 62;
                            currentMove^.link := moveList;
                            moveList := currentMove;
                        end;
                end;
    end;
    
procedure checkOwnBackRowAttack (var lastmove: moveRec);
    var
        bits: bitboard;
    begin
        if (turn = 0) and (wCastleFlag = 0) and ((wRookRFlag <> 0) or (wRookLFlag <> 0)) then
            begin
                bits := combineTrimSide (true, lastmove, tempBoard);
                if bits [0] and $0f00 <> 0 then		// TODO: not correct - rook may be attacked for castling
                    wRAFlag := 1;
                if bits [0] and $f000 <> 0 then
                    wLAFlag := 1
            end
        else if (turn = 1) and (bCastleFlag = 0) and ((bRookRFlag <> 0) or (bRookLFlag <> 0)) then
            begin
                bits := combineTrimSide (false, lastmove, tempBoard);
                if bits [3] and $000f <> 0 then
                    bRAFlag := 1;
                if bits [3] and $00f0 <> 0 then
                    bLAFlag := 1
            end
    end;

procedure loopAllPieces (var board: TBoardRecord; turn: integer; var lastMove: moverec; attackIndex, tailIndex: listPointer; ply: integer);
    var 
        j, l, n, pLoc, epCapFlag: integer;
        posArray, moveArray: bitArray;
        currentMoveBoard, attackBoard, bit8, bit9: bitboard;
        
    procedure createMoveNodes (var list: listPointer; id, startSq: integer; var endSquares: bitboard);
        var
            k: integer;
            moveArray: bitArray;
        begin
            BitPos (endSquares, moveArray);
            for k := 1 to moveArray [0] do
                begin
                    new (list^.link);
                    list^.id := id;
                    list^.startSq := startSq;
                    list^.endSq := moveArray [k];
                    list := list^.link;
                    list^.link := nil
                end
        end;
        
    begin
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
                            CombineTrim(bit3, bit5, lastMove, mainBoard);
                            
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
        until j > 40
    end;
    
function isKingChecked (lastMove: moverec): boolean;
    begin
        CombineTrim(bit3, bit5, lastMove, tempBoard);
        
        {check if own king attacked by opposite trim board}
        if turn = 0 then
            bit1 := tempBoard.white.kingBitboard
        else
            bit1 := tempBoard.black.kingBitboard;
        
        if turn = 0 then
            BitAnd(bit1, bit5, bit1)
        else
            BitAnd(bit1, bit3, bit1);
        isKingChecked := not isClear (bit1)
    end;
    
    
procedure enterMove (turn, attackFlag: integer; var attackId, capId: integer; var foundFlag: boolean; var board: TBoardRecord; currentmove: ^moverec);
        
    procedure updateBitboards (var own, opponent: TSideRecord; var ownPieces, opponentPieces: bitboard);
        var
            epSquare: integer;
            i, j: integer;
        begin
            {erase piece at starting position}
            clearBit (board.allPieces, currentMove^.startSq);
            clearBit (ownPieces, currentMove^.startSq);
            clearBit (own.bitboards [currentMove^.id shr 3], currentMove^.startSq);

            {remove attacked piece from opponent's bitboards}
            if attackFlag = 1 then
                begin
                    j := 0;
                    repeat
                        if getBit (opponent.bitboards [j shr 3], currentMove^.endSq) <> 0 then
                            begin
                                foundFlag := true;
                                attackId := currentMove^.id;
                                capId := j;
                                clearBit (opponent.bitboards [j shr 3], currentMove^.endSq);
                                clearBit (opponentPieces, currentMove^.endSq)
                            end;
                        j := j + 8;
                    until (foundFlag) or (j > 40);

                    {en passant capture handling}
                    if not foundFlag and (currentMove^.id = 0) and (abs (currentMove^.startSq - currentMove^.endSq) in [7, 9]) then
                        begin
                            if turn = 0 then
                                epSquare := currentMove^.endSq - 8
                            else
                                epSquare := currentMove^.endSq + 8;
                            clearBit (opponent.pawnBitboard, epSquare);
                            clearBit (opponentPieces, epSquare);
                            clearBit (board.allPieces, epSquare);
                        end
                end;

            {place piece at ending position}
            setBit (board.allPieces, currentMove^.endSq);
            setBit (ownPieces, currentMove^.endSq);
            if (currentMove^.id = 0) and (currentMove^.endSq in [0..7, 56..63]) then
                setBit (own.queenBitboard, currentMove^.endSq)
            else
                setBit (own.bitboards [currentMove^.id shr 3], currentMove^.endSq)
        end;
    
    begin
        if turn = 0 then
            updateBitboards (board.white, board.black, board.whitePieces, board.blackPieces)
        else
            updateBitboards (board.black, board.white, board.blackPieces, board.whitePieces)
    end;    
    
procedure MoveGen(lastMove: moverec; var finalMove: moverec; var score: integer; alpha, beta: integer; cMoveFlag, ply: integer);
    var 
        i, j, k, attackId, capId, bestScore: integer;
        wCheckFlag, bCheckFlag, switchFlag: integer;
        attackFlag, evalScore: integer;
        mateFlag: integer;
        foundFlag, pruneFlag, ignoreMove: boolean;
        bestMove, tempMove: moverec;
        moveList, attackList, tailIndex, attackIndex, currentMove: listPointer;
        savedBoard: TBoardRecord;
        heap: pointer;

    begin
        mark (heap);

        if doLogging then begin
            if ply = gamePly then
                begin
                    printBoard;
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

        loopAllPieces (tempBoard, turn, lastMove, attackIndex, tailIndex, ply);

        checkBackRowInterposing;
        checkOwnBackRowAttack (lastMove);
        checkRookMissing;
        checkCastling (moveList);

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

        {save bitboards}
        savedBoard := tempBoard;

        repeat
            foundFlag := false;
            tempMove := currentMove^;
            enterMove (turn, attackFlag, attackId, capId, foundFlag, tempBoard, currentMove);
            
            {check for castling move}
            if (attackFlag = 0) and (currentMove^.id = 40) then
                begin
                    if abs(currentMove^.startSq - currentMove^.endSq) = 2 then
                        begin
                            if ply = gamePly then
                                cMoveFlag := 1;
                            currentMove := currentMove^.link;
                            enterMove (turn, attackFlag, attackId, capId, foundFlag, tempBoard, currentMove);
                        end;
                end;

            {check if own king in check after current move}
//            if (cWarning = 1) and (ply = gamePly) then
            ignoreMove := isKingChecked (lastMove);

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
                            evalScore := Evaluate (cMoveFlag, attackFlag, attackId, capId, lastMove, tempMove, tempBoard);
                            if doLogging then begin   
                                indent (ply - 1); 
                                printMove (tempMove); 
                                writeln (logFile, ': ', evalScore: 6)
                            end
                        end
                    else
                        begin
                            turn := 1 - turn;
                            MoveGen (tempMove, finalMove, evalScore, alpha, beta, cMoveFlag, pred (ply));
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

            {restore the previous ply base bitboard}
            tempBoard := savedBoard;

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
        turn := 1 - turn;
        release (heap)
    end;

end.
