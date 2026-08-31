
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
        n: integer;
    begin
        writeln;
        changePly;
            
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
            
//        writeln (chr (7), 'Log to DSK0.phoenix.log (y/n)');
//        if getKeySet (['Y', 'N']) = 'Y' then
//            startLogging ('DSK0.phoenix.log');
            
        writeln (chr (7), 'Select pattern: [d]ark/[l]ight');
        darkMode := getKeySet (['D', 'L']) = 'D';
        if not darkMode then
            initVideoMode (false);

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
                begin
                    playerMove (mainBoard, playMove.move, humanSide);	// may change game side
                    showMessage ('')
                end;
            isHumanMove := humanSide = sideToMove (mainBoard);
                
            if not isHumanMove then
                begin
                    gotoxy (18, 18);
                    write('thinking...');
                    playMove := generateMove (gamePly, mainBoard);
                    showMessage ('');
                    showHChar (18, 18, 32, 11);
                    soundBell;
                    
                    if playMove.move.pieceType = InvalidPiece then
                        begin
                            showMessage ('stalemate!');
                            waitKeyPressed;
                            Utility (dummy, mainBoard)
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
                        Utility (dummy, mainBoard)
                    end;
(*                    
                else if abs (playMove.Score) >= infinity then
                    begin
                        showMessage ('resign!');
                        waitKeypressed;
                        Utility (dummy, mainBoard);
                    end;
*)                    
                
            showMove (playMove, isHumanMove)
        until false
    end;

end.
