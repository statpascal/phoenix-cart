unit utility;

interface

uses board;

procedure Utility (var humanSide: integer; var board: TBoardRecord);
procedure changePly;


implementation

uses globals, ui, logger, genmove;

const
    xOrg = 18;
    yOrg = 6;
    Height = 15;

var
    lineCount: integer;
    
procedure clearUtilityMenu;
    var 
        i: integer;
    begin
        for i := 0 to height - 1 do
            showHChar (xOrg, yOrg + i, 32, 32 - xOrg);
        linecount := 0
    end;
    
procedure clearButtomLines;
    begin
        showHChar (0, 22, 32, 2 * screenWidth)
    end;
    
procedure showMenuLine (s: string);
    begin
        gotoxy (xOrg, yOrg + lineCount);
        write (s);
        inc (lineCount)
    end;
    
function getFileName (prompt: string): string;
    begin
        clearButtomLines;
        gotoxy (0, 22);
        writeln (prompt);
        readln (result);
        clearButtomLines
    end;
    
function isFileError (var f: text; name: string): boolean;
    var
        res: integer;
    begin
        res := IOResult;
        result := res <> 0;
        if result then
            begin
                gotoxy (0, 22);
                writeln ('File: ', name);
                case res of
                    FileWriteProtected:
                        write ('Write protection');
                    FileBadAttributes:
                        write ('Bad attributes');
                    FileIllegalOperation:
                        write ('Illegal operation');
                    FileDiskFull:
                        write ('Disk full');
                    FilePastEOF:
                        write ('Past EOF');
                    FileDeviceError:
                        write ('Device error');
                    FileError:
                        write ('Error accessing');
                    FileMaxOpen:
                        write ('Too many open files');
                    FileInvalidDsrName:
                        write ('DSR not found');
                    FileInvalidName:
                        write ('Invalid name');
                    FileNotOpen:
                        write ('Not open')
                end;
                waitKeyPressed;
                clearButtomLines;
                close (f);
                res := IOResult	// clear error code
            end
    end;

procedure ShowUtilityMenu;
    begin
        showMenuLine ('A: load game');
        showMenuLine ('B: save game');
        showMenuLine ('C: backup');
        showMenuLine ('D: forward');
        showMenuLine ('E: first move ');
        showMenuLine ('F: last move');
        showMenuLine ('G: switch side');
        showMenuLine ('H: change ply');
        showMenuLine ('I: play');
        showMenuLine ('J: write FEN');
        showMenuLine ('K: new game');
        showMenuLine ('L: setup pos');
        showMenuLine ('M: print game');
        showMenuLine ('N: exit cart');
        showMenuLine ('O: license')
    end;
    
procedure printGame;
    var 
        f: text;
        s: string;
        side, count, moveNr, total: integer;
        startPosition: TBoardRecord;
        move: TMoveRecord;
    begin
        s := getFileName ('Print to [PIO]:');
        if s = '' then
            s := 'PIO';
        
        assign(f, s);
        rewrite (f);
        
        if isFileError (f, s) then
            exit;
        
        writeln (f, 'Initial posiition:');
        
        startPosition := getGameStartPosition;
        writeln (f, makeFENString (startPosition));
        writeln (f);
        
        count := 0;
        side := sideToMove (startPosition);
        moveNr := startPosition.moveNr;
        total := getGameMoveCount;
        
        while count < total do
            begin
                if (side = 0) or (count = 0) then
                    write (f, moveNr, '. ');
                if (count = 0) and (side = 1) then
                    write (f, '... ');
                move := getGameSavedMove (count);
                printMove (f, move);
                inc (count);
                if side = 0 then 
                    write (f, ' ')
                else
                    begin
                        inc (moveNr);
                        writeln (f)
                    end;
                side := 1 - side;
            end;
            
        writeln (f);
        if isFileError (f, s) then
            exit;
        close (f)
    end;
    
