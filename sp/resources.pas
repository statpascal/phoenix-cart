unit resources;

interface

uses globals;

type 
    TBitboardType = (RookMove, KnightMove, BishopMove, QueenMove, KingMove, WhitePawnMove, WhitePawnCapture, BlackPawnMove, BlackPawnCapture);

function getMovementBitboard (bitboardType: TBitboardType; loc: integer): bitboard;
function getPieceLocationBitboard (loc: integer): bitboard;
function getEnPassantBitboard (isBlack: boolean; col: integer): bitboard;

function getInitPosition: TBoardRecord;

type
    TPieceScoreType = (WhitePawnScore, BlackPawnScore, KnightScore, BishopScore, KingMidScore, KingEndScore);

function getPieceScoreValue (pieceScoreType: TPieceScoreType; loc: integer): integer;


implementation

function getMovementBitboard (bitboardType: TBitboardType; loc: integer): bitboard;

    type
        TBitboardData = array [TBitboardType, 0..63] of bitboard;

    procedure data_move; external '../resources/movement.dat';
    
    begin
        result := TBitboardData (addr (data_move)) [bitboardType, loc]
    end;
    
function getPieceLocationBitboard (loc: integer): bitboard;

    type
        TBitboardData = array [0..63] of bitboard;

    procedure data_loc; external '../resources/pieceloc.dat';
    
    begin
        result := TBitboardData (addr (data_loc)) [loc]
    end;

function getEnPassantBitboard (isBlack: boolean; col: integer): bitboard;

    type
        TBitboardData = array [boolean, 0..7] of bitboard;
        
    procedure data_ep; external '../resources/enpassant.dat';
    
    begin
        result := TBitboardData (addr (data_ep)) [isBlack, col]
    end;
    
function getPieceScoreValue (pieceScoreType: TPieceScoreType; loc: integer): integer;

    type
        TPieceScoreData = array [TPieceScoreType, 0..63] of integer;
        
    procedure data_score; external '../resources/piecescore.dat';
    
    begin
        result := TPieceScoreData (addr (data_score)) [pieceScoreType, loc]
    end;
    
function getInitPosition: TBoardRecord;

    procedure data_init; external '../resources/initboard.dat';
    
    begin
        result := TBoardRecord (addr (data_init))
    end;
    
end.
