unit board;

interface

uses bitops;

const

    (* Board flags *)

    Pawn = 0;
    Rook = 1;
    Knight = 2;
    Bishop = 3;
    Queen = 4;
    King = 5;
    SidePieces = 6;	// board index for combined side bitboard
    InvalidPiece = 6;

    epColBitmask = 7;
    epWhiteFlag = 8;
    epMoveFlag = 16;
    
    whiteLeftCastle = 32;
    whiteRightCastle = 64;
    blackLeftCastle = 128;
    blackRightCastle = 256;
    
    moveBlackFlag = 512;
    
    (* Move Flags *)
    
    AttackMove = 1;

    Figure: array [0..1, 0..5] of char = (('P', 'R', 'N', 'B', 'Q', 'K'),
                                          ('p', 'r', 'n', 'b', 'q', 'k'));
    

type
    TMoveRecord = packed record
        startSq, endSq: uint8;
        pieceType: uint8;	// moved piece
        flags: uint8		// high nibble: pawn promotion piece
    end;
    
    TMoveScoreRecord = packed record
        score: integer;
        move: TMoveRecord
    end;

    TSideRecord = record
        case boolean of
            false: (pawnBitboard, rookBitboard, knightBitboard, bishopBitboard, queenBitboard, kingBitboard, pieces: bitboard);
            true:  (bitboards: array [0..6] of bitboard)
    end;
    
    TBoardRecord = record
        flags: int16;
        allPieces: bitboard;
        case boolean of
            false: (white, black: TSideRecord);
            true:  (sides: array [0..1] of TSideRecord)
    end;
    
    TCompressedBoard = packed record
        board: bitboard;	         // all pieces
        pieces: array [0..15] of uint8;	 // color/piece type for bits in board (4 bit per position)
        flags: int16;			 // EP/castling flag
    end;

procedure setInitPosition (var board: TBoardRecord; var side, moveNr: integer);
procedure setFENPosition (var board: TBoardRecord; var side, moveNr: integer; s: string);

function checkCastleRights (var board: TBoardRecord; turn: integer): integer;
function isKingChecked (turn: integer; var board: TBoardRecord): boolean;

function findPieceType (var board: TBoardRecord; turn, pos: integer): integer;
procedure enterMove (turn: integer; isAttack: boolean; var capId: integer; var board: TBoardRecord; var move: TMoveRecord);
procedure enterMoveSimple (turn: integer; var board: TBoardRecord; var move: TMoveRecord);

procedure combinePieces (var board: TBoardRecord);
procedure compressBoard (var board: TBoardRecord; var res: TCompressedBoard);
procedure inflateBoard (var compressed: TCompressedBoard; var res: TBoardRecord);

implementation

uses trimprocs;

procedure combinePieces (var board: TBoardRecord);
    var
        s, i: integer;
    begin
        for s := 0 to 1 do
            begin
                board.sides [s].bitboards [sidePieces] := board.sides [s].bitboards [Pawn];
                for i := Rook to King do
                    board.sides [s].bitboards [sidePieces] := board.sides [s].bitboards [sidePieces] or board.sides [s].bitboards [i]
            end;
        board.allPieces := board.white.pieces or board.black.pieces
    end;                            

procedure compressBoard (var board: TBoardRecord; var res: TCompressedBoard);
    var
        position: bitarray;
        i, square, piece: integer;
    begin
        res.board := board.allpieces;
{$ifdef ti99}        
        res.flags := board.flags;
{$endif}
{$ifdef fpc}
        res.flags := swapEndian (board.flags);
{$endif}
        fillChar (res.pieces, sizeof (res.pieces), 0);
        
        BitPos (res.board, position);
        for i := 1 to position [0] do
            begin
                square := position [i];
                piece := findPieceType (board, 0, square);
                if piece = InvalidPiece then
                    piece := findPieceType (board, 1, square) or 8;
                if odd (i) then
                    res.pieces [pred (i) shr 1] := piece shl 4
                else
                    res.pieces [pred (i) shr 1] := res.pieces [pred (i) shr 1] or piece
            end
    end;
    
