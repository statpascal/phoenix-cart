unit pmove;

interface

uses globals, board;

procedure PlayerMove (var board: TBoardRecord; var playMove: TMoveRecord; var humanSide: integer);


implementation

uses trimprocs, utility;

const
    xOrg = 18;
    yOrg = 9;

procedure PlayerMove (var board: TBoardRecord; var playMove: TMoveRecord; var humanSide: integer);
    var 
        state, turn: integer;
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
        turn := sideToMove (board);
        
        repeat
            case state of
                0:
                    begin
                        square [0] := 0;
                        gotoxy (xOrg, yOrg);
                        write (chr (7), 'Enter move:');
                        showHChar (xOrg, succ (yOrg), 32, 8);
                        gotoxy (xOrg, succ (yOrg))
                    end;
                2:
                    begin
                        square [1] := 0;
                        gotoxy (xOrg + 3, succ (yOrg));
                        write ('to ')
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
                        Utility (humanSide, board);
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
        
        showHChar (xOrg, yOrg, 32, 31 - Xorg);
        showHChar (xOrg, succ (yOrg), 32, 31 - Xorg);
                        
        {promote pawn if applicable}
        if (playMove.pieceType = pawn) and (playMove.endSq in [0..7, 56..63]) then
            begin
                gotoxy (xOrg, yOrg);
                write ('promote pawn');
                gotoxy (xOrg, yOrg + 1);
                write('1- rook');
                gotoxy (xOrg, yOrg + 2);
                write ('2- knight');
                gotoxy (xOrg, yOrg + 3);
                write ('3- bishop');
                gotoxy (xOrg, yOrg + 4);
                write ('4- queen');
                repeat
                    key := GetKey
                until key in ['1'..'4'];
                playMove.flags := playMove.flags or (ord (key) - ord ('0')) shl 4
            end;
            
        // delete position/score while calculating
        showHChar (0, 22, 32, 64)

    end;

end.
