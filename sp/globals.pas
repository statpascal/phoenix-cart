unit Globals;

interface

uses samsutil, vdp, bitops;

const
    Pawn = 0;
    Rook = 8;
    Knight = 16;
    Bishop = 24;
    Queen = 32;
    King = 40;
    InvalidPiece = 99;

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
        allPieces, whitePieces, blackPieces: bitboard;
        castleFlags: integer;
    end;
    
var
    (* turn, *) gameSide, gamePointer: integer;
    pieceCount, cWarning: integer;
    gamePly, gameMove, humanSide: integer;
    moveNumHi, moveNumLo: integer;
    
    doLogging: boolean;
    logFile: text;
    

procedure ClearBitboard (var bit1: bitboard);
function IsClear (var b: bitboard): boolean;

function GetKeyInt: integer;

function checkCastleRights (var board: TBoardRecord; turn: integer): integer;
function isKingChecked (turn: integer; var board: TBoardRecord): boolean;

procedure enterMove (turn, attackFlag: integer; var attackId, capId: integer; var foundFlag: boolean; var board: TBoardRecord; var move: moverec);
procedure enterMoveSimple (turn: integer; var board: TBoardRecord; var move: moverec);

procedure soundBell;

implementation


uses trimprocs;

procedure soundBell;
    begin
        // TODO
    end;

function isKingChecked (turn: integer; var board: TBoardRecord): boolean;
    var
        dummyMove: moverec;
        bit1, bit3, bit5: bitboard;
    begin
        {ignore en passant - cannot affect king}
        fillchar (dummyMove, sizeof (dummyMove), 0);
        CombineTrim(bit3, bit5, dummyMove, board);
        
        {check if own king attacked by opposite trim board}
        if turn = 0 then
            bit1 := board.white.kingBitboard
        else
            bit1 := board.black.kingBitboard;
        
        if turn = 0 then
            BitAnd(bit1, bit5, bit1)
        else
            BitAnd(bit1, bit3, bit1);
        isKingChecked := not isClear (bit1)
    end;
    


procedure enterMove (turn, attackFlag: integer; var attackId, capId: integer; var foundFlag: boolean; var board: TBoardRecord; var move: moverec);
        
    procedure updateBitboards (var own, opponent: TSideRecord; var ownPieces, opponentPieces: bitboard; id, startSq, endSq: integer);
        var
            epSquare: integer;
            i, j: integer;
        begin
            {erase piece at starting position}
            clearBit (board.allPieces, startSq);
            clearBit (ownPieces, startSq);
            clearBit (own.bitboards [id shr 3], startSq);
            
            {remove attacked piece from opponent's bitboards}
            foundFlag := false;
            if attackFlag = 1 then
                begin
                    j := 0;
                    repeat
                        if getBit (opponent.bitboards [j shr 3], endSq) <> 0 then
                            begin
                                foundFlag := true;
                                attackId := id;
                                capId := j;
                                clearBit (opponent.bitboards [j shr 3], endSq);
                                clearBit (opponentPieces, endSq)
                            end;
                        j := j + 8;
                    until (foundFlag) or (j > 40);

                    {en passant capture handling}
                    if not foundFlag and (id = 0) and (abs (startSq - endSq) in [7, 9]) then
                        begin
                            if turn = 0 then
                                epSquare := endSq - 8
                            else
                                epSquare := endSq + 8;
                            clearBit (opponent.pawnBitboard, epSquare);
                            clearBit (opponentPieces, epSquare);
                            clearBit (board.allPieces, epSquare);
                        end
                end;

            {place piece at end position}
            setBit (board.allPieces, endSq);
            setBit (ownPieces, endSq);
            if (id = 0) and (endSq in [0..7, 56..63]) then
                setBit (own.queenBitboard, endSq)
            else
                setBit (own.bitboards [id shr 3], endSq)
        end;
    
    begin
        if turn = 0 then
            begin
                updateBitboards (board.white, board.black, board.whitePieces, board.blackPieces, move.id, move.startsq, move.endsq);
                if (move.id = King) and (move.startSq = 4) and (move.endSq = 6) then
                    updateBitboards (board.white, board.black, board.whitePieces, board.blackPieces, Rook, 7, 5);
                if (move.id = King) and (move.startSq = 4) and (move.endSq = 2) then
                    updateBitboards (board.white, board.black, board.whitePieces, board.blackPieces, Rook, 0, 3);
                if getBit (board.white.rookBitBoard, 0) = 0 then
                    board.castleFlags := board.castleFlags or whiteRookLeftFlag;
                if getBit (board.white.rookBitboard, 7) = 0 then
                    board.castleFlags := board.castleFlags or whiteRookRightFlag;
                if (move.id = King) or (board.castleFlags and (whiteRookLeftFlag or whiteRookRightFlag) = (whiteRookLeftFlag or whiteRookRightFlag)) then
                    board.castleFlags := board.castleFlags or whiteCastleFlag;
            end
        else
            begin
                updateBitboards (board.black, board.white, board.blackPieces, board.whitePieces, move.id, move.startsq, move.endsq);
                if (move.id = King) and (move.startSq = 60) and (move.endSq = 58) then
                    updateBitboards (board.black, board.white, board.blackPieces, board.whitePieces, Rook, 56, 59);
                if (move.id = King) and (move.startSq = 60) and (move.endSq = 62) then
                    updateBitboards (board.black, board.white, board.blackPieces, board.whitePieces, Rook, 63, 61);
                if getBit (board.black.rookBitBoard, 56) = 0 then
                    board.castleFlags := board.castleFlags or blackRookLeftFlag;
                if getBit (board.black.rookBitboard, 63) = 0 then
                    board.castleFlags := board.castleFlags or blackRookRightFlag;
                if (move.id = King) or (board.castleFlags and (blackRookLeftFlag or blackRookRightFlag) = (blackRookLeftFlag or blackRookRightFlag)) then
                    board.castleFlags := board.castleFlags or blackCastleFlag;
            end
    end;    
    
procedure enterMoveSimple (turn: integer; var board: TBoardRecord; var move: moverec);
    var
        dummyId1, dummyId2: integer;
        dummyFlg: boolean;
    begin
        enterMove (turn, 1, dummyId1, dummyId2, dummyFlg, board, move)
    end;
    
function checkCastleRights (var board: TBoardRecord; turn: integer): integer;
    var
        bits: bitboard;
        dummyMove: moverec;
    begin
        result := 0;
        if (turn = 0) and (board.castleFlags and whiteCastleFlag = 1) or
           (turn = 1) and (board.castleFlags and blackCastleFlag = 2) then
            exit;
            
        {check back row interposing pieces}
        if turn = 0 then 
            begin
                if (board.castleFlags and whiteRookLeftFlag = 0) and (board.allPieces [0] and $7000 = 0) then
                    result := whiteLeftCastleRight;
                if (board.castleFlags and whiteRookRightFlag = 0) and (board.allPieces [0] and $0600 = 0) then
                    result := result or whiteRightCastleRight
            end
        else
            begin
                if (board.castleFlags and blackRookLeftFlag = 0) and (board.allPieces [3] and $0007 = 0) then
                    result := blackLeftCastleRight;
                if (board.castleFlags and blackRookRightFlag = 0) and (board.allPieces [3] and $0006 = 0) then
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
