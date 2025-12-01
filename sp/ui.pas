unit ui;

interface

uses {$U chesslib.code} globals;

procedure PrintGame;
procedure BoardDisplay;
procedure EnterPos (var board: TBoardRecord);
procedure MoveCoord(score, iLoc, eLoc : integer; flag : boolean);

implementation

uses trimprocs;

procedure PrintGame;

label 
    l_1;

var 
    pturn, offset : integer;
    pcname : array [0..40] of char;
    status : boolean;
    moveStore : moverec;
    rdir, iLocString, eLocString, gDate, pName : string;

begin
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
    
    gotoxy(20, 12);
    write('               ');
end;
(* PrintGame *)

procedure NewBoard;

var 
    y, row : integer;

begin
    clrscr;
    writeln('Phoenix Chess');
    writeln('ply : ', gamePly);
    writeln;
    y := 4;
    row := 8;
    writeln('------------------');
    repeat
        gotoxy(0, y);
        writeln(row, '| |=| |=| |=| |=|');
        writeln(pred(row), '|=| |=| |=| |=| |');
        y := y + 2;
        row := row - 2;
    until y > 10;
    writeln('------------------');
    writeln('  A B C D E F G H');
end; {NewBoard}

procedure BoardDisplay;

var 
    i, j, x, y, side, offset, offset1, pLoc : integer;
    posArray : bitarray;

begin
    NewBoard;
    startPage := BASE;
    dataSize := 8;
    for side := 0 to 1 do
        begin
            if side = 0 then
                offset := WPO
            else
                offset := BPO;

            j := 0;
            repeat
                offset1 := offset + ((j div 8) * 8);
                DataOps(2, startPage, dataSize, offset1, bit1);
                if not(IsClear(bit1)) then
                    begin
                        BitPos(bit1, posArray);
                        for i := 1 to posArray[0] do
                            begin
                                pLoc := posArray[i];
                                y := 11 - (pLoc div 8);
                                x := ((pLoc mod 8) * 2) + 2;
                                gotoxy(x, y);
                                case j of 
                                    0 : write(chr(80 + (side * 32)));
                                    8 : write(chr(82 + (side * 32)));
                                    16: write(chr(78 + (side * 32)));
                                    24: write(chr(66 + (side * 32)));
                                    32: write(chr(81 + (side * 32)));
                                    40: write(chr(75 + (side * 32)));
                                end;
                            end;
                    end;
                j := j + 8;
            until j > 40;
        end;
    gotoxy(0, 14);
end; {BoardDisplay}

procedure ClearPrompts;

var 
    y : integer;

begin
    for y := 14 to 20 do
        begin
            gotoxy(0, y);
            write('                                    ');
        end;
    gotoxy(0, 14);
end; {ClearPrompts}

procedure EnterPos (var board: TBoardRecord);

label 
    l_1;

var 
    x, y, orgX, orgY, row, column, sideKey, pieceKey, offset : integer;
    offset1, offset2, ans, pLoc : integer;
    pname : string;

