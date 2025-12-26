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

type
    TPieceMovementBitboard = array [0..63] of bitboard;

{$ifdef ti99}
    
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
    
end.
    
{$endif}

{$ifdef fpc}

type
    TBitboardData = array [boolean, 0..7] of bitboard;
    TPieceScoreData = array [TPieceScoreType, 0..63] of int16;
    
var
    whitePawnMove, blackPawnMove, whitePawnCapture, blackPawnCapture, 
    knightMove, kingMove: TPieceMovementBitboard;
    data_ep: TBitboardData;
    data_score: TPieceScoreData;

function getPawnMovementBitboard (side: integer; loc: integer): bitboard;
    begin
        if side = 0 then
            result := whitePawnMove [loc]
        else
            result := blackPawnMove [loc]
    end;

function getPawnCaptureBitboard (side: integer; loc: integer): bitboard;
    begin
        if side = 0 then
            result := whitePawnCapture [loc]
        else
            result := blackPawnCapture [loc]
    end;

function getKnightMovementBitboard (loc: integer): bitboard;
    begin
        result := knightMove [loc]
    end;

function getKingMovementBitboard (loc: integer): bitboard;
    begin
        result := kingMove [loc]
    end;
    
function getEnPassantBitboard (isBlack: boolean; col: integer): bitboard;
    begin
        result := data_ep [isBlack, col]
    end;
    
function getPieceScoreValue (pieceScoreType: TPieceScoreType; loc: integer): integer;
    begin
        result := swapEndian (data_score [pieceScoreType, loc])
    end;
    
procedure readRes (var buf; size: integer; fn: string);
    var
        f: file;
    begin
        assign (f, fn);
        reset (f, 1);
        blockread (f, buf, size);
        close (f)
    end;    
    
begin
    writeln ('Loading res');
    readRes (whitePawnMove, sizeof (whitePawnMove), 'resources/whitepawnmove.dat');
    readRes (blackPawnMove, sizeof (whitePawnMove), 'resources/blackpawnmove.dat');
    readRes (whitePawnCapture, sizeof (whitePawnCapture), 'resources/whitepawncapture.dat');
    readRes (blackPawnCapture, sizeof (blackPawnCapture), 'resources/blackpawncapture.dat');
    readRes (knightMove, sizeof (knightMove), 'resources/knightmove.dat');
    readRes (kingMove, sizeof (kingMove), 'resources/kingmove.dat');
    readRes (data_ep, sizeof (data_ep), 'resources/enpassant.dat');
    readRes (data_score, sizeof (data_score), 'resources/piecescore.dat');
    writeln ('res loaded');
end.
    


{$endif}
    