procedure loadGame (var board: TBoardRecord);
    var
        f: text;
        s: string;
        move: TMoveRecord;

    function readCoord (col, row: char): integer;
        begin
            readCoord := ord (upcase (col)) - ord ('A') + 8 * (ord (row) - ord ('1'))
        end;

    begin
        s := getFileName ('Load game from file:');
        if s = '' then 
            exit;
            
        assign (f, s);
        reset (f);
        if isFileError (f, s) then
            exit;
        
        readln (f, s);
        if isFileError (f, s) then
            exit;
        
        setFENPosition (board, s);
        while not eof (f) do
            begin
                readln (f, s);
                if length (s) >= 4 then
                    begin
                        move := makeMoveRecord (board, readCoord (s [1], s [2]), readCoord (s [3], s [4]));
                        if length (s) = 5 then
                            move.flags := move.flags or pos (upcase (s [5]), 'RNBQ') shl 4;
                        enterMoveSimple (board, move);
                        enterPositionHash (move, board.hash);
                        BoardDisplay (board);
                    end
            end;
            
        if isFileError (f, s) then
            exit;
        close (f)
    end;
            
procedure saveGame;
    var
        f: text;
        s: string;
        i, promotion: integer;
        startPosition: TBoardRecord;
        move: TMoveRecord;
        
    procedure writeCoord (sq: integer);
        begin
            write (f, chr (ord ('a') + sq mod 8), chr (ord ('1') + sq div 8))
        end;
        
    begin
        s := getFileName ('Save game to file:');
        if s = '' then
            exit;

        assign (f, s);
        rewrite (f);
        if isFileError (f, s) then
            exit;
            
        startPosition := getGameStartPosition;
        writeln (f, makeFENString (startPosition));
 
        // TODO: parantheses should not be required in call to getGameMoveCount
        for i := 0 to pred (getGameMoveCount ()) do
            begin
                move := getGameSavedMove (i);
                writeCoord (move.startSq);
                writeCoord (move.endSq);
                promotion := move.flags shr 4;
                if promotion <> 0 then
                    write (f, figure [1, promotion]);
                writeln (f)
            end;
            
        if isFileError (f, s) then
            exit;
            
        close (f);
    end;

procedure refreshBoard (var board: TBoardRecord);
    begin    
        clrscr;
        NewBoard;
        BoardDisplay (board);
        showPly;
        clearUtilityMenu
    end;
    
procedure changePly;
    var
        ch: char;
        n: integer;
    begin
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
            
        writeln ('Deepen search?');
        writeln ('[N]one [L]ight [M]edium [H]eavy');
        writeln ('[C]ustom');
        ch := getKeySet (['N', 'L', 'M', 'H', 'C']);
        if ch = 'C' then 
            begin
                writeln;
                writeln ('Custom setting of the minimal');
                write ('number of positions in thousands');
                writeln ('to evaluate. This will take');
                writeln ('1.5 minutes times the value');
                writeln ('entered.');
                writeln;
                write ('Select nodes [0-32767]: ');
                readln (n);
                writeln;
                setMaxMoves (n)
            end
    end;

procedure replayMove (var board: TBoardRecord; index: integer);
    var
        move: TMoveRecord;
    begin
        move := getGameSavedMove (index);
        enterMoveSimple (board, move);
        enterPositionHash (move, board.hash)
    end;
    
procedure writeFEN (var board: TBoardRecord);
    var
        s: string;
        f: text;
    begin
        s := getFileName ('Write FEN position to file:');
        if s = '' then 
            exit;
        
        assign (f, s);
        rewrite (f);
        if isFileError (f, s) then
            exit;
        
        writeln (f, makeFenString (board));
        if isFileError (f, s) then
            exit;
        close (f)
    end;    

