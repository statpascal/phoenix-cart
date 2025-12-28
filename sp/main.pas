unit Main;

interface

procedure chainMain;

implementation
// uses random,

uses 
    globals, move, trimprocs, ui, pmove, utility, resources, fen,  logger;

var 
    i, j, moveScore, aVal, bVal: integer;
    lastMove, playMove: moverec;


procedure SaveMove;
    begin
    end;

procedure initGame (var mainBoard: TBoardRecord);
    var
        ans: integer;
    begin
        // Randomize;	// TODO
        pieceCount := 0;
//        gameSide := 0;
//        gameMove := 1;

        lastMove.id := InvalidPiece;
        lastMove.startSq := 0;
        lastMove.endSq := 0;

        write(chr(7), 'enter ply: [1-6] ');
        repeat
            ans := GetKeyInt;
        until ans in[49..54];
        writeln(chr(ans));
        gamePly := ans - 48;

        writeln(chr(7), 'select side to play: [w]hite/[b]lack');
        repeat
            ans := GetKeyInt;
        until ans in[66, 87];
        if ans = 66 then
            begin
                humanSide := 1;
                writeln('***playing as black***');
            end
        else
            begin
                humanSide := 0;
                writeln('***playing as white***');
            end;
            
        cWarning := 0;
        write(chr(7), 'enter position? (y/n)');
        repeat
            ans := GetKeyInt;
        until ans in[78, 89];
        if ans = 89 then
            begin
                EnterPos (mainBoard, gameside);
//                gameSide := turn;	<->
               {look for check condition}
               
(* TODO: check cehck               
                lastMove.id := 0;
                lastMove.startSq := 0;
                lastMove.endSq := 0;
                CombineTrim(bit3, bit5, lastMove, mainBoard);
                if gameSide = 0 then
                    offset := WKO
                else
                    offset := BKO;
                DataOps(2, startPage, dataSize, offset, bit1);
                if gameSide = 0 then
                    BitAnd(bit1, bit5, bit2)
                else
                    BitAnd(bit1, bit3, bit2);
                if not(IsClear(bit2)) then
                    cWarning := 1;
*)                    
            end
        else
            gameSide := 0;	// turn := gameside

        writeln;            
        write(chr(7), 'debug log to DSK0.phoenix.log (y/n)');
        repeat
            ans := GetKeyInt;
        until ans in[78, 89];
        if ans = 89 then
            startLogging ('DSK0.phoenix.log');
            
        writeln;
        write ('QS deepening (0-9/u)');
        repeat
            ans := getKeyInt
        until ans in [48..57, 85];
        if ans = 85 then 
            plyQS := -Maxint
        else 
            plyQS := 1 - (ans - 48)
    end;


