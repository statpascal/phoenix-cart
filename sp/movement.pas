unit movement;

interface

uses globals;

type 
    TBitboardType = (RookMove, KnightMove, BishopMove, QueenMove, KingMove, WhitePawnMove, WhitePawnCapture, BlackPawnMove, BlackPawnCapture);

function getMovementBitboard (bitboardType: TBitboardType; loc: integer): bitboard;


implementation

type
    TBitboardData = array [TBitboardType, 0..63] of bitboard;

function getMovementBitboard (bitboardType: TBitboardType; loc: integer): bitboard;

    procedure data; external '../resources/movement.dat';
    
    begin
        result := TBitboardData (addr (data)) [bitboardType, loc]
    end;
    
end.