procedure editBoard (var board: TBoardRecord);
    var 
        sideKey, ch: char;
        pieceName : string [6];
        pLoc, pieceType, side, i: integer;

    begin
        showMenuLine ('Clear (y/n)');
        if getKeySet (['Y', 'N']) = 'Y' then
            begin        
                fillChar (board, sizeof (board), 0);
                BoardDisplay (board)
            end;

        repeat
            clearUtilityMenu;
            showMenuLine ('Select side');
            showMenuLine ('[w]hite');
            showMenuLine ('[b]lack');
            showMenuLine ('[q]uit');
            sideKey := getKeySet (['W', 'B', 'Q']);
            
            if sideKey <> 'Q' then
                begin
                    showMenuLine ('');
                    if sideKey = 'W' then
                        showMenuLine ('select white')
                    else
                        showMenuLine ('select black');
                    side := ord (sideKey <> 'W');
                        
                    showMenuLine ('P/R/N/B/Q/K');
                    pieceType := pred (pos (getKeySet (['P', 'R', 'N', 'B', 'Q', 'K']), 'PRNBQK'));
                    case pieceType of
                        Pawn: 
                            pieceName := 'pawn';
                        Rook:
                            pieceName := 'rook';
                        Knight:
                            pieceName := 'knight';
                        Bishop:
                            pieceName := 'bishop';
                        Queen:
                            pieceName := 'queen';
                        King:
                            pieceName := 'king'
                    end;
                    showMenuLine ('');
                    showMenuLine (pieceName + ' square');
                    repeat
                        showMenuLine ('[col|row]? ');
                        ch := getKeySet (['A'..'H']);
                        write (ch);
                        ploc := ord (ch) - ord ('A');

                        ch := getKeySet (['1'..'8']);
                        write (ch);
                        inc (pLoc, 8 * (ord (ch) - ord ('1')));
                    
                        showMenuLine ('');
                        showMenuLine ('[c]onfirm');
                        showMenuLine ('[r]edo');
                        showMenuLine ('[d]elete');
                        ch := getKeySet (['C', 'R', 'D']);
                        
                        if ch = 'R' then
                            begin
                                dec (lineCount, 5);
                                for i := 0 to 4 do
                                    showHChar (xOrg, yOrg + lineCount + i, 32, 33 - xOrg)
                            end
                        
                    until ch <> 'R';
                    if ch = 'C' then
                        begin
                            setSquare (board, side, pieceType, pLoc)
                        end
                    else 
                       begin
                            clearSquare (board, side, pieceType, pLoc)
                        end;
                    BoardDisplay (board);
                    clearButtomLines
                end
        until sideKey = 'Q';

        if getBit (board.white.kingBitboard, 4) = 1 then
            begin
                gotoxy (0, 23);
                write ('Allow white castling? (y/n)');
                if getKeySet (['Y', 'N']) = 'Y' then
                    begin
                        if getBit (board.white.rookBitboard, 0) = 1 then
                            enterCastleFlag (board, whiteLeftCastle, true);
                        if getBit (board.white.rookBitboard, 7) = 1 then
                            enterCastleFlag (board, whiteRightCastle, true)
                    end
            end;

        if getBit (board.black.kingBitboard, 60) = 1 then
            begin
                gotoxy (0, 23); 
                write ('Allow black castling? (y/n)');
                if getKeySet (['Y', 'N']) = 'Y' then
                    begin
                        if getBit (board.black.rookBitboard, 56) = 1 then
                            enterCastleFlag (board, blackLeftCastle, true);
                        if getBit (board.black.rookBitboard, 63) = 1 then
                           enterCastleFlag (board, blackRightCastle, true)
                    end
            end;

        clearButtomLines;
        gotoxy (0, 23);
        write ('Side to start? [w]hite/[b]lack');
        ch := getKeySet (['W', 'B']);
        if sideToMove (board) <> ord (ch = 'B') then
            toggleMoveFlag (board);

        clearButtomLines;
        gotoxy (0, 23);
        write ('Enter move number: ');
        readln (board.moveNr);
        
        setGameStartPosition (board);
        NewBoard;
        BoardDisplay (board);
        clearUtilityMenu
    end;
    
