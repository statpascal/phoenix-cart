
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
        ch: char;
    begin
        writeln;
        write (chr (7), 'Enter ply: [1-6]: ');
        ch := getKeySet (['1'..'6']);
        writeln (ch);
        gamePly := ord (ch) - ord ('0');

        write ('QS deepening (0-9/u): ');
        ch := getKeySet (['0'..'9', 'U']);
        writeln (ch);
        if ch = 'U' then
            plyQS := -Maxint
        else
            plyQS := 1 - (ord (ch) - ord ('0'));
            
        writeln (chr (7), 'Select side: [w]hite/[b]lack');
        if getKeySet (['W', 'B']) = 'B' then
            begin
                humanSide := 1;
                writeln ('Playing as black');
            end
        else
            begin
                humanSide := 0;
                writeln ('Playing as white');
            end;
            
        writeln (chr (7), 'Log to DSK0.phoenix.log (y/n)');
        if getKeySet (['Y', 'N']) = 'Y' then
            startLogging ('DSK0.phoenix.log');

        cWarning := 0            
    end;

procedure chainMain;
    var mainBoard: TBoardRecord;
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
                            Utility (dummy, mainBoard);
                            exit                            
                        end
                end;

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
                        Utility (dummy, mainBoard);
                        exit;
                    end
                else if abs (playMove.Score) >= infinity then
                    begin
                        showMessage ('resign!');
                        waitKeypressed;
                        Utility (dummy, mainBoard);
                        exit;
                    end;
                
            showMove (playMove, isHumanMove)
        until false
    end;

end.
