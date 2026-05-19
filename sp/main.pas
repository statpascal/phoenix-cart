
unit Main;

interface

procedure chainMain;

implementation
// uses random,

uses 
    globals, genmove, trimprocs, ui, pmove, utility, resources, logger;

var 
    cWarning, humanSide: integer;


procedure SaveMove;
    begin
    end;
    
procedure showMessage (s: string);
    begin
        // TODO: beep
        showHChar (18, 4, 32, 14);
        gotoxy (18, 4);
        write (s)
    end;

procedure initGame (var mainBoard: TBoardRecord);
    var
        ans: integer;
    begin
        writeln;
        write(chr(7), 'Enter ply: [1-6] ');
        repeat
            ans := GetKeyInt;
        until ans in[49..54];
        writeln(chr(ans));
        gamePly := ans - 48;

        writeln(chr(7), 'Select side: [w]hite/[b]lack');
        repeat
            ans := GetKeyInt;
        until ans in[66, 87];
        if ans = 66 then
            begin
                humanSide := 1;
                writeln('Playing as black');
            end
        else
            begin
                humanSide := 0;
                writeln('Playing as white');
            end;
            
        cWarning := 0;
        write(chr(7), 'Enter position? (y/n)');
        repeat
            ans := GetKeyInt;
        until ans in[78, 89];
        if ans = 89 then
            begin
                EnterPos (mainBoard);
(* TODO: check cehck               
                    cWarning := 1;
*)                    
            end;

        writeln;            
        write(chr(7), 'Log to DSK0.phoenix.log (y/n)');
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

procedure chainMain;
    var mainBoard: TBoardRecord;
        compressedBoard: TCompressedBoard;
        checkFlag, isHumanMove: boolean;
        playMove: TMoveScoreRecord;
        dummy: integer;

    begin
        setInitPosition (mainboard);
        initGame (mainBoard);

        {start game}
        NewBoard;
        BoardDisplay (mainBoard);
        showMessage ('');
        
        if cWarning = 1 then
            showMessage ('check!');

        repeat
        
            gotoxy(0, 2);
            write ('move: ', mainBoard.moveNr, ' turn: ');
            if mainBoard.flags and moveBlackFlag = 0 then
                write ('white')
            else
                write ('black');
        
            if humanSide = sideToMove (mainBoard) then
                playerMove (mainBoard, playMove.move, humanSide);	// may change game side
            isHumanMove := humanSide = sideToMove (mainBoard);
            showMessage ('');
                
            if not isHumanMove then
                begin
                    gotoxy (18, 18);
                    write('thinking...');
                    playMove := generateMove (gamePly, mainBoard);
                    showHChar (18, 18, 32, 11);
                    
                    if playMove.move.pieceType = InvalidPiece then
                        begin
                            showMessage ('stalemate!');
                            waitKeyPressed;
                            Utility (dummy);
                            exit                            
                        end
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

            enterMoveSimple (mainBoard, playMove.move);
            enterPositionHash (playMove.move, mainBoard.hash);

            BoardDisplay (mainBoard);
            
            if isThreeFoldRepetition then
                showMessage ('3-fold rep');

            {look for check condition}
            checkFlag := isKingChecked (sideToMove (mainBoard), mainBoard);
            if checkFlag then
                begin
                    showMessage ('check!');
                    cWarning := 1;
                end;

            {look for checkmate or stalemate condition}
            if checkFlag then
                if isMovingSideMate (mainBoard) then
                    begin
                        showMessage ('checkmate!');
                        waitKeyPressed;
                        Utility (dummy);
                        exit;
                    end
                else if abs (playMove.Score) >= infinity then
                    begin
                        showMessage ('resign!');
                        waitKeypressed;
                        Utility (dummy);
                        exit;
                    end;
                
            showMove (playMove, isHumanMove);

//            check3Rep;

        until false
    end;

end.