(*

procedure check3Rep;
    begin
            {check for 3-move repetition}
        if gameMove > 6 then
            begin
                repFlag := TRUE;
                sPage := BASE2;
                tempPointer := gamePointer;
                for i := 1 to 3 do
                    begin
                        tempPointer := tempPointer - 8;
                        offset := PLAYLIST + tempPointer;
                        DataOps(2, sPage, dataSize, offset, moveStore);
                        offset := PLAYLIST + tempPointer - 32;
                        DataOps(2, sPage, dataSize, offset, tempMove);
                        // TODO: 
                        //      if moveStore <> tempMove then
                        if not compareWord (moveStore, tempMove, 4) then
                            repFlag := FALSE;
                        offset := PLAYLIST + tempPointer - 64;
                        DataOps(2, sPage, dataSize, offset, tempMove);
                        // TODO
                        //      if moveStore <> tempMove then
                        if not compareWord (moveStore, tempMove, 4) then
                            repFlag := FALSE;
                    end;
                if repFlag then
               {3x repetition. Draw}
                    begin
                        gotoxy(20, 0);
                        write(chr(7), chr(7), 'draw by 3-fold repetition!');
                        ans := GetKeyInt;
                        readln;
                        Utility(i);
                        exit;
                    end;
            end;
    end;
    
*)    
    
    
function isOpponentMate (gameSide: integer; var board: TBoardRecord; playMove: moverec): boolean;
    var
        moveArray: bitarray;
        bits, kingMovement, opponentMoves: bitboard;
        kingPos, epCapDummy: integer;
        move: moverec;
        tempBoard: TBoardRecord;
    begin
        isOpponentMate := false;
        
        {get opposite king position}
        if gameSide = 0 then
            BitPos (board.black.kingBitboard, moveArray)
        else
            BitPos (board.white.kingBitboard, moveArray);
        kingPos := moveArray [1];

        {obtain list of all possible opposite king movement}
        kingMovement := Trim (1 - gameSide, King, kingPos, board, epCapDummy);
        BitPos (kingMovement, moveArray);
        
        move.id := King;
        move.startSq := kingPos;
        for i := 1 to moveArray [0] do
            begin
                tempBoard := board;
                move.endSq := moveArray [i];
                enterMoveSimple (1 - gameSide, tempBoard, move);
                if not isKingChecked (1 - gameSide, tempBoard) then
                    exit
            end;

        {remove opposite king from all opposite boards}
        tempBoard := board;
        if gameSide = 0 then
            begin
                clearBit (tempBoard.black.kingBitboard, kingPos);
                clearBit (tempBoard.black.pieces, kingPos);
            end
        else
            begin
                clearBit (tempBoard.white.kingBitboard, kingPos);
                clearBit (tempBoard.white.pieces, kingPos);
            end;
        clearBit (tempBoard.allPieces, kingPos);
        
        {check if attacking piece can be captured}
        opponentMoves := combineTrimSide (gameSide = 0, tempBoard);
        if getBit (opponentMoves, playMove.endSq) <> 0 then
            exit;
        
        {generate trim board for attacking piece}
        bits := Trim (gameSide, playMove.id, playMove.endSq, tempBoard, epCapDummy); 

        {check if any opposite piece movement blocks it}
        BitAnd (bits, opponentMoves, bits);

        {update bitboards with opposite combined movement trim board}
        // TODO: could we use opponentMoves directly to block all movevemnt?
        BitOr (bits, tempBoard.allPieces, tempBoard.allPieces);
        if gameside = 0 then
            BitOr (bits, tempBoard.black.pieces, tempBoard.black.pieces)
        else
            BitOr (bits, tempBoard.white.pieces, tempBoard.white.pieces);

        {regenerate Trim board for attacking piece}
        bits := Trim (gameSide, playMove.id, playMove.endSq, tempBoard, epCapDummy);

        {check if overalp with opposite king}
        if getBit (bits, kingPos) = 0 then
            exit;
            
        isOpponentMate := true
end;                        
    

procedure chainMain;

    var mainBoard: TBoardRecord;
        checkFlag: boolean;

    begin
