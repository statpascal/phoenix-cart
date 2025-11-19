unit resources;

interface

uses globals;

type 
    TBitboardType = (RookMove, KnightMove, BishopMove, QueenMove, KingMove, WhitePawnMove, WhitePawnCapture, BlackPawnMove, BlackPawnCapture);

function getMovementBitboard (bitboardType: TBitboardType; loc: integer): bitboard;
function getPieceLocationBitboard (loc: integer): bitboard;


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
    
end.
