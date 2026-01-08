unit Globals;

interface

uses bitops
{$ifdef ti99}
, vdp
{$endif}
;

const    
    versionString = '2026-01-03-15-30';
    bitmasks: array [0..7] of uint8 = ($80, $40, $20, $10, $08, $04, $02, $01);
    maxPly = 9;
    
var
    gameSide: integer;
    pieceCount, cWarning: integer;
    gamePly, gameMove, humanSide: integer;
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
