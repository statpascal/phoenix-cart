unit ui;

interface

uses globals, board;

procedure PrintGame;
procedure BoardDisplay (var board: TBoardRecord);
procedure EnterPos (var board: TBoardRecord; var turn: integer);
procedure showMove (moveScore: TMoveScoreRecord; isHumanMove: boolean);

function getKeyInt: integer;


implementation

uses trimprocs;

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

procedure NewBoard;

var 
    y, row : integer;

begin
    clrscr;
    writeln('Phoenix Chess ', versionString);
    writeln('ply : ', gamePly, '-', succ (gamePly - plyQS));
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

procedure showSquare (row, col: integer; ch: char);
    const 
        orgX = 2;
        orgY = 11;
    begin
        gotoxy (orgX + 2 * col, orgY - row);
        write (ch)
    end;

procedure BoardDisplay (var board: TBoardRecord);
    var 
        s, piece, i: integer;
        posArray: bitarray;
    begin
        NewBoard;
        for s := 0 to 1 do
            for piece := Pawn to King do
                begin
                    BitPos (board.sides [s].bitboards [piece], posArray);
                    for i := 1 to posArray [0] do
                        showSquare (posArray [i] div 8, posArray [i] mod 8, figure [s, piece])
                end;
        gotoxy (0, 16);
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
            write (' EP: ', chr (ord ('A') + board.flags and 7), 3 + 3 * ord (board.flags and epWhiteFlag = 0));
        gotoxy(0, 14)
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
            setFENPosition (board, turn, gameMove, s)
        else
            writeln ('Cannot read ', fn);
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

        repeat
            gotoxy (0, 14);
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
                    side := ord (sideKey <> 87);
                        
                    writeln(chr(7), 'select piece: P / R / N / B / Q / K');
                    repeat
                        pieceKey := GetKeyInt;
                    until pieceKey in[66, 75, 78, 80, 81, 82, 88];
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
                    writeln('*** ', pname, ' selected ***');
                    writeln(chr(7), 'enter board square [column|row]');
                    repeat
                        showHChar (0, 19, 32, 2 * screenWidth);
                        gotoxy(0, 19);
                        
                        repeat
                            column := GetKeyInt
                        until column in[65..72];
                        write(chr(column));
                        dec (column, 65);
                        
                        repeat
                            row := GetKeyInt
                        until row in[49..56];
                        writeln(chr(row));
                        dec (row, 49);
                        
                        write('[c]onfirm [r]edo [d]elete piece');
                        repeat
                            ans := GetKeyInt
                        until ans in[67, 68, 82];
                    until ans <> 82;
                    
                    if ans = 67 then
                        showSquare (row, column, Figure [side, pieceType])
                    else 
                        if odd (row) = odd (column) then
                            showSquare (row, column, '=')
                        else
                            showSquare (row, column,' ');
                    
                    pLoc := 8 * row + column;
                    bitval := ord (ans = 67);
                    if side = 0 then
                        begin
                            setBit (board.white.bitboards [pieceType], pLoc, bitval);
                            setBit (board.white.pieces, pLoc, bitval)
                        end
                    else
                        begin
                            setBit (board.black.bitboards [pieceType], pLoc, bitval);
                            setBit (board.black.pieces, pLoc, bitval)
                        end;
                    setBit (board.allPieces, pLoc, bitval);
                    
                    showHChar (0, 14, 32, 7 * screenWidth)
                end;
        until sideKey = 81;

        board.flags := 0;

        writeln;
        writeln(chr(7), 'allow white castling? (y/n)');
        repeat
            ans := GetKeyInt;
        until ans in[78, 89];
        if ans = 89 then
            begin
                if getBit (board.white.rookBitboard, 0) = 1 then
                    board.flags := board.flags or whiteLeftCastle;
                if getBit (board.white.rookBitboard, 7) = 1 then
                    board.flags := board.flags or whiteRightCastle
            end;

        writeln(chr(7), 'allow black castling? (y/n)');
        repeat
            ans := GetKeyInt;
        until ans in[78, 89];
        if ans = 89 then
            begin
                if getBit (board.black.rookBitboard, 56) = 1 then
                    board.flags := board.flags or blackLeftCastle;
                if getBit (board.black.rookBitboard, 63) = 1 then
                    board.flags := board.flags or blackRightCastle
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
                board.flags := board.flags or moveBlackFlag;
            end;

        write('enter move number: ');
        readln(gameMove)
    end;

procedure showMove (moveScore: TMoveScoreRecord; isHumanMove: boolean);
    var 
        iLocString, eLocString: string [2];

    begin
        iLocString [0] := #2;
        eLocString [0] := #2;
        iLocString [1] := chr (65 + (moveScore.move.startSq mod 8));
        iLocString [2] := chr (49 + (moveScore.move.startSq div 8));
        eLocString [1] := chr (65 + (moveScore.move.endSq mod 8));
        eLocString [2] := chr (49 + (moveScore.move.endSq div 8));
        gotoxy(20, 4);
        writeln('last move: ', iLocString, ' to ', eLocString);
        if not isHumanMove then
            begin
                showHChar (0, 17, 32, 2 * screenWidth);
                gotoxy(0, 17);
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
                write('position score: ', moveScore.score);
            end;
    end;

end.
