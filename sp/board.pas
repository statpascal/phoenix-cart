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

function findPieceType (var board: TBoardRecord; turn, square: integer): integer;
procedure enterMove (turn: integer; isAttack: boolean; var capId: integer; var board: TBoardRecord; move: TMoveRecord);
procedure enterMoveSimple (turn: integer; var board: TBoardRecord; var move: TMoveRecord);

procedure combinePieces (var board: TBoardRecord);
procedure compressBoard (var board: TBoardRecord; var res: TCompressedBoard);
procedure inflateBoard (var compressed: TCompressedBoard; var res: TBoardRecord);

implementation

uses trimprocs, resources;

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
{$ifdef ti99}
    { load relevant movement boards locally }
    procedure ext_pancapture_1; external '../resources/pawncapture.dat';
    procedure ext_knightmove_1; external '../resources/knightmove.dat';
    procedure ext_kingmove_1; external '../resources/kingmove.dat';

    var
        pawnCaptureBitboards: TPawnBitboards absolute ext_pancapture_1;
        knightMovementBitboards: TPieceBitboards absolute ext_knightmove_1;
        kingMovementBitboards: TPieceBitboards absolute ext_kingmove_1;
{$endif}

    var
        posArray: bitarray;
        kingPos: integer;
        bits, bitsOpponent: bitboard;
        
    begin
        {check if own king attacked by opposite trim board}
//        res := board.sides [turn].kingBitboard and combineTrimSide (turn = 0, board);
//        isKingChecked := not isClear (res);
        
        result := true;
        BitPos (board.sides [turn].kingBitboard, posArray);
        kingPos := posArray [1];
        
        {impersonate all piece types and check if opoonent piece of same type can be captured}
        bitsOpponent := board.sides [1 - turn].bishopBitboard or board.sides [1 - turn].queenBitboard;
        if not isClear (bitsOpponent) then
            begin        
                bits := makeMovementBitboard (kingPos, Bishop, board.sides [turn].pieces, board.sides [1 - turn].pieces) and bitsOpponent;
                if not isClear (bits) then
                    exit
            end;
            
        bitsOpponent := board.sides [1 - turn].rookBitboard or board.sides [1 - turn].queenBitboard;
        if not isClear (bitsOpponent) then
            begin
                bits := makeMovementBitboard (kingPos, Rook, board.sides [turn].pieces, board.sides [1 - turn].pieces) and bitsOpponent;
                if not isClear (bits) then
                    exit
            end;

        bits := knightMovementBitboards [kingPos] and board.sides [1 - turn].knightBitboard;
        if not isClear (bits) then
            exit;
        
        bits := pawnCaptureBitboards [turn, kingPos] and board.sides [1 - turn].pawnBitboard;
        if not isClear (bits) then
            exit;
            
        bits := kingMovementBitboards [kingPos] and board.sides [1 - turn].kingBitboard;
        if not isClear (bits) then
            exit;
            
        result := false
    end;

function findPieceType (var board: TBoardRecord; turn, square: integer): integer;
    begin
        result := Pawn;
        repeat
            if getBit (board.sides [turn].bitboards [result], square) <> 0 then
                exit;
            inc (result)
        until result = InvalidPiece
    end;
    
procedure clearSquare (var board: TBoardRecord; side, piece, square: integer);
    begin
        clearBit (board.sides [side].bitboards [piece], square);
        clearBit (board.sides [side].pieces, square);
        clearBit (board.allPieces, square)
    end;
    
procedure enterSquare (var board: TBoardRecord; side, piece, square: integer);
    begin
        setBit (board.sides [side].bitboards [piece], square);
        setBit (board.sides [side].pieces, square);
        setBit (board.allPieces, square)
    end;
        
procedure enterMove (turn: integer; isAttack: boolean; var capId: integer; var board: TBoardRecord; move: TMoveRecord);
        
    procedure castleRook (startSq, endSq: integer);
        begin
            clearSquare (board, turn, Rook, startSq);
            enterSquare (board, turn, Rook, endSq)
        end;            
        
    begin
        board.flags := board.flags and not (epMoveFlag + epWhiteFlag + epColBitmask + moveBlackFlag);
        clearSquare (board, turn, move.pieceType, move.startSq);
        
        {remove attacked piece from opponent's bitboards}
        if isAttack then
            begin
                capId := findPieceType (board, 1 - turn, move.endSq);
                if capId <> InvalidPiece then
                    clearSquare (board, 1 - turn, capId, move.endSq)
                else if (move.pieceType = Pawn) and (abs (move.startSq - move.endSq) in [7, 9]) then
                    begin
                        {en passant capture handling}
                        clearSquare (board, 1 - turn, Pawn, move.endSq - 8 + 16 * (turn and 1));
                        capId := pawn
                    end
            end;

        {place piece at end position}
        if (move.pieceType = Pawn) and (move.endSq in [0..7, 56..63]) then
            begin
                move.pieceType := move.flags shr 4;
                if move.pieceType = 0 then
                    move.pieceType := Queen
            end;
        enterSquare (board, turn, move.pieceType, move.endSq);
            
        {set EP rights in board}  
        if (move.pieceType = Pawn) and (abs (move.startSq - move.endSq) = 16) then
            begin
                board.flags := board.flags or (move.startSq and 7) or epMoveFlag;
                if move.endSq in [24..31] then 
                    board.flags := board.flags or epWhiteFlag
            end;
        
        {handle castling move and rights}
        if move.pieceType = King then 
            begin
                if move.endSq = move.startSq + 2 then
                    castleRook (move.startSq or 7, move.endSq - 1)
                else if move.endSq = move.startSq - 2 then
                    castleRook (move.startSq and not 7, move.endSq + 1);
                if turn = 0 then
                    board.flags := board.flags and not (whiteLeftCastle or whiteRightCastle)
                else
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