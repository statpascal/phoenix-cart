unit Globals;

interface

uses samsutil, vdp, bitops;

const 
//    BASE = 20;
//    BASE1 = 21;
//    BASE2 = 22;

    BASE = $2000;
    BASE1 = $3000;
    BASE2 = $A000;

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
//    EMPTYSQUARES = 120;
//    FILEMASK = 128;
    FILEBLANK = 192;
//    RANKMASK = 256;
//    RANKBLANK = 320;
    PIECELOC = 384;
    WPMOVE = 896;
    BPMOVE = 1344;
    KMOVE = 1792;
    NMOVE = 2304;
    QMOVE = 2816;
    RMOVE = 3328;
//    SIDES = 3840;
//    WPDOUBLE = 3848;
//    BPDOUBLE = 3856;
//    WEPFLAG = 3864;
//    BEPFLAG = 3872;
    WLBRMASK = 3886;		// f0 00 00 00 00 00 00 00
    WRBRMASK = 3894;		// 0f 00 00 00 00 00 00 00
    BLBRMASK = 3902;		// 00 00 00 00 00 00 00 f0
    BRBRMASK = 3910;		// 00 00 00 00 00 00 00 0f
    WRCMASK = 3918;		// 06 00 00 00 00 00 00 00 
    WLCMASK = 3926;		// 70 00 00 00 00 00 00 00
    BRCMASK = 3934;		// 00 00 00 00 00 00 00 06
    BLCMASK = 3942;		// 00 00 00 00 00 00 00 70
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
    EVALKNIGHT = 256;
    EVALBISHOP = 384;
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
    
const
    Pawn = 0;
    Rook = 8;
    Knight = 16;
    Bishop = 24;
    Queen = 32;
    King = 40;

type 
    listPointer = ^moverec;
    moverec = record
        id: integer;
        startSq: integer;
        endSq: integer;
        link: listPointer;
    end;

    TSideRecord = record
        case boolean of
            false: (pawnBitboard, rookBitboard, knightBitboard, bishopBitboard, queenBitboard, kingBitboard: bitboard);
            true:  (bitboards: array [0..5] of bitboard)
        end;
    
    TBoardRecord = record
        white, black: TSideRecord;
        allPieces, whitePieces, blackPieces: bitboard
    end;
    
const
    whiteCastleFlag = 1;
    blackCastleFlag = 2;    
    whiteRookLeftFlag = 4;
    whiteRookRightFlag = 8;
    blackRookLeftFlag = 16;
    blackRookRightFlag = 32;
    
    whiteLeftCastleRight = 1;
    whiteRightCastleRight = 2;
    blackLeftCastleRight = 4;
    blackRightCastleRight = 8;
    
var
    mainBoard: TBoardRecord absolute $2000;
    tempBoard: TBoardRecord absolute $2f6e;
    
    castleFlags: integer;

var 
    startPage, sPage, dataSize, turn, gameSide, gamePointer: integer;
    pieceCount, (* wCastleFlag, bCastleFlag, *) cWarning: integer;
    gamePly, wMobility, bMobility, gameMove, humanSide: integer;
//    wRAFlag, wLAFlag, bRAFlag, bLAFlag: integer;
//    wRookLFlag, wRookRFlag, bRookLFlag, bRookRFlag: integer;
    moveNumHi, moveNumLo: integer;
    bit1, bit2, bit3, bit4, bit5, bit6, bit7, bitRes: bitboard;
    buffer: array[0..59] of integer;
    
    doLogging: boolean;
    logFile: text;
    


procedure ClearBitboard (var bit1: bitboard);
function IsClear (var b: bitboard): boolean;

function GetKeyInt: integer;

function checkCastleRights (var board: TBoardRecord; castleFlags, turn: integer): integer;

implementation


uses trimprocs;

function checkCastleRights (var board: TBoardRecord; castleFlags, turn: integer): integer;
    var
        bits: bitboard;
        dummyMove: moverec;
    begin
        result := 0;
        if (turn = 0) and (castleFlags and whiteCastleFlag = 1) or
           (turn = 1) and (castleFlags and blackCastleFlag = 2) then
            exit;
            
        {check back row interposing pieces}
        if turn = 0 then 
            begin
                if (castleFlags and whiteRookLeftFlag = 0) and (board.allPieces [0] and $7000 = 0) then
                    result := whiteLeftCastleRight;
                if (castleFlags and whiteRookRightFlag = 0) and (board.allPieces [0] and $0600 = 0) then
                    result := result or whiteRightCastleRight
            end
        else
            begin
                if (castleFlags and blackRookLeftFlag = 0) and (board.allPieces [3] and $0007 = 0) then
                    result := blackLeftCastleRight;
                if (castleFlags and blackRookRightFlag = 0) and (board.allPieces [3] and $0006 = 0) then
                    result := result or blackRightCastleRight
            end;
        if result = 0 then
            exit;
            
        {check for back row attack and remove affected rights}
        fillChar (dummyMove, sizeof (dummyMove), 0);
        bits := combineTrimSide (turn = 0, dummyMove, board);
        if turn = 0 then
            begin
                if bits [0] and $f000 <> 0 then		// not correct - rook may be attacked
                    result := result and not whiteLeftCastleRight;
                if bits [0] and $0f00 <> 0 then
                    result := result and not whiteRightCastleRight
            end
        else
            begin
                if bits [3] and $00f0 <> 0 then
                    result := result and not blackLeftCastleRight;
                if bits [3] and $000f <> 0 then
                    result := result and not blackRightCastleRight
            end
    end;        
           

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

function IsClear(var b: bitboard): boolean; assembler;
        clr  r14
        mov  @b, r12
        mov  *r12+, r13
        soc  *r12+, r13
        soc  *r12+, r13
        soc  *r12, r13
        jne  isclear_done
        li   r14, >0100
    isclear_done:
        mov  *r10, r12
        movb r14, *r12
end;        

(*
    begin
        IsClear := b [0] or b [1] or b [2] or b [3] = 0
    end;
*)    


end.
