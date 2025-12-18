unit fen;

interface

uses globals;

procedure setFENPosition (var board: TBoardRecord; var gameSide, gameMove: integer; s: string);


implementation

procedure placePiece (var board: TBoardRecord; row, col: integer; piece: char);
    var
        s, pieceType: integer;
    begin
        for s := 0 to 1 do
            for pieceType := 0 to 5 do
                if piece = Figure [s, pieceType] then
                    setBit (board.side [s].bitboards [pieceType], row * 8 + col)
   end;
    
procedure combineBoards (var side: TSideRecord; var res: bitboard);
    var
        i: integer;
    begin
        res := side.bitboards [0];
        for i := 1 to 5 do
            BitOr (res, side.bitboards [i], res)
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
        BitOr (board.white.pieces, board.black.pieces, board.allpieces);
        
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
            
        // TODO: ep, half move count
        index := length (s);
        gameMove := 0;
        factor := 1;
        while s [index] in ['0'..'9'] do
            begin
                inc (gameMove, factor * (ord (s [index]) - ord ('0')));
                factor := factor * 10;
                dec (index)
            end
                
    end;
                
end.
