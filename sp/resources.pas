unit resources;

interface

uses bitops;

function getPawnMovementBitboard (side: integer; loc: integer): bitboard;
function getPawnCaptureBitboard (side: integer; loc: integer): bitboard;
function getEnPassantBitboard (isBlack: boolean; col: integer): bitboard;

function getKnightMovementBitboard (loc: integer): bitboard;
function getKingMovementBitboard (loc: integer): bitboard;

type
    TPieceScoreType = (WhitePawnScore, BlackPawnScore, KnightScore, BishopScore, KingMidScore, KingEndScore);

function getPieceScoreValue (pieceScoreType: TPieceScoreType; loc: integer): integer;


implementation

{$ifdef ti99}
    
type
    TPieceMovementBitboard = array [0..63] of bitboard;

function getPawnMovementBitboard (side: integer; loc: integer): bitboard;
    procedure whitePawnMove; external '../resources/whitepawnmove.dat';
    procedure blackPawnMove; external '../resources/blackpawnmove.dat';
    begin
        if side = 0 then
            result := TPieceMovementBitboard (addr (whitePawnMove)) [loc]
        else
            result := TPieceMovementBitboard (addr (blackPawnMove)) [loc]
    end;

function getPawnCaptureBitboard (side: integer; loc: integer): bitboard;
    procedure whitePawnCapture; external '../resources/whitepawncapture.dat';
    procedure blackPawnCapture; external '../resources/blackpawncapture.dat';
    begin
        if side = 0 then
            result := TPieceMovementBitboard (addr (whitePawnCapture)) [loc]
        else
            result := TPieceMovementBitboard (addr (blackPawnCapture)) [loc]
    end;

function getKnightMovementBitboard (loc: integer): bitboard;
    procedure knightMove; external '../resources/knightmove.dat';
    begin
        result := TPieceMovementBitboard (addr (knightMove)) [loc]
    end;

function getKingMovementBitboard (loc: integer): bitboard;
    procedure kingMove; external '../resources/kingmove.dat';
    begin
        result := TPieceMovementBitboard (addr (kingMove)) [loc]
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
{$endif}

{$ifdef fpc}

uses resvals;

function getPawnMovementBitboard (side: integer; loc: integer): bitboard;
    begin
        if side = 0 then
            result := bitboard (whitePawnMove [loc])
        else
            result := bitboard (blackPawnMove [loc])
    end;

function getPawnCaptureBitboard (side: integer; loc: integer): bitboard;
    begin
        if side = 0 then
            result := bitboard (whitePawnCapture [loc])
        else
            result := bitboard (blackPawnCapture [loc])
    end;

function getKnightMovementBitboard (loc: integer): bitboard;
    begin
        result := bitboard (knightMove [loc])
    end;

function getKingMovementBitboard (loc: integer): bitboard;
    begin
        result := bitboard (kingMove [loc])
    end;
    
function getEnPassantBitboard (isBlack: boolean; col: integer): bitboard;
    begin
        result := bitboard (data_ep [isBlack, col])
    end;
    
function getPieceScoreValue (pieceScoreType: TPieceScoreType; loc: integer): integer;
    begin
        result := data_score [ord (pieceScoreType), loc]
    end;
{$endif}

end.
