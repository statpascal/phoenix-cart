(* version 10-30-25 v1.7 *)
(* MinMax, no iterative deepening, capture evaluation bonus *)
(* fixed castling when rook has moved bug *)

(* adjustments to scorepos
   - modified the mobility bonus
   - decreased opposite check to 100
   - modified the capture bonus table
   - removed the pawn count factor for bishops
   - increased the castling bonus to 500
   - increased pawn support bonus to 20
   - reduced pawn en-passant capture penalty to 20
   - added doubled pawns penalty *)
(* cMoveFlag set only on initial ply *)
(* reset the castling obstruction flags with every turn *)
(* lastMove variable now local only *)
(* capture flags only set on topmost ply *)
(* fixed castling at ply > 2 *)
(* fixed impending mate detection *)
(* removed randomization of bestScore in MinMax *)
(* replaced bitgen with direct file load *)
(* fixed checkmate bug when attacking piece can be captured *)
(* fixed bug in the BitTrim routine *)
(* added pawn promotion piece choice for human side *)
(* fixed discovery check bug *)
(* moved Update routine to an Include file *)
(* added mating move check during move generation *)
(* reduced maximum ply to 5 *)
(* fixed bugs with the GetBoards, matecheck and matechk routines *)
(* removed move skipping when king in check during move generation *)
(* added game moves saving to SAMS card *)
(* added penalty for moving king when castling possible *)
(* fixed bug in board update after en passant capture *)
(* fixed bug in queen movement trimming *)
(* fixed back row threat detection during castling *)
(* added 3-fold repetition draw detection *)
(* added game status storage to SAMS card *)
(* fixed en-passant capture risk detection *)
(* fixed stalemate function and added the resign function *)
(* added the utility menu *)
(* fixed bug in opening move *)
(* Added rook move penalty before castling *)
(* adjusted end game conditions *)
(* added check condition evaluation to position setup *)
(* ignored moves that did not eliminate own check *)
(* 10-19-25: Fixed castling when rook not present *)
(* 10-19-25: Adjusted the resign parameters *)
(* 10-30-25: Added capture bonus in scorepos *)

unit Main;

interface

procedure chainMain;

implementation
// uses random,

uses 
    globals, move, trimprocs, ui, pmove, utility, resources;

var 
    turn, i, j, moveScore, offset, found, aVal, bVal, ans: integer;
    tempPointer: integer;
    humanFlag, checkFlag, promFlag, repFlag: boolean;
    lastMove, playMove, moveStore, tempMove: moverec;

(*
*)

procedure SaveMove;
    begin
    end;

procedure initGame (var mainBoard: TBoardRecord);
    begin
        // Randomize;	// TODO
        turn := 0;
        gameSide := turn;
        gameMove := 1;

        lastMove.id := 99;
        lastMove.startSq := 0;
        lastMove.endSq := 0;
        lastMove.link := nil;
        moveStore.id := 99;
        moveStore.startSq := 99;
        moveStore.endSq := 99;
        gamePointer := 0;

             {initialize the game storage pointers}
        write(chr(7), 'enter ply: [1-6] ');
        repeat
            ans := GetKeyInt;
        until ans in[49..54];
        writeln(chr(ans));
        gamePly := ans - 48;
