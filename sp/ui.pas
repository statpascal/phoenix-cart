unit ui;

interface

uses vdp, globals, board;

procedure showPly;					// display ply/qs in 2nd line
procedure NewBoard;					// display main game screen
procedure BoardDisplay (var board: TBoardRecord);	// display only board

procedure showMove (moveScore: TMoveScoreRecord; isHumanMove: boolean);

function getKeyInt: integer;

type
    charset = set of char;
    
function getKeySet (validKeys: charset): char;

procedure waitKeyPressed;

procedure initVideoMode (dark: boolean);
procedure showSplashScreen;


implementation

uses trimprocs, logger;

const
    PatternSplitNumbers = 0;
    PatternSplitChars = 16;
    
procedure waitKeypressed;
    begin
        while keyPressed do;
        waitkey
    end;

function getKeyInt: integer;
    begin
        getKeyInt := ord (upcase (getkey ()))
    end;
    
function getKeySet (validKeys: charset): char;
    var
        ch: char;
    begin
        repeat
            ch := upcase (getKey)
        until ch in validKeys;
        getKeySet := ch
    end;

const 
    orgX = 1;
    orgY = 4;
    
procedure showPly;
    begin
        gotoxy (0, 1);
        showHChar (0, 1, 32, 32);
        write ('ply: ', gamePly, ' qs: ');
        if plyQS = -Maxint then
            write ('unlimited')
        else
            write (succ (-plyQS))
    end;

procedure NewBoard;
    var 
        row, col: integer;
    begin
        clrscr;
        writeln ('Phoenix Chess ', versionString);
        showPly;
        for row := 0 to 15 do
            begin
                showHChar (0, orgY + row, row, 1);
                showHChar (succ (row), orgY + 16, PatternSplitChars + row, 1)
            end
    end; 

procedure BoardDisplay (var board: TBoardRecord);
    var 
        s, piece, i, row, col: integer;
        posArray: bitarray;
        lines: array [0..15] of string [16];
        
    procedure showSquare (row, col, pattern: integer);
        begin
            row := 2 * (7 - row);
            col := succ (col + col);
            lines [row, col] := chr (pattern);
            lines [row, succ (col)] := chr (succ (pattern));
            lines [succ (row), col] := chr (pattern + 16);
            lines [succ (row), succ (col)] := chr (pattern + 17)
        end;

    begin
        for row := 0 to 7 do
            for col := 0 to 7 do
                showSquare (row, col, 128 + 12 + 32 * ord (odd (row) = odd (col)));
        
        for s := 0 to 1 do
            for piece := Pawn to King do
                begin
                    BitPos (board.sides [s].bitboards [piece], posArray);
                    for i := 1 to posArray [0] do
                        begin
                            row := posArray [i] div 8;
                            col := posArray [i] mod 8;
                            showSquare (row, col, 128 + 2 * piece + 32 * ord (odd (row) = odd (col)) + 64 * s)
                        end
                end;
                
        for row := 0 to 15 do
            begin
                lines [row][0] := #16;
                gotoxy (orgX, orgY + row);
                write (lines [row])
            end;
            
        gotoxy(0, 2);
        write ('move: ', board.moveNr, ' turn: ');
        if board.flags and moveBlackFlag = 0 then
            write ('white')
        else
            write ('black')
    end;
    
procedure showMove (moveScore: TMoveScoreRecord; isHumanMove: boolean);
    begin
        gotoxy (18, 6);
        write ('Last move: ');
        gotoxy (18, 7);
        printMove (output, moveScore.move);
        write (' ');
        
        if not isHumanMove then
            begin
                showHChar (0, 22, 32, 2 * screenWidth);
                gotoxy (0, 22);
                if (moveNumHi <> 0) or (moveNumLo <> 0) then
                    begin
                        write('Positions evaluated: ');
                        if moveNumHi > 0 then
                            begin
                                write (moveNumHi);
                                write ('000');
                                if moveNumLo >= 100 then
                                    gotoxy (wherex - 3, wherey)
                                else if moveNumLo >= 10 then
                                    gotoxy (wherex - 2, wherey)
                                else
                                    gotoxy (wherex - 1, wherey);
                                writeln (moveNumLo)
                            end
                        else
                            writeln (moveNumLo);
                        write('Position score: ', moveScore.score)
                    end
                else
                    write ('Book move')
            end;
    end;

type
    TTableData = array [0..6143] of uint8;

procedure loadPatternTable;
    procedure patternTableData; external '../resources/splashp.dat';
    var
        buf: TTableData;
        data: TTableData absolute patternTableData;
    begin
        buf := data;
        vmbw (buf, patternTable, 6144)
    end;
    
procedure loadColorTable;
    procedure colorTableData; external '../resources/splashc.dat';
    var
        buf: TTableData;
        data: TTableData absolute colorTableData;
    begin
        buf := data;
        vmbw (buf, colorTable, 6144)
    end;
    
procedure showSplashScreen;
    var
        saveDiskBufs: array [0..4095] of uint8;
    begin
        vmbr (saveDiskBufs, 16384 - sizeof (saveDiskBufs), sizeof (saveDiskBufs));
        setVideoMode (BitmapMode);
        loadPatternTable;
        loadColorTable;
        waitKeyPressed;
        vmbw (saveDiskBufs, 16384 - sizeof (saveDiskBufs), sizeof (saveDiskBufs));
    end;

procedure initVideoMode (dark: boolean);

    procedure patternDark; external '../resources/pattern-dark.dat';
    procedure patternLight; external '../resources/pattern-light.dat';
    
    procedure setCol (group: integer; fg, bg: uint8);
        begin
            setColor (group, TColor (fg), TColor (bg))
        end;
    
    type
        TPatternData = record
            charData: array [0..255, 0..7] of uint8;
            colorTable: array [0..31] of uint8;
            backColor: TColor
        end;
    
    var
        patternDataRomDark: TPatternData absolute patternDark;
        patternDataRomLight: TPatternData absolute patternLight;
        patternData: TPatternData;
        i, j, field, destChar: integer;
        p1, p2, p3: array [0..7] of uint8;

    begin
        setVideoMode (StandardMode);
        setBackColor (black);
        clrscr;
        enableScreenSaver (false);
        
        if dark then
            patternData := patternDataRomDark
        else
            patternData := patternDataRomLight;
            
        vmbw (patternData.charData, patternTable, sizeof (patternData.charData));
        vmbw (patternData.colorTable, colorTable, sizeof (patternData.colorTable));
        setBackColor (patternData.backColor);
        
        // create split numbers 1 - 8
        fillChar (p2, 8, #0);
        fillChar (p3, 8, #0);
        destChar := patternTable + PatternSplitNumbers;
        for i := 0 to 7 do
            begin
                vmbr (p1, patternTable + (ord ('8') - i) * 8, 8);
                move (p1, p2 [4], 4);
                move (p1 [4], p3, 4);
                vmbw (p2, destChar, 8);
                vmbw (p3, destChar + 8, 8);
                inc (destChar, 16)
            end;
        
        // create split chars A - H
        destChar := patternTable + 8 * PatternSplitChars;
        for i := 0 to 7 do
            begin
                vmbr (p1, patternTable + (ord ('A') + i) * 8, 8);
                p2 [0] := 0; p3 [0] := 0;
                for j := 0 to 6 do
                    begin
                        p2 [succ (j)] := p1 [j] shr 4;
                        p3 [succ (j)] := (p1 [j] and $f) shl 4;
                    end;
                vmbw (p2, destChar, 8);
                vmbw (p3, destChar + 8, 8);
                inc (destChar, 16)
            end
    end;

end.