procedure showLicense;
    
    procedure license; external '../resources/GPL.txt';
    
    type
        TLicense = array [0..6000] of char;
        
    var
        licenseText: TLicense absolute license;
        index, line: integer;
        
    procedure showContinueMessage;
        begin
            writeln;
            write ('=== Press any key to continue ===');
            waitKeyPressed;
            clrscr
        end;
    
    begin
        clrscr;
        setVideoMode (TextMode);
        if darkMode then
            begin
                setTextColor (white);
                setBackColor (black)
            end;
        index := 0;
        line := 0;
        while licenseText [index] <> '#' do
            begin
                if licenseText [index] = #10 then
                    begin
                        inc (line);
                        writeln;
                        if line mod 22 = 0 then 
                            showContinueMessage
                    end
                else
                    write (licenseText [index]);
                inc (index)
            end;

        showContinueMessage;        
        setVideoMode (StandardMode);
        initVideoMode (darkMode)
    end;

procedure Utility (var humanSide: integer; var board: TBoardRecord);
    var 
        utilDone: boolean;
        ch, sel: char;
        i, n, totalMoves, currentMove: integer;
    begin
        utilDone := false;
        totalMoves := getGameMoveCount;
        currentMove := totalMoves;
        clearUtilityMenu; 
        sel := 'A';
        
        repeat
            if sel in ['A', 'B', 'H'..'O'] then
                showUtilityMenu;
            repeat
                sel := upcase (getKey)
            until sel in ['A'..'O'];
            
            if sel in ['A', 'B', 'H'..'N'] then
                clearUtilityMenu;

            case sel of 
                'A':
                    begin
                        loadGame (board);
                        clearUtilityMenu;
                        totalMoves := getGameMoveCount;
                        currentMove := totalMoves
                    end;
                'B': 
                    begin
                        saveGame;
                        clearUtilityMenu
                    end;
                'C':
                    if currentMove > 0 then {backup}
                        begin
                            board := getGameStartPosition;
                            setGameStartPosition (board);
                            for i := 0 to currentMove - 2 do
                                replayMove (board, i);
                            dec (currentMove);
                            BoardDisplay (board)
                        end;
                'D':
                    if currentMove < totalMoves then {forward}
                        begin 
                            replayMove (board, currentMove);
                            BoardDisplay (board);
                            inc (currentMove);
                        end;
                'E':
                    begin {first move}
                        board := getGameStartPosition;
                        setGameStartPosition (board);
                        BoardDisplay (board);
                        currentMove := 0;
                    end;
                'F':
                    begin {last move}
                        while currentMove < totalMoves do
                            begin
                                replayMove (board, currentMove);
                                inc (currentMove)
                            end;
                        BoardDisplay (board);
                    end;
                'G':
                    {switch sides}
                    humanSide := 1 - humanSide;
                'H':
                    begin {change ply}
                        clrscr;
                        changePly;
                        refreshBoard (board)
                    end;
                'I':
                    utilDone := true;
                'J':
                    begin
                        writeFEN (board);
                        clearUtilityMenu
                    end;
                'K':
                    begin
                        showMenuLine ('new game?');
                        showMenuLine ('[y/n]');
                        if getKeySet (['Y', 'N']) = 'Y' then
                            begin
                                setInitPosition (board);
                                BoardDisplay (board);
                                utilDone := true
                            end;
                        clearUtilityMenu;
                    end;
                'L':
                    editBoard (board);
                'M': 
                    printGame;
                'N':
                    begin {exit game}
                        showMenuLine ('exit cart?');
                        showMenuLine ('[y/n]');
                        if getKeySet (['Y', 'N']) = 'Y' then
                            halt;
                        clearUtilityMenu
                    end;
                'O':
                    begin
                        showLicense;
                        refreshBoard (board)
                    end
            end;
        until utilDone
    end;

end.