begin
    NewBoard;
    startPage := BASE;
    dataSize := 8;
    orgX := 2;
    orgY := 11;

    offset := WPO;
    repeat
        ClearBitboard(bit1);
        Dataops(1, startPage, dataSize, offset, bit1);
        offset := offset + 8;
    until offset > 40;

    offset := BPO;
    repeat
        ClearBitboard(bit1);
        DataOps(1, startPage, dataSize, offset, bit1);
        offset := offset + 8;
    until offset > (BPO + 40);

    offset := WPIECES;
    ClearBitboard(bit1);
    DataOps(1, startPage, dataSize, offset, bit1);
    offset := BPIECES;
    ClearBitboard(bit1);
    DataOps(1, startPage, dataSize, offset, bit1);
    offset := APIECES;
    ClearBitboard(bit1);
    DataOps(1, startPage, dataSize, offset, bit1);

    gotoxy(0, 14);
    repeat
        writeln(chr(7), 'select side: [w]hite/[b]black');
        write('[q] to exit  ');
        repeat
            sideKey := GetKeyInt;
        until sideKey in[87, 66, 81];
        if sideKey <> 81 then
            begin
                if sideKey = 87 then
                    writeln('*** white selected ***')
                else
                    writeln('*** black selected ***');
                writeln(chr(7), 'select piece: P / R / N / B / Q / K');
                repeat
                    pieceKey := GetKeyInt;
                until pieceKey in[66, 75, 78, 80, 81, 82, 88];
                case pieceKey of 
                    66: 
                    begin
                        if sideKey = 87 then
                            offset := WBO
                        else
                            offset := BBO;
                        pname := 'bishop';
                    end;
                    75: 
                    begin
                        if sideKey = 87 then
                            offset := WKO
                        else
                            offset := BKO;
                        pname := 'king';
                    end;
                    78: 
                    begin
                        if sideKey = 87 then
                            offset := WNO
                        else
                            offset := BNO;
                        pname := 'knight';
                    end;
                    80: 
                    begin
                        if sideKey = 87 then
                            offset := WPO
                        else
                            offset := BPO;
                        pname := 'pawn';
                    end;
                    81: 
                    begin
                        if sideKey = 87 then
                            offset := WQO
                        else
                            offset := BQO;
                        pname := 'queen';
                    end;
                    82: 
                    begin
                        if sideKey = 87 then
                            offset := WRO
                        else
                            offset := BRO;
                        pname := 'rook';
                    end;
                end;
                writeln('*** ', pname, ' selected ***');
                writeln(chr(7), 'enter board square [column|row]');
                l_1: 
                gotoxy(0, 19);
                write('                       ');
                gotoxy(0, 20);
                write('                                    ');
                gotoxy(0, 19);
                repeat
                    column := GetKeyInt;
                until column in[65..72];
                write(chr(column));
                repeat
                    row := GetKeyInt;
                until row in[49..56];
                writeln(chr(row));
                write('[c]onfirm [r]edo [d]elete piece');
                repeat
                    ans := GetKeyInt;
                until ans in[67, 68, 82];
                if ans = 82 then
                    goto l_1;
                pLoc := ((row - 49) * 8) + (column - 65);
                x := ((column - 65) * 2) + orgX;
                y := orgY - (row - 49);
                gotoxy(x, y);
                if ans = 67 then
                    begin
                        if sideKey = 87 then
                            write(chr(pieceKey))
                        else
                            write(chr(pieceKey + 32));
                    end
                else
                    begin
                        if odd(row) then
                            begin
                                if odd(column) then
                                    write('=')
                                else
                                    write(' ');
                            end
                        else
                            begin
                                if odd(column) then
                                    write(' ')
                                else
                                    write('=');
                            end;
                    end;
                offset1 := PIECELOC + (pLoc * 8);
                DataOps(2, startPage, dataSize, offset, bit1);
                DataOps(2, startPage, dataSize, offset1, bit2);
                offset1 := APIECES;
                if sideKey = 87 then
                    offset2 := WPIECES
                else
                    offset2 := BPIECES;
                if ans = 68 then
                    begin
                        BitNot(bit2, bit2);
                        BitAnd(bit1, bit2, bit1);
                        DataOps(1, startPage, dataSize, offset, bit1);
                        DataOps(2, startPage, dataSize, offset1, bit1);
                        BitAnd(bit1, bit2, bit1);
                        DataOps(1, startPage, dataSize, offset1, bit1);
                        DataOps(2, startPage, dataSize, offset2, bit1);
                        BitAnd(bit1, bit2, bit1);
                        DataOps(1, startPage, dataSize, offset2, bit1);
                    end
                else
                    begin
                        BitOr(bit1, bit2, bit1);
                        DataOps(1, startPage, dataSize, offset, bit1);
                        DataOps(2, startPage, dataSize, offset1, bit1);
                        BitOr(bit1, bit2, bit1);
                        DataOps(1, startPage, dataSize, offset1, bit1);
                        DataOps(2, startPage, dataSize, offset2, bit1);
                        BitOr(bit1, bit2, bit1);
                        DataOps(1, startPage, dataSize, offset2, bit1);
                    end;
                ClearPrompts;
            end;
    until sideKey = 81;

    castleFlags := 0;

    writeln;
    writeln(chr(7), 'allow white castling? (y/n)');
    repeat
        ans := GetKeyInt;
    until ans in[78, 89];
    if ans = 78 then
        castleFlags := castleFlags or whiteCastleFlag
    else
        begin
            if getBit (board.white.rookBitboard, 0) = 0 then
                castleFlags := castleFlags or whiteRookLeftFlag;
            if getBit (board.white.rookBitboard, 7) = 0 then
                castleFlags := castleFlags or whiteRookRightFlag
        end;

    writeln(chr(7), 'allow black castling? (y/n)');
    repeat
        ans := GetKeyInt;
    until ans in[78, 89];
    if ans = 78 then
        castleFlags := castleFlags or blackCastleFlag
    else
        begin
            if getBit (board.black.rookBitboard, 56) = 0 then
                castleFlags := castleFlags or blackRookLeftFlag;
            if getBit (board.black.rookBitboard, 63) = 0 then
                castleFlags := castleFlags or blackRookRightFlag
        end;

    writeln(chr(7), 'side to start? [w]hite/[b]lack');
    repeat
        ans := GetKeyInt;
    until ans in[87, 66];
    if ans = 87 then
        begin
            writeln('*** white to move ***');
            turn := 0;
        end
    else
        begin
            writeln('*** black to move ***');
            turn := 1;
        end;

    write('enter move number: ');
    readln(gameMove);
end; {EnterPos}

var
    rs232: text;

procedure MoveCoord(score, iLoc, eLoc : integer; flag : boolean);

var 
    iLocString, eLocString : string;

begin
    iLocString := '  ';
    eLocString := '  ';
    iLocString[1] := chr(65 + (iLoc mod 8));
    iLocString[2] := chr(49 + (iLoc div 8));
    eLocString[1] := chr(65 + (eLoc mod 8));
    eLocString[2] := chr(49 + (eLoc div 8));
    gotoxy(20, 4);
    writeln('last move: ', iLocString, ' to ', eLocString);
    if not(flag) then
        begin
            gotoxy(30, 16);
            writeln('        ');
            gotoxy(15, 17);
            writeln('            ');
            gotoxy(0, 16);
            write('number of positions evaluated: ');
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
            write('position score: ', score);
            writeln (rs232, iLocString, eLocString)
        end;
end; {MoveCoord}

begin
    assign (rs232, 'RS232');
    rewrite (rs232)
end.
