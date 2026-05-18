unit ui;

interface

uses vdp, globals, board;

procedure PrintGame;

procedure showPly;					// display ply/qs in 2nd line
procedure NewBoard;					// display main game screen
procedure BoardDisplay (var board: TBoardRecord);	// display only board

procedure EnterPos (var board: TBoardRecord; var turn: integer);
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



procedure PrintGame;

var 
    pturn, offset : integer;
    pcname : array [0..40] of char;
    status : boolean;
    rdir, iLocString, eLocString, gDate, pName : string;

begin
(*
    rdir := 'PIO';
    pcname[0] := 'P';
    pcname[8] := 'R';
    pcname[16] := 'N';
    pcname[24] := 'B';
    pcname[32] := 'Q';
    pcname[40] := 'K';

    gotoxy(20, 10);
    write(chr(7), 'opponent name:');
    gotoxy(20, 11);
    readln(pName);
    gotoxy(20, 10);
    write(chr(7), 'date:             ');
    gotoxy(20, 11);
    write('                  ');
    gotoxy(20, 11);
    readln(gDate);
    gotoxy(20, 12);
    write('printing...');
    offset := PLAYLIST;
    startPage := BASE2;
    dataSize := 8;
    pturn := 1;
    
    close (output);
    assign (output, rdir);
    rewrite (output);
    status := IOResult = 0;
    
    if status = FALSE then
        begin
            //   Exception(TRUE);
            gotoxy(20, 12);
            write(chr(7), 'printer error!');
        end
    else
        begin
            iLocString := '  ';
            eLocString := '  ';
            write('Phoenix Chess ');
            if humanSide = 0 then
                writeln('playing black')
            else
                writeln('playing white');
            writeln('Opponent: ', pName);
            writeln('Date: ', gDate);
            writeln('Ply: ', gamePly);
            writeln;
            repeat
                DataOps(2, startPage, dataSize, offset, moveStore);
                if moveStore.Id = 99 then
                    goto l_1;
                iLocString[1] := chr(65 + (moveStore.startSq mod 8));
                iLocString[2] := chr(49 + (moveStore.startSq div 8));
                eLocString[1] := chr(65 + (moveStore.endSq mod 8));
                eLocString[2] := chr(49 + (moveStore.endSq div 8));
                write(pturn, ': ', pcname[moveStore.Id], ']', iLocString, '-',
                      eLocString, '  ');
                offset := offset + 8;
                DataOps(2, startPage, dataSize, offset, moveStore);
                if moveStore.Id = 99 then
                    goto l_1;
                iLocString[1] := chr(65 + (moveStore.startSq mod 8));
                iLocString[2] := chr(49 + (moveStore.startSq div 8));
                eLocString[1] := chr(65 + (moveStore.endSq mod 8));
                eLocString[2] := chr(49 + (moveStore.endSq div 8));
                writeln(pcname[moveStore.Id], ']', iLocString, '-', eLocString);
                offset := offset + 8;
                pturn := succ(pturn);
                l_1: 
            until moveStore.Id = 99;
        end;
    //  Exception(TRUE);
    
    close (output);
    assign (output, '');
    rewrite (output);
*)    
    gotoxy(20, 12);
    write('               ');
end;
(* PrintGame *)

const 
    orgX = 1;
    orgY = 4;
    
procedure showPly;
    begin
        gotoxy (0, 1);
        writeln ('ply: ', gamePly, ' qs: ', succ (-plyQS))
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
    type
        TByteArray = array [0..7] of uint8;
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
(*                
        gotoxy (0, 22);
        write ('castling: ');
        if board.flags and whiteRightCastle <> 0 then
            write ('K');
        if board.flags and whiteLeftCastle <> 0 then
            write ('Q');
        if board.flags and blackRightCastle <> 0 then
            write ('k');
        if board.flags and blackLeftCastle <> 0 then
            write ('q');
        if board.flags and epMoveFlag <> 0 then            
            write (' EP: ', chr (ord ('A') + board.flags and 7), 6 - 3 * ord (board.flags and MoveBlackFlag <> 0));
        writeln;
        write ('hash: ');
        for i := 0 to 7 do 
            write (hexstr2 (TByteArray (board.hash) [i]));
        gotoxy(0, 14)
*)        
    end;
    
procedure loadFENData (var board: TBoardRecord; var turn, gameMove: integer);
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
            setFENPosition (board, gameMove, s)
        else
            writeln ('Cannot read ', fn);
        turn := ord (board.flags and moveBlackFlag <> 0);
        close (f)
    end;