procedure inflateBoard (var compressed: TCompressedBoard; var res: TBoardRecord);
    var
        position: bitarray;
        i, piece: integer;
    begin
        fillchar (res, sizeof (res), 0);
{$ifdef ti99}
        res.flags := compressed.flags;
{$endif}
{$ifdef fpc}        
        res.flags := swapEndian (compressed.flags);
{$endif}
        BitPos (compressed.board, position);
        for i := 1 to position [0] do
            begin
                if odd (i) then 
                    piece := (compressed.pieces [pred (i) shr 1] shr 4) and $f
                else
                    piece := compressed.pieces [pred (i) shr 1] and $f;
                setBit (res.sides [ord (piece and 8 <> 0)].bitboards [piece and 7], position [i])
            end;
        combinePieces (res)
    end;        
                    
function isKingChecked (turn: integer; var board: TBoardRecord): boolean;
    var
        res: bitboard;
    begin
        {check if own king attacked by opposite trim board}
        res := board.sides [turn].kingBitboard and combineTrimSide (turn = 0, board);
        isKingChecked := not isClear (res)
    end;

function findPieceType (var board: TBoardRecord; turn, pos: integer): integer;
    var
        pieceType: integer;
    begin
        for pieceType := Pawn to King do
            if getBit (board.sides [turn].bitboards [pieceType], pos) <> 0 then
                begin
                    findPieceType := pieceType;
                    exit
                end;
        findPieceType := InvalidPiece
    end;
        
