unit Globals;

interface

uses bitops
{$ifdef ti99}
, vdp
{$endif}
;

const    
    versionString = '2026-06-02-19-00';
    bitmasks: array [0..7] of uint8 = ($80, $40, $20, $10, $08, $04, $02, $01);
    maxPly = 9;
    MaxMoves = 20;	// max moves for hased openbook position
    
type
    TBookMoves = array [0..MaxMoves - 1] of integer;
    
var
//    gameMove: integer;
    gamePly: integer;
    moveNumHi, moveNumLo: integer;
    plyQS: integer;
    disableAlphaBetaPruning: boolean;
    
procedure soundBell;


implementation

procedure soundBell;
    begin
        // TODO
    end;

begin
    disableAlphaBetaPruning := false
end.
