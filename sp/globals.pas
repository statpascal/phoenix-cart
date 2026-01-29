unit Globals;

interface

uses bitops
{$ifdef ti99}
, vdp
{$endif}
;

const    
    versionString = '2026-01-30-17-00';
    bitmasks: array [0..7] of uint8 = ($80, $40, $20, $10, $08, $04, $02, $01);
    maxPly = 9;
    
var
    gameMove: integer;
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