procedure enterMove (turn: integer; isAttack: boolean; var capId: integer; var board: TBoardRecord; var move: TMoveRecord);
        
    procedure updateBitboards (var own, opponent: TSideRecord; var ownPieces, opponentPieces: bitboard; id, startSq, endSq, flags: integer);
        var
            foundFlag: boolean;
            epSquare: integer;
            j: integer;
        begin
            {erase piece at starting position}
            clearBit (board.allPieces, startSq);
            clearBit (ownPieces, startSq);
            clearBit (own.bitboards [id], startSq);
            
            {remove attacked piece from opponent's bitboards}
            foundFlag := false;
            if isAttack then
                begin
                    j := Pawn;
                    repeat
                        if getBit (opponent.bitboards [j], endSq) <> 0 then
                            begin
                                foundFlag := true;
                                capId := j;
                                clearBit (opponent.bitboards [j], endSq);
                                clearBit (opponentPieces, endSq)
                            end;
                        inc (j)
                    until (foundFlag) or (j > King);

                    {en passant capture handling}
                    if not foundFlag and (id = Pawn) and (abs (startSq - endSq) in [7, 9]) then
                        begin
                            if turn = 0 then
                                epSquare := endSq - 8
                            else
                                epSquare := endSq + 8;
                            clearBit (opponent.pawnBitboard, epSquare);
                            clearBit (opponentPieces, epSquare);
                            clearBit (board.allPieces, epSquare);
                            capId := pawn
                        end
                end;

            {place piece at end position}
            setBit (board.allPieces, endSq);
            setBit (ownPieces, endSq);
            if (id = Pawn) and (endSq in [0..7, 56..63]) then
                if flags shr 4 <> 0 then
                    setBit (own.bitboards [flags shr 4], endSq)
                else
                    setBit (own.queenBitboard, endSq)
            else
                setBit (own.bitboards [id], endSq);
              
            {set EP rights in board}  
            if (id = Pawn) and (abs (startSq - endSq) = 16) then
                begin
                    board.flags := board.flags or (startSq and 7) or epMoveFlag;
                    if endSq in [24..31] then 
                        board.flags := board.flags or epWhiteFlag
                end
        end;
    
    begin
        board.flags := board.flags and not (epMoveFlag + epWhiteFlag + epColBitmask + moveBlackFlag);
        if turn = 0 then
            begin
                updateBitboards (board.white, board.black, board.white.pieces, board.black.pieces, move.pieceType, move.startSq, move.endSq, move.flags);
                if (move.pieceType = King) and (move.startSq = 4) and (move.endSq = 6) then
                    updateBitboards (board.white, board.black, board.white.pieces, board.black.pieces, Rook, 7, 5, 0);
                if (move.pieceType = King) and (move.startSq = 4) and (move.endSq = 2) then
                    updateBitboards (board.white, board.black, board.white.pieces, board.black.pieces, Rook, 0, 3, 0);
                if move.pieceType = King then
                    board.flags := board.flags and not (whiteLeftCastle or whiteRightCastle);
                board.flags := board.flags or moveBlackFlag;
            end
        else
            begin
                updateBitboards (board.black, board.white, board.black.pieces, board.white.pieces, move.pieceType, move.startSq, move.endSq, move.flags);
                if (move.pieceType = King) and (move.startSq = 60) and (move.endSq = 58) then
                    updateBitboards (board.black, board.white, board.black.pieces, board.white.pieces, Rook, 56, 59, 0);
                if (move.pieceType = King) and (move.startSq = 60) and (move.endSq = 62) then
                    updateBitboards (board.black, board.white, board.black.pieces, board.white.pieces, Rook, 63, 61, 0);
                if move.pieceType = King then
                    board.flags := board.flags and not (blackLeftCastle or blackRightCastle)
            end;
        if getBit (board.white.rookBitBoard, 0) = 0 then
            board.flags := board.flags and not whiteLeftCastle;
        if getBit (board.white.rookBitboard, 7) = 0 then
            board.flags := board.flags and not whiteRightCastle;
        if getBit (board.black.rookBitBoard, 56) = 0 then
            board.flags := board.flags and not blackLeftCastle;
        if getBit (board.black.rookBitboard, 63) = 0 then
            board.flags := board.flags and not blackRightCastle
    end;    
    
procedure enterMoveSimple (turn: integer; var board: TBoardRecord; var move: TMoveRecord);
    var
        dummyId: integer;
    begin
        enterMove (turn, true, dummyId, board, move)
    end;
    
function checkCastleRights (var board: TBoardRecord; turn: integer): integer;
    var
        bits: bitboard;
    begin
        result := board.flags;
            
        {check back row interposing pieces}
        if turn = 0 then 
            begin
                if bytearray (board.allPieces) [0] and $70 <> 0 then
                    result := result and not whiteLeftCastle;
                if bytearray (board.allPieces) [0] and $06 <> 0 then
                    result := result and not whiteRightCastle;
                if result and (whiteLeftCastle or whiteRightCastle) = 0 then
                   exit
            end
        else
            begin
                if bytearray (board.allPieces) [7] and $70 <> 0 then
                    result := result and not blackLeftCastle;
                if bytearray (board.allPieces) [7] and $06 <> 0 then
                    result := result and not blackRightCastle;
                if result and (blackLeftCastle or blackRightCastle) = 0 then
                    exit
            end;
            
        {check for back row attack and remove affected rights}
        bits := combineTrimSide (turn = 0, board);
        if turn = 0 then
            begin
                if bytearray (bits) [0] and $38 <> 0 then		// not correct - rook may be attacked
                    result := result and not whiteLeftCastle;
                if bytearray (bits) [0] and $0e <> 0 then
                    result := result and not whiteRightCastle
            end
        else
            begin
                if bytearray (bits) [7] and $38 <> 0 then
                    result := result and not blackLeftCastle;
                if bytearray (bits) [7] and $0e <> 0 then
                    result := result and not blackRightCastle
            end
    end;        
    
procedure placePiece (var board: TBoardRecord; row, col: integer; piece: char);
    var
        s, pieceType: integer;
    begin
        for s := 0 to 1 do
            for pieceType := 0 to 5 do
                if piece = Figure [s, pieceType] then
                    setBit (board.sides [s].bitboards [pieceType], row * 8 + col)
   end;

procedure setFENPosition (var board: TBoardRecord; var side, moveNr: integer; s: string);
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
        combinePieces (board);
(*        
        combineBoards (board.white, board.white.pieces);
        combineBoards (board.black, board.black.pieces);
        board.allpieces := board.white.pieces or board.black.pieces;
*)        
        
        skipBlank;
        side := ord (s [index] = 'b');
        if side = 1 then 
            board.flags := board.flags or moveBlackFlag;
        inc (index);
        
        skipBlank;
        while s [index] <> ' ' do
            begin
                case s [index] of 
                    'Q':
                        board.flags := board.flags or whiteLeftCastle;
                    'K':
                        board.flags := board.flags or whiteRightCastle;
                    'q':
                        board.flags := board.flags or blackLeftCastle;
                    'k':
                        board.flags := board.flags or blackRightCastle
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
                        board.flags := board.flags or epMoveFlag or col;
                        if row = 3 then
                            board.flags := board.flags or epWhiteFlag;
                    end
            end;
            
        // TODO: half move count
        index := length (s);
        moveNr := 0;
        factor := 1;
        while s [index] in ['0'..'9'] do
            begin
                inc (moveNr, factor * (ord (s [index]) - ord ('0')));
                factor := factor * 10;
                dec (index)
            end;
            
    end;

procedure setInitPosition (var board: TBoardRecord; var side, moveNr: integer);
    begin    
        setFENPosition (board, side, moveNr, 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
    end;
           
end.