procedure EnterPos (var board: TBoardRecord; var turn: integer);
    var 
        row, column, sideKey, pieceKey, offset : integer;
        ans, pLoc : integer;
        ch: char;
        pname : string;
        pieceType, bitval, side: integer;

    begin
        writeln;
        writeln ('load [f]en/[i]nteractive?');
        write ('(q) to exit');
        repeat
            ch := upcase (GetKey)
        until ch in ['F','I', 'Q'];
        writeln;
        
        if ch = 'Q' then 
            exit;
            
        if ch = 'F' then
            begin
                loadFENData (board, turn, gameMove);
                exit
            end;
        
        NewBoard;
        fillChar (board, sizeof (board), 0);
        BoardDisplay (board);

        repeat
            gotoxy (0, 22);
            writeln(chr(7), 'select side: [w]hite/[b]black');
            write('[q] to exit  ');
            repeat
                sideKey := GetKeyInt;
            until sideKey in[87, 66, 81];
            if sideKey <> 81 then
                begin
                    gotoxy (0, 22);
                    write ('select ');
                    if sideKey = 87 then
                        write ('white')
                    else
                        write ('black');
                    side := ord (sideKey <> 87);
                        
                    writeln(chr(7), ' piece: P/R/N/B/Q/K');
                    showHChar (0, 23, 32, 32);
                    repeat
                        pieceKey := GetKeyInt
                    until pieceKey in [66, 75, 78, 80, 81, 82, 88];
                    case pieceKey of 
                        66: 
                        begin
                            pieceType := Bishop;
                            pname := 'bishop';
                        end;
                        75: 
                        begin
                            pieceType := King;
                            pname := 'king';
                        end;
                        78: 
                        begin
                            pieceType := Knight;
                            pname := 'knight';
                        end;
                        80: 
                        begin
                            pieceType := Pawn;
                            pname := 'pawn';
                        end;
                        81: 
                        begin
                            pieceType := Queen;
                            pname := 'queen';
                        end;
                        82: 
                        begin
                            pieceType := Rook;
                            pname := 'rook';
                        end;
                    end;
                    gotoxy (0, 23);
                    write (pname, ' square [col|row]? ');
                    repeat
                        repeat
                            column := GetKeyInt
                        until column in[65..72];
                        write (chr(column));
                        dec (column, 65);
                        
                        repeat
                            row := GetKeyInt
                        until row in[49..56];
                        write (chr(row));
                        dec (row, 49);
                        
                        gotoxy (0, 22);
                        write('[c]onfirm [r]edo [d]elete piece');
                        repeat
                            ans := GetKeyInt
                        until ans in[67, 68, 82];
                    until ans <> 82;
                    
                    pLoc := 8 * row + column;
                    if ans = 67 then
                        begin
                            setSquare (board, side, pieceType, pLoc)
                        end
                    else 
                       begin
                            clearSquare (board, side, pieceType, pLoc)
                        end;
                    BoardDisplay (board);
                    showHChar (0, 23, 32, 2 * screenWidth)
                end;
        until sideKey = 81;

        clrscr;
        if getBit (board.white.kingBitboard, 4) = 1 then
            begin
                writeln(chr(7), 'allow white castling? (y/n)');
                repeat
                    ans := GetKeyInt;
                until ans in[78, 89];
                if ans = 89 then
                    begin
                        if getBit (board.white.rookBitboard, 0) = 1 then
                            enterCastleFlag (board, whiteLeftCastle, true);
                        if getBit (board.white.rookBitboard, 7) = 1 then
                            enterCastleFlag (board, whiteRightCastle, true)
                    end
            end;

        if getBit (board.black.kingBitboard, 60) = 1 then
            begin
                writeln(chr(7), 'allow black castling? (y/n)');
                repeat
                    ans := GetKeyInt;
                until ans in[78, 89];
                if ans = 89 then
                    begin
                        if getBit (board.black.rookBitboard, 56) = 1 then
                            enterCastleFlag (board, blackLeftCastle, true);
                        if getBit (board.black.rookBitboard, 63) = 1 then
                           enterCastleFlag (board, blackRightCastle, true)
                    end
            end;

        writeln ('side to start? [w]hite/[b]lack');
        repeat
            ch := upcase (getKey)
        until ch in ['W', 'B'];
        turn := ord (ch = 'B');
        setMoveFlag (board, turn);
        if turn = 0 then
            writeln('*** white to move ***')
        else
            writeln('*** black to move ***');

        write('enter move number: ');
        readln(gameMove)
    end;

procedure showMove (moveScore: TMoveScoreRecord; isHumanMove: boolean);
    begin
        gotoxy (18, 6);
        write ('last move: ');
        gotoxy (18, 7);
        printMove (output, moveScore.move);
        write (' ');
        
        if not isHumanMove then
            begin
                showHChar (0, 22, 32, 2 * screenWidth);
                gotoxy (0, 22);
                if (moveNumHi <> 0) or (moveNumLo <> 0) then
                    begin
                        write('positions evaluated: ');
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
                        write('position score: ', moveScore.score)
                    end
                else
                    write ('book move')
            end;
    end;

procedure initVideoMode;

    procedure pattern; external '../resources/pattern.dat';
    
    type
        TPatternData = array [0..3, Pawn..King, 0..31] of uint8;
    
    var
        patternDataRom: TPatternData absolute pattern;
        patternData: TPatternData;
        i, j, side, field, destChar, destGroup: integer;
        fg, bg: TColor;
        p1, p2, p3: array [0..7] of uint8;

    begin
        setVideoMode (StandardMode);
        clrscr;
        setBackColor (gray);
        setTextColor (black);
        enableScreenSaver (false);

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
                        bg := lightgreen
                    else
                        bg := darkyellow;
                    setColor (destGroup, fg, bg);
                    setColor (destGroup + 1, fg, bg);
                    setColor (destGroup + 2, fg, bg);
                    inc (destChar, 24);
                    inc (destGroup, 3)
                end;
        setColor (destGroup, darkyellow, lightgreen);
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
        for i := ord ('A') to ord ('Z') do
            begin
                vmbr (p1, patternTable + i * 8, 8);
                vmbw (p1, patternTable + (i + ord ('a') - ord ('A')) * 8, 8)
            end
        
    end;

end.
