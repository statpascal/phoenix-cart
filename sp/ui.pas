unit ui;

interface

uses vdp, globals, board;

procedure showPly;					// display ply/qs in 2nd line
procedure NewBoard;					// display main game screen
procedure BoardDisplay (var board: TBoardRecord);	// display only board

procedure showMove (moveScore: TMoveScoreRecord; isHumanMove: boolean);

function getKeyInt: integer;
procedure waitKeyPressed;

procedure initVideoMode;


implementation

uses trimprocs, logger;

const
    PatternBaseWhiteOnWhite = 128;
    PatternBaseWhiteOnBlack = 152;
    PatternBaseBlackOnWhite = 176;
    PatternBaseBlackOnBlack = 200;
    PatternEmptyWhite = 224;
    PatternEmptyBlack = 228;
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
            lines [succ (row), col] := chr (pattern + 2);
            lines [succ (row), succ (col)] := chr (pattern + 3)
        end;

    begin
        for row := 0 to 7 do
            for col := 0 to 7 do
                showSquare (row, col, PatternEmptyWhite + 4 * ord (odd (row) = odd (col)));
        
        for s := 0 to 1 do
            for piece := Pawn to King do
                begin
                    BitPos (board.sides [s].bitboards [piece], posArray);
                    for i := 1 to posArray [0] do
                        begin
                            row := posArray [i] div 8;
                            col := posArray [i] mod 8;
                            showSquare (row, col, PatternBaseWhiteOnWhite + 4 * piece + 24 * ord (odd (row) = odd (col)) + 48 * s)
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
            write ('black');
    
        
    end;
    
(*    
procedure loadFENData (var board: TBoardRecord);
    var
        fn, s: string;
        f: text;
    begin
        write ('Filename: ');
        readln (fn);
        assign (f, fn);
        s := '';
        reset (f);
        readln (f, s);
        if s <> '' then
            setFENPosition (board, s)
        else
            writeln ('Cannot read ', fn);
        close (f)
    end;
*)    

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

procedure initVideoMode;

    procedure charset; external '../resources/font-221.bin';
    procedure pattern; external '../resources/pattern.dat';
    
    type
        TCharData = array [0..767] of uint8;
        TPatternData = array [0..3, Pawn..King, 0..31] of uint8;
    
    var
        patternDataRom: TPatternData absolute pattern;
        charDataRom: TCharData absolute charset;
        patternData: TPatternData;
        charData: TCharData;
        i, j, side, field, destChar, destGroup: integer;
        fg, bg: TColor;
        p1, p2, p3: array [0..7] of uint8;

    begin
        setVideoMode (StandardMode);
        clrscr;
//        setBackColor (gray);
        setBackColor (white);
        setTextColor (black);
        enableScreenSaver (false);
        
        charData := charDataRom;
        vmbw (charData, patternTable + 8 * ord (' '), sizeof (charData));

        patternData := patternDataRom;
        destChar := PatternBaseWhiteOnWhite;
        destGroup := destChar div 8;
        
        vmbw (patternData, patternTable + 8 * destChar, sizeof (patternData));
        for side := 0 to 1 do
            for field := 0 to 1 do
                begin
                    if side = 0 then
                        fg := white
                    else
                        fg := black;
                    if field = 0 then
                        bg := gray // lightgreen
                    else
                        bg := darkyellow;
                    setColor (destGroup, fg, bg);
                    setColor (destGroup + 1, fg, bg);
                    setColor (destGroup + 2, fg, bg);
                    inc (destChar, 24);
                    inc (destGroup, 3)
                end;
//        setColor (destGroup, darkyellow, lightgreen);
        setColor (destGroup, darkyellow, gray);
        vrbw (patternTable + 8 * PatternEmptyBlack, $ff, 32);
        
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
            end;
            
        // replace lower case char definition
//        for i := ord ('A') to ord ('Z') do
//            begin
//                vmbr (p1, patternTable + i * 8, 8);
//                vmbw (p1, patternTable + (i + ord ('a') - ord ('A')) * 8, 8)
//            end
        
    end;

end.
