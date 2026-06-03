unit utility;

interface

uses board;

procedure saveGame (gname: string; showMsg: boolean);
procedure Utility (var humanSide: integer; var board: TBoardRecord);


implementation

uses globals, ui, logger;

(*
procedure UpdateBoard(gBase, gOffset: integer);
    var 
        offset: integer;
        buffer: array[0..59] of integer;

    begin
        startPage := gBase;
        dataSize := 120;
        offset := gOffset;
        DataOps(2, startPage, dataSize, offset, buffer);
        startPage := BASE;
        offset := WPO;
        DataOps(1, startPage, dataSize, offset, buffer);

        BoardDisplay;
        gotoxy(0, 2);
        if gameSide = 0 then
            write('turn: white')
        else
            write('turn: black');

        gotoxy(10, 1);
        write('move: ', gameMove);

        gotoxy(20, 1);
        if cWarning = 1 then
            write(chr(7), chr(7), 'check!')
        else
            write('      ');

        dataSize := 8;
    end;
*)    

const
    xOrg = 18;
    yOrg = 6;

procedure ClearUtilityMenu;
    var 
        i: integer;
    begin
        for i := 0 to 11 do
            showHChar (xOrg, yOrg + i, 32, 32 - xOrg)
    end;
    
procedure ShowUtilityMenu;
    var
        count: integer;

    procedure showLine (s: string);
        begin
            gotoxy (xOrg, yOrg + count);
            write (s);
            inc (count)
        end;
    
    begin
        count := 0;
        showLine (' : load game');
        showLine (' : save game');
        showLine (' : backup');
        showLine ('4: forward');
        showLine ('5: first move ');
        showLine (' : last move');
        showLine ('7: switch side');
        showLine ('8: change ply');
        showLine ('9: play');
        showLine ('N: new game');
        showLine ('P: print game');
        showLine ('0: exit')
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

procedure saveGame (gname: string; showMsg: boolean);
    begin    
    end;

procedure Utility (var humanSide: integer; var board: TBoardRecord);
    var 
        utilDone: boolean;
        ch: char;
        move: TMoveRecord;
        totalMoves, currentMove: integer;
    begin
        utilDone := false;
        totalMoves := getGameMoveCount;
        currentMove := totalMoves;

        repeat
            showUtilityMenu;
            repeat
                ch := upcase (getKey)
            until ch in ['0', '4'..'5', '7'..'9', 'N', 'P'];
            clearUtilityMenu;

            case ch of 
                'P': 
                    begin {print}
                        PrintGame;
                    end;
                '1': 
                    begin {load}
                    end;
                '2': 
                    begin {save}
                    end;
                '3':                 
                    begin {backup}
                    end;
                '4':
                    if currentMove < totalMoves then {forward}
                        begin 
                            move := getGameSavedMove (currentMove);
                            // unify with main
                            enterMoveSimple (board, move);
                            enterPositionHash (move, board.hash);
                            //                             
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
                    end;
                '7':
                    begin {switch sides}
                        humanSide := 1 - humanSide;
                        utilDone := true
                    end;
                '8':
                    begin {change ply}
                        repeat
                            gotoxy(xOrg, yOrg);
                            write(chr(7), 'ply: ');
                            readln(gamePly);
                        until gamePly in[1..6];
                        showPly
                    end;
                '9':
                    utilDone := true;
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
                        
                '0':
                    begin {end game}
                        gotoxy(xOrg, yOrg);
                        write (chr(7), 'end game?');
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