//        mainBoard := getInitPosition;
        setFENPosition (mainBoard, gameSide, gameMove, 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
        initGame (mainBoard);

     {start game}
        BoardDisplay (mainBoard);
        if cWarning = 1 then
            begin
                gotoxy(20, 1);
                write(chr(7), chr(7), 'check!');
            end;

        repeat
        
            gotoxy(10, 1);
            writeln('move: ', gameMove);
            if gameSide = 0 then
                write('turn: white')
            else
                write('turn: black');
        
            moveNumLo := 0;
            moveNumHi := 0;

            aVal := -20000;
            bVal := 20000;
            moveScore := 0;


            if humanSide = gameSide then
                begin

        {save current game state}
// TODO: move to VDP                    SaveMove;

                    playerMove (mainBoard, playMove, gameSide);
//                    if humanSide <> gameSide then
//				TODO: handle side change
                    if pieceCount = -1 then
                        begin
                            writeln;
                            writeln ('pieceCount = -11, exiting');
                            exit
                        end
                end
            else
                begin
                    {opening move selection}
                    if gameMove = 1 then
                        begin
                            moveScore := 0;
                            //      i := Rnd_Int(3);		TODO
                            i := 2;
                            if gameSide = 0 then
                                begin
                                    case i of 
                                        1: 
                                        begin
                                            playMove.id := 0;
                                            playMove.startSq := 12;
                                            playMove.endSq := 28;
                                        end;
                                        2: 
                                        begin
                                            playMove.id := 0;
                                            playMove.startSq := 11;
                                            playMove.endSq := 27;
                                        end;
                                        3: 
                                        begin
                                            playMove.id := 16;
                                            playMove.startSq := 6;
                                            playMove.endSq := 21;
                                        end;
                                    end;
                                end
                            else
                                begin
                                    case lastMove.endSq of 
                                        12: 
                                        begin
                                            playMove.id := 0;
                                            case i of 
                                                1: 
                                                begin
                                                    playMove.startSq := 52;
                                                    playMove.endSq := 44;
                                                end;
                                                2: 
                                                begin
                                                    playMove.startSq := 51;
                                                    playMove.endSq := 43;
                                                end;
                                                3: 
                                                begin
                                                    playMove.startSq := 51;
                                                    playMove.endSq := 35;
                                                end;
                                            end;
                                        end;
                                        11,21: 
                                        begin
                                            case i of 
                                                1: 
                                                begin
                                                    playMove.id := 0;
                                                    playMove.startSq := 51;
                                                    playMove.endSq := 35;
                                                end;
                                                2: 
                                                begin
                                                    playMove.id := 16;
                                                    playMove.startSq := 62;
                                                    playMove.endSq := 45;
                                                end;
                                                3: 
                                                begin
                                                    playMove.id := 0;
                                                    playMove.startSq := 50;
                                                    playMove.endSq := 34
                                                end;
                                            end;
                                        end;
                                    end;
                                    if not(lastMove.endSq in [11, 12, 21]) then
                                        begin
                                            playMove.id := 0;
                                            playMove.startSq := 51;
                                            playMove.endSq := 35;
                                        end;
                                end;
                        end
                    else
                        begin
                            gotoxy(20, 7);
                            write('thinking...');
                            MoveGen (mainBoard, lastMove, playMove, moveScore, 0, aVal, bVal, gamePly, gameSide);
                        end;
                end;

            {update move list}
(*            
        TODO: save move history
            sPage := BASE2;
            dataSize := 8;
            offset := PLAYLIST + gamePointer;
            DataOps(1, sPage, dataSize, offset, playMove);
            gamePointer := gamePointer + 8;
            moveStore.id := 99;
            offset := offset + 8;
            DataOps(1, sPage, dataSize, offset, moveStore);
*)            

            lastMove := playMove;
            enterMoveSimple (gameSide, mainBoard, playMove);

            {convert move to coordinates}
            BoardDisplay (mainBoard);

            {look for check condition}
            checkFlag := isKingChecked (1 - gameSide, mainBoard);
            if checkFlag then
                begin
                    gotoxy(20, 1);
                    write(chr(7), chr(7), 'check!');
                    cWarning := 1;
                end;

            {look for checkmate or stalemate condition}
            if checkFlag then
                if isOpponentMate (gameSide, mainBoard, playMove) then
                    begin
                        gotoxy(20, 1);
                        write(chr(7), chr(7), 'checkmate!');
                        readln;
                        Utility(i);
                        exit;
                    end
                else if abs(moveScore) = 20000 then
                    begin
                        gotoxy(20, 1);
                        write(chr(7), chr(7), 'resign!');
                        readln;
                        Utility(i);
                        exit;
                    end;
                
            inc (gameMove, gameSide);	// add 1 if black
            showMove (moveScore, playMove.startSq, playMove.endSq, gameSide = humanSide);
            gameSide := 1 - gameSide;

//            check3Rep;

        until FALSE;
    end;

end.
