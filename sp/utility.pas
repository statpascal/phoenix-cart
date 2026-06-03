unit utility;

interface

uses board;

procedure Utility (var humanSide: integer; var board: TBoardRecord);


implementation

uses globals, ui, logger;

const
    xOrg = 18;
    yOrg = 6;
    Height = 14;

var
    lineCount: integer;
    
procedure ClearUtilityMenu;
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

procedure ShowUtilityMenu;
    begin
        showMenuLine (' : load game');
        showMenuLine (' : save game');
        showMenuLine ('3: backup');
        showMenuLine ('4: forward  ');
        showMenuLine ('5: first move ');
        showMenuLine ('6: last move');
        showMenuLine ('7: switch side');
        showMenuLine ('8: change ply');
        showMenuLine ('9: play');
        showMenuLine ('[W]rite FEN');
        showMenuLine ('[N]ew game');
        showMenuLine ('[S]etup pos');
        showMenuLine ('[P]rint game');
        showMenuLine ('[E]xit cart')
    end;
    
procedure printGame;
    var 
        f: text;
        s: string;
        side, count, moveNr, total: integer;
        startPosition: TBoardRecord;
        move: TMoveRecord;
    begin
        gotoxy (xOrg, yOrg);
        write ('Print [PIO]:');
        gotoxy (xOrg, succ (yOrg));
        readln (s);
        if s = '' then
            s := 'PIO';
        
        assign(f, s);
        rewrite (f);
        
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
        close (f)
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
        fn: string;
        f: text;
    begin
        gotoxy (xOrg, yOrg);
        write ('Write FEN');
        gotoxy (xOrg, succ (yOrg));
        write ('Filename:');
        gotoxy (xOrg, yOrg + 2);
        readln (fn);
       
        assign (f, fn);
        rewrite (f);
        writeln (f, makeFenString (board));
        close (f)
    end;    

procedure editBoard (var board: TBoardRecord);
    var 
        row, column, sideKey, pieceKey, offset : integer;
        ans, pLoc : integer;
        ch: char;
        pname : string;
        pieceType, bitval, side: integer;

    begin
        gotoxy (xOrg, yOrg);
        write ('Clear (y/n)');
        repeat
            ch := upcase (getKey)
        until ch in ['Y', 'N'];

        if ch = 'Y' then
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
            repeat
                sideKey := GetKeyInt
            until sideKey in[87, 66, 81];
            
            if sideKey <> 81 then
                begin
                    showMenuLine ('');
                    if sideKey = 87 then
                        showMenuLine ('select white')
                    else
                        showMenuLine ('select black');
                    side := ord (sideKey <> 87);
                        
                    showMenuLine ('P/R/N/B/Q/K');
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
                    showMenuLine ('');
                    showMenuLine (pname + ' square');
                    showMenuLine ('[col|row]? ');
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
                        
                        showMenuLine ('');
                        showMenuLine ('[c]onfirm');
                        showMenuLine ('[r]edo');
                        showMenuLine ('[d]elete');
                        repeat
                            ans := GetKeyInt
                        until ans in[67, 68, 82]
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
                    clearButtomLines
                end;
        until sideKey = 81;

        if getBit (board.white.kingBitboard, 4) = 1 then
            begin
                gotoxy (0, 23);
                write ('Allow white castling? (y/n)');
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
                gotoxy (0, 23); 
                write ('Allow black castling? (y/n)');
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

        clearButtomLines;
        gotoxy (0, 23);
        write ('Side to start? [w]hite/[b]lack');
        repeat
            ch := upcase (getKey)
        until ch in ['W', 'B'];

        clearButtomLines;
        gotoxy (0, 23);
        write ('Enter move number: ');
        readln (board.moveNr);
        
        
        setGameStartPosition (board);
        NewBoard;
        BoardDisplay (board);
        clearUtilityMenu
    end;

procedure Utility (var humanSide: integer; var board: TBoardRecord);
    var 
        utilDone: boolean;
        ch: char;
        i, totalMoves, currentMove: integer;
    begin
        utilDone := false;
        totalMoves := getGameMoveCount;
        currentMove := totalMoves;

        repeat
            showUtilityMenu;
            repeat
                ch := upcase (getKey)
            until ch in ['E', '3'..'9', 'N', 'P', 'W', 'S'];
            clearUtilityMenu;

            case ch of 
                'P': 
                    PrintGame;
                '1': 
                    begin {load}
                    end;
                '2': 
                    begin {save}
                    end;
                '3':
                    if currentMove > 0 then {backup}
                        begin
                            board := getGameStartPosition;
                            setGameStartPosition (board);
                            for i := 0 to currentMove - 2 do
                                replayMove (board, i);
                            dec (currentMove);
                            BoardDisplay (board)
                        end;
                '4':
                    if currentMove < totalMoves then {forward}
                        begin 
                            replayMove (board, currentMove);
                            BoardDisplay (board);
                            inc (currentMove);
                        end;
                '5':
                    begin {first move}
                        board := getGameStartPosition;
                        setGameStartPosition (board);
                        BoardDisplay (board);
                        currentMove := 0;
                    end;
                '6':
                    begin {last move}
                        while currentMove < totalMoves do
                            begin
                                replayMove (board, currentMove);
                                inc (currentMove)
                            end;
                        BoardDisplay (board);
                    end;
                '7':
                    {switch sides}
                    humanSide := 1 - humanSide;
                '8':
                    begin {change ply}
                        repeat
                            gotoxy (xOrg, yOrg);
                            write (chr (7), 'ply: ');
                            readln (gamePly);
                        until gamePly in [1..6];
                        repeat
                            gotoxy (xOrg, yOrg + 1);
                            write (char (7), 'qs: ');
                            readln (ch)
                        until ch in ['0'..'9', 'u'];
                        if ch = 'u' then
                            plyQS := -Maxint
                        else
                            plyQS := 1 - (ord (ch) - ord ('0'));
                        showPly
                    end;
                '9':
                    utilDone := true;
                'W':
                    writeFen (board);
                'S':
                    editBoard (board);
                'N':
                    begin
                        gotoxy (xOrg, yOrg);
                        write (chr (7), 'new game?');
                        gotoxy (xOrg, succ (yOrg));
                        write ('[y/n]');
                        repeat
                            ch := upcase (getKey)
                        until ch in ['Y', 'N'];
                        
                        if ch = 'Y' then
                            begin
                                setInitPosition (board);
                                ClearUtilityMenu;
                                BoardDisplay (board);
                                utilDone := true
                            end
                    end;
                'E':
                    begin {exit game}
                        gotoxy(xOrg, yOrg);
                        write (chr(7), 'exit cart?');
                        gotoxy (xOrg, succ (yOrg));
                        write ('[y/n]');
                        repeat
                            ch := upcase (getKey)
                        until ch in ['Y', 'N'];
                        if ch = 'Y' then
                            halt;
                    end;
            end
        until utilDone
    end;

end.