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
    epMoveFlag = 8;
    
    whiteLeftCastle = 16;
    whiteRightCastle = 32;
    blackLeftCastle = 64;
    blackRightCastle = 128;
    allCastleRights = whiteLeftCastle + whiteRightCastle + blackLeftCastle + blackRightCastle;
    
    moveBlackFlag = 256;
    
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
procedure setFENPosition (var board: TBoardRecord; var moveNr: integer; s: string);

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
    
procedure setSquare (var board: TBoardRecord; side, piece, square: integer);
    begin
        setBit (board.sides [side].bitboards [piece], square);
        setBit (board.sides [side].pieces, square);
        setBit (board.allPieces, square)
    end;
    
procedure clearCastleFlag (var board: TBoardRecord; flag: integer);
    begin
        board.flags := board.flags and not flag
    end;
    
procedure setCastleFlag (var board: TBoardRecord; flag: integer);
    begin
        board.flags := board.flags or flag
    end;
    
procedure clearEnPassantRights (var board: TBoardRecord);
    begin
        board.flags := board.flags and not (epMoveFlag + epColBitmask)
    end;
    
procedure setEnPassantRights (var board: TBoardRecord; col: integer);
    begin
        board.flags := board.flags or col or epMoveFlag;
    end;
    
procedure setMoveFlag (var board: TBoardRecord; side: integer);
    begin
        if side = 1 then
            board.flags := board.flags or moveBlackFlag
        else
            board.flags := board.flags and not moveBlackFlag
    end;
    
const 
    castleFlags: array [0..1, 0..1] of integer = ((whiteLeftCastle, whiteRightCastle), (blackLeftCastle, blackRightCastle));
    
procedure enterMove (turn: integer; isAttack: boolean; var capId: integer; var board: TBoardRecord; move: TMoveRecord);
        
    procedure castleRook (startSq, endSq: integer);
        begin
            clearSquare (board, turn, Rook, startSq);
            setSquare (board, turn, Rook, endSq)
        end;            
        
    begin
        clearEnPassantRights (board);
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
        setSquare (board, turn, move.pieceType, move.endSq);
            
        if (move.pieceType = Pawn) and (abs (move.startSq - move.endSq) = 16) then
            setEnPassantRights (board, move.startSq and 7);
        
        {handle castling move and rights}
        if move.pieceType = King then 
            begin
                if move.endSq = move.startSq + 2 then
                    castleRook (move.startSq or 7, move.endSq - 1)
                else if move.endSq = move.startSq - 2 then
                    castleRook (move.startSq and not 7, move.endSq + 1);
                clearCastleFlag (board, castleFlags [turn, 0]);
                clearCastleFlag (board, castleFlags [turn, 1])
            end;
            
        {check if rook is missing from start position}
        if board.flags and allCastleRights <> 0 then
            begin
                if getBit (board.white.rookBitBoard, 0) = 0 then
                    clearCastleFlag (board, whiteLeftCastle);
                if getBit (board.white.rookBitboard, 7) = 0 then
                    clearCastleFlag (board, whiteRightCastle);
                if getBit (board.black.rookBitBoard, 56) = 0 then
                    clearCastleFlag (board, blackLeftCastle);
                if getBit (board.black.rookBitboard, 63) = 0 then
                    clearCastleFlag (board, blackRightCastle)
            end;
            
        setMoveFlag (board, 1 - turn);
    end;    
    
procedure enterMoveSimple (turn: integer; var board: TBoardRecord; var move: TMoveRecord);
    var
        dummyId: integer;
    begin
        enterMove (turn, true, dummyId, board, move)
    end;
    
function checkCastleRights (var board: TBoardRecord; turn: integer): integer;
    var
        castleRights: integer;
        bits: bitboard;
        
    procedure checkBits (var bits: bitboard; row, mask0, mask1: integer);
        begin
            if bytearray (bits) [row] and mask0 <> 0 then
                castleRights := castleRights and not castleFlags [turn, 0];
            if bytearray (bits) [row] and mask1 <> 0 then
                castleRights := castleRights and not castleFlags [turn, 1]
        end;

    begin
        castleRights := board.flags and allCastleRights;
        if castleRights <> 0 then
            begin
                {check back row interposing pieces}
                checkBits (board.allPieces, 7 * turn, $70, $06);
                if castleRights and (castleFlags [turn, 0] or castleFlags [turn, 1]) <> 0 then
                    begin
                        {check for back row attack}
                        bits := combineTrimSide (turn = 0, board);
                        checkBits (bits, 7 * turn, $38, $0e)
                    end
            end;
        result := castleRights
    end;
    
procedure placePiece (var board: TBoardRecord; row, col: integer; piece: char);
    var
        side, pieceType: integer;
    begin
        for side := 0 to 1 do
            for pieceType := Pawn to King do
                if piece = Figure [side, pieceType] then
                    setSquare (board, side, pieceType, row * 8 + col)
   end;

procedure setFENPosition (var board: TBoardRecord; var moveNr: integer; s: string);
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
        
        skipBlank;
        setMoveFlag (board, ord (s [index] = 'b'));
        inc (index);
        
        skipBlank;
        while s [index] <> ' ' do
            begin
                case s [index] of 
                    'Q':
                        setCastleFlag (board, whiteLeftCastle);
                    'K':
                        setCastleFlag (board, whiteRightCastle);
                    'q':
                        setCastleFlag (board, blackLeftCastle);
                    'k':
                        setCastleFlag (board, blackRightCastle)
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
                    setEnPassantRights (board, col);
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
        setFENPosition (board, moveNr, 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
        side := 0;
    end;
           
end.