unit Globals;

interface

uses samsutil, vdp, bitops;

const 
    BASE = 20;
    BASE1 = 21;
    BASE2 = 22;
 {BASE3 = 23;}
    BASE4 = 24;
    WPO = 0; {BASE}
    WRO = 8;
    WNO = 16;
    WBO = 24;
    WQO = 32;
    WKO = 40;
    BPO = 48;
    BRO = 56;
    BNO = 64;
    BBO = 72;
    BQO = 80;
    BKO = 88;
    APIECES = 96;
    WPIECES = 104;
    BPIECES = 112;
    EMPTYSQUARES = 120;
    FILEMASK = 128;
    FILEBLANK = 192;
    RANKMASK = 256;
    RANKBLANK = 320;
    PIECELOC = 384;
    WPMOVE = 896;
    BPMOVE = 1344;
    KMOVE = 1792;
    NMOVE = 2304;
    QMOVE = 2816;
    RMOVE = 3328;
    SIDES = 3840;
    WPDOUBLE = 3848;
    BPDOUBLE = 3856;
    WEPFLAG = 3864;
    BEPFLAG = 3872;
    WLBRMASK = 3886;
    WRBRMASK = 3894;
    BLBRMASK = 3902;
    BRBRMASK = 3910;
    WRCMASK = 3918;
    WLCMASK = 3926;
    BRCMASK = 3934;
    BLCMASK = 3942;
    TWPO = 3950;
    TWRO = 3958;
    TWNO = 3966;
    TWBO = 3974;
    TWQO = 3982;
    TWKO = 3990;
    TBPO = 3998;
    TBRO = 4006;
    TBNO = 4014;
    TBBO = 4022;
    TBQO = 4030;
    TBKO = 4038;
    TAPIECES = 4046;
    TWPIECES = 4054;
    TBPIECES = 4062;
    BMOVE = 0; {BASE 1}
    WPDIAG = 512;
    BPDIAG = 960;
    WEP = 1408;
    BEP = 1472;
    WEPSTORE = 1536;
    BEPSTORE = 1616;
    PLYBOARDS = 1856;
    WPAWN = 0; {BASE 2}
    BPAWN = 128;
    KNIGHT = 256;
    BISHOP = 384;
    KINGMID = 512;
    KINGEND = 640;
    KINGEDGE = 768;
    SWPO = 776;
    SWRO = 784;
    SWNO = 792;
    SWBO = 800;
    SWQO = 808;
    SWKO = 816;
    SBPO = 824;
    SBRO = 832;
    SBNO = 840;
    SBBO = 848;
    SBQO = 856;
    SBKO = 864;
    SAPIECES = 872;
    SWPIECES = 880;
    SBPIECES = 888;
    PLAYLIST = 896;
 (*OPENLIB = 0; {BASE 3}*)
    GAMESTORE = 0; {BASE 4}

type 
    // byte = 0..255;

    dual = record
        case boolean of 
            TRUE: (value: integer);
            FALSE: (bytes: array[0..1] of byte);
    end;

    listPointer = ^moverec;
    moverec = record
        id: integer;
        startSq: integer;
        endSq: integer;
        link: listPointer;
    end;


var 
    startPage, sPage, dataSize, turn, gameSide, gamePointer: integer;
    pieceCount, wCastleFlag, bCastleFlag, cWarning: integer;
    gamePly, wMobility, bMobility, gameMove, humanSide: integer;
    wRAFlag, wLAFlag, bRAFlag, bLAFlag: integer;
    wRookLFlag, wRookRFlag, bRookLFlag, bRookRFlag: integer;
    moveNumHi, moveNumLo: integer;
    bit1, bit2, bit3, bit4, bit5, bit6, bit7, bitRes: bitboard;
    buffer: array[0..59] of integer;
    
    doLogging: boolean;
    logFile: text;

procedure ClearBitboard(var bit1: bitboard);
function IsClear(var b: bitboard): boolean;
procedure BitDisp(var bit1: bitboard);

function GetKeyInt: integer;


implementation

function getKeyInt: integer;
    begin
        getKeyInt := ord (upcase (getkey ()))
    end;

procedure ClearBitboard(var bit1: bitboard);
    var 
        i: integer;
    begin
        for i := 0 to 3 do
            bit1[i] := 0;
    end; 

(*
function IsClear(var bit1: bitboard): boolean;
    var 
        i, flag: integer;
    begin
        flag := 0;
        IsClear := TRUE;
        for i := 0 to 3 do
            if bit1[i] <> 0 then
                flag := 1;

        if flag <> 0 then
            IsClear := FALSE;
    end;
*)    

function IsClear(var b: bitboard): boolean;
    begin
        IsClear := b [0] or b [1] or b [2] or b [3] = 0
    end;


procedure BitDisp(var bit1: bitboard);
    var 
        i, j, k, bitPos: integer;
        bitVal: dual;
    begin
        gotoxy(0, 14);
        bitPos := 256;
        for i := 3 downto 0 do
            begin
                bitVal.value := bit1[i];
                for j := 1 downto 0 do
                    begin
                        for k := 0 to 7 do
                            begin
                                bitPos := bitPos div 2;
                                if ord (odd(bitVal.bytes[j]) and odd(bitPos)) <> 0 then
                                    write('1')
                                else
                                    write('0');
                            end;
                        writeln;
                        bitPos := 256;
                    end;
            end;
    end;

end.
