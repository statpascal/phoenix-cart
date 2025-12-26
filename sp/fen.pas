unit fen;

interface

uses bitops, globals, logger;

procedure setFENPosition (var board: TBoardRecord; var gameSide, gameMove: integer; s: string);


implementation

procedure placePiece (var board: TBoardRecord; row, col: integer; piece: char);
    var
        s, pieceType: integer;
    begin
        for s := 0 to 1 do
            for pieceType := 0 to 5 do
                if piece = Figure [s, pieceType] then
                    setBit (board.sides [s].bitboards [pieceType], row * 8 + col)
   end;
    
procedure combineBoards (var side: TSideRecord; var res: bitboard);
    var
        i: integer;
    begin
        res := side.bitboards [0];
        for i := 1 to 5 do
            res := res or side.bitboards [i]
    end;

procedure setFENPosition (var board: TBoardRecord; var gameSide, gameMove: integer; s: string);
    var
        index, row, col, factor: integer;
        ch: char;
        
    procedure skipBlank;
        begin
            while (index < length (s)) and (s [index] = ' ') do
                inc (index)
        end;
        
    begin
        fillChar (board, sizeof (board), 0);
        row := 7;
        col := 0;
        index := 1;
        while s [index] <> ' ' do 
            begin
                ch := s [index];
                case ch of
                    '/':
                        begin
                            dec (row);
                            col := 0
                        end;
                    '1'..'8':
                        inc (col, ord (ch) - ord ('0'));
                    else
                        begin
                            placePiece (board, row, col, ch);
                            inc (col)
                        end
                end;
                inc (index)
            end;
        combineBoards (board.white, board.white.pieces);
        combineBoards (board.black, board.black.pieces);
        board.allpieces := board.white.pieces or board.black.pieces;
        
        skipBlank;
        gameSide := ord (s [index] = 'b');
        inc (index);
        
        skipBlank;
        while s [index] <> ' ' do
            begin
                case s [index] of 
                    'Q':
                        board.castleFlags := board.castleFlags or whiteLeftCastle;
                    'K':
                        board.castleFlags := board.castleFlags or whiteRightCastle;
                    'q':
                        board.castleFlags := board.castleFlags or blackLeftCastle;
                    'k':
                        board.castleFlags := board.castleFlags or blackRightCastle
                end;
                inc (index);
            end;
            
        skipBlank;
        if s [index] = '-' then
            inc (index)
        else
            begin
                col := ord (s [index]) - ord ('a');
                inc (index);
                row := ord (s [index]) - ord ('0');
                inc (index);
                if (col in [0..7]) and (row in [3, 7]) then
                    begin
                        board.castleFlags := board.castleFlags or epMoveFlag or col;
                        if row = 3 then
                            board.castleFlags := board.castleFlags or epWhiteFlag;
                    end
            end;
            
        // TODO: half move count
        index := length (s);
        gameMove := 0;
        factor := 1;
        while s [index] in ['0'..'9'] do
            begin
                inc (gameMove, factor * (ord (s [index]) - ord ('0')));
                factor := factor * 10;
                dec (index)
            end;
            
    end;
                
end.
