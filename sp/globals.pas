unit Globals;

interface

uses bitops
{$ifdef ti99}
, vdp
{$endif}
;

const    
    versionString = '2026';
    bitmasks: array [0..7] of uint8 = ($80, $40, $20, $10, $08, $04, $02, $01);
    maxPly = 9;
    MaxMoves = 20;	// max moves for hased openbook position

(* Encoding of book moves: 
   val shr 12 - weight
   (val shr 6) and 63 - start square
   val and 63 - end square
*)   
    
type
    TBookMoves = array [0..MaxMoves - 1] of integer;

    
var
//    gameMove: integer;
    gamePly: integer;
    moveNumHi, moveNumLo: integer;
    plyQS: integer;
    disableAlphaBetaPruning: boolean;
    darkMode: boolean;
    
procedure soundBell;	// TODO: move to standard runtime


implementation

var
    soundPort: byte absolute $8400;

procedure soundBell;
    var
        i: integer;
    begin
{$ifdef ti99}
        soundPort := $8e;
        soundPort := $0f;	// 440 Hz
        soundPort := $92;	// volume
        
        for i := 1 to 10 do
            repeat
            until ord (VDPSTA) and $80 <> 0;
            
        soundPort := $9f	// sound off
{$endif}
end;

begin
    disableAlphaBetaPruning := false
end.
