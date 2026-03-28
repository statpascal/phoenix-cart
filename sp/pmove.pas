unit pmove;

interface

uses globals, board;

procedure PlayerMove (var board: TBoardRecord; var playMove: TMoveRecord; turn: integer; var humanSide: integer);


implementation

uses trimprocs, ui, utility;

procedure PlayerMove (var board: TBoardRecord; var playMove: TMoveRecord; turn: integer; var humanSide: integer);
    var 
        state: integer;
        square: array [0..1] of integer;
        key: char;
        
    function readKey (state: integer): char;
        var
            validKey: set of char;
        begin
            if odd (state) then
                validKey := ['1'..'8', 'U', 'R']
            else
                validKey := ['A'..'H', 'U', 'R'];
            repeat
                result := upcase (GetKey)
            until result in validKey
        end;
                
    begin
        state := 0;
        
        repeat
            case state of
                0:
                    begin
                        square [0] := 0;
                        gotoxy (20, 6);
                        write (chr (7), 'enter move');
                        gotoxy (20, 7);
                        write ('from:           ');
                        gotoxy (26, 7)
                    end;
                2:
                    begin
                        square [1] := 0;
                        gotoxy (30, 7);
                        write ('to:   ');
                        gotoxy (34, 7)
                    end
            end;
                
            key := readKey (state);
            if not (key in ['U', 'R']) then 
                write (key);
            inc (state);
            case key of
                'R':
                    state := 0;
                'U':
                    begin
                        Utility (humanSide);
                        playMove.pieceType := InvalidPiece;
                        if humanSide <> turn then
                            exit;
                        state := 0
                    end;
                'A'..'H':
                    inc (square [pred (state) div 2], ord (key) - ord ('A'));
                '1'..'8':
                    inc (square [pred (state) div 2], 8 * (ord (key) - ord ('1')))
            end;
            
            case state of
                2:
                    if getBit (board.sides [turn].bitboards [SidePieces], square [0]) = 0 then
                        state := 0;
                4:
                    begin
                        playMove := makeMoveRecord (board, turn, square [0], square [1]);
                        if playMove.pieceType = InvalidPiece then
                            state := 2
                    end
            end
        until state = 4;
                        
        {promote pawn if applicable}
        if (playMove.pieceType = pawn) and (playMove.endSq in [0..7, 56..63]) then
            begin
                gotoxy (20, 8);
                writeln ('promote pawn to');
                gotoxy (22, 9);
                writeln ('1- rook');
                gotoxy (22, 10);
                writeln ('2- knight');
                gotoxy (22, 11);
                writeln ('3- bishop');
                gotoxy (22, 12);
                writeln ('4- queen');
                repeat
                    key := GetKey
                until key in ['1'..'4'];
                playMove.flags := playMove.flags or (ord (key) - ord ('0')) shl 4
            end

    end;

end.