//        gamePly := ply;

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
                EnterPos (mainBoard, turn);
                gameSide := turn;
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
            begin
                turn := 0;
                gameSide := turn;
            end;

        writeln;            
        write(chr(7), 'debug log to DSK0.phoenix.log (y/n)');
        repeat
            ans := GetKeyInt;
        until ans in[78, 89];
        if ans = 89 then
            begin
                doLogging := true;
                assign (logFile, 'DSK0.phoenix.log');
                rewrite (logFile)
            end;
            
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
        dummyMove, move: moverec;
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
        kingMovement := Trim (1 - gameSide, King, kingPos, playMove, board, epCapDummy);
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
                clearBit (tempBoard.blackPieces, kingPos);
            end
        else
            begin
                clearBit (tempBoard.white.kingBitboard, kingPos);
                clearBit (tempBoard.whitePieces, kingPos);
            end;
        clearBit (tempBoard.allPieces, kingPos);
        
        {check if attacking piece can be captured}
        fillChar (dummyMove, sizeof (dummyMove), 0);
        opponentMoves := combineTrimSide (gameSide = 0, dummyMove, tempBoard);
        if getBit (opponentMoves, playMove.endSq) <> 0 then
            exit;
        
        {generate trim board for attacking piece}
        bits := Trim (gameSide, playMove.id, playMove.endSq, dummyMove, tempBoard, epCapDummy); 

        {check if any opposite piece movement blocks it}
        BitAnd (bits, opponentMoves, bits);

        {update bitboards with opposite combined movement trim board}
        // TODO: could we use opponentMoves directly to block all movevemnt?
        BitOr (bits, tempBoard.allPieces, tempBoard.allPieces);
        if gameside = 0 then
            BitOr (bits, tempBoard.blackPieces, tempBoard.blackPieces)
        else
            BitOr (bits, tempBoard.whitePieces, tempBoard.whitePieces);

        {regenerate Trim board for attacking piece}
        bits := Trim (gameSide, playMove.id, playMove.endSq, dummyMove, tempBoard, epCapDummy);

        {check if overalp with opposite king}
        if getBit (bits, kingPos) = 0 then
            exit;
            
        isOpponentMate := true
end;                        
    

procedure chainMain;

    var mainBoard: TBoardRecord;

    begin
        mainBoard := getInitPosition;
        initGame (mainBoard);

     {start game}
        BoardDisplay (mainBoard);
        gotoxy(10, 1);
        writeln('move: ', gameMove);
        if gameSide = 0 then
            write('turn: white')
        else
            write('turn: black');
        if cWarning = 1 then
            begin
                gotoxy(20, 1);
                write(chr(7), chr(7), 'check!');
            end;
        ans := GetKeyInt;

        repeat
            {transfer current board state to temp boards}
            moveNumLo := 0;
            moveNumHi := 0;

            aVal := -20000;
            bVal := 20000;
            moveScore := 0;

            humanFlag := FALSE;

            if humanSide = gameSide then
                begin
                    humanFlag := TRUE;

        {save current game state}
// TODO: move to VDP                    SaveMove;

                    playerMove(mainBoard, playMove, lastMove, gameSide);
//                    if humanSide <> gameSide then
//				TODO: handle side change
                    if pieceCount = -1 then
                        exit
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
                            MoveGen (mainBoard, lastMove, playMove, moveScore, aVal, bVal, 0, gamePly, turn);
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


//            UpdateMove(playMove);
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
            if checkFlag and isOpponentMate (gameSide, mainBoard, playMove) then
                begin
                    gotoxy(20, 1);
                    write(chr(7), chr(7), 'checkmate!');
                    ans := GetKeyInt;
                    readln;
                    Utility(i);
                    exit;
                end;
            if abs(moveScore) = 20000 then
                begin
                    gotoxy(20, 1);
                    write(chr(7), chr(7), 'resign!');
                    ans := GetKeyInt;
                    readln;
                    Utility(i);
                    exit;
                end;

            if humanFlag then
                begin
                    gotoxy(20, 7);
                    write('thinking...');
                end;

            if gameSide = 0 then
                begin
                    gameSide := 1;
                    turn := 1;
                    gotoxy(0, 2);
                    write('turn: black');
                end
            else
                begin
                    gameSide := 0;
                    turn := 0;
                    gameMove := succ(gameMove);
                    gotoxy(0, 2);
                    write('turn: white');
                end;

//            check3Rep;

            gotoxy(10, 1);
            writeln('move: ', gameMove);

            MoveCoord(moveScore, playMove.startSq, playMove.endSq, humanFlag);
//            ply := gamePly;
        until FALSE;
    end;

end.
