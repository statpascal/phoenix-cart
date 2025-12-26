unit Globals;

interface

uses vdp, bitops;

const
    Pawn = 0;
    Rook = 1;
    Knight = 2;
    Bishop = 3;
    Queen = 4;
    King = 5;
    InvalidPiece = 6;

    epColBitmask = 7;
    epWhiteFlag = 8;
    epMoveFlag = 16;
    
    whiteLeftCastle = 32;
    whiteRightCastle = 64;
    blackLeftCastle = 128;
    blackRightCastle = 256;
    
    versionString = '2025-12-26-16-00';
    
    Figure: array [0..1, 0..5] of char = (('P', 'R', 'N', 'B', 'Q', 'K'),
                                          ('p', 'r', 'n', 'b', 'q', 'k'));
    
    bitmasks: array [0..7] of uint8 = ($80, $40, $20, $10, $08, $04, $02, $01);

    
type 
    moverec = record
        id: integer;
        startSq: integer;
        endSq: integer
    end;

    TSideRecord = record
        case boolean of
            false: (pawnBitboard, rookBitboard, knightBitboard, bishopBitboard, queenBitboard, kingBitboard, pieces: bitboard);
            true:  (bitboards: array [0..6] of bitboard)
    end;
    
    TBoardRecord = record
        castleFlags: integer;
        allPieces: bitboard;
        case boolean of
            false: (white, black: TSideRecord);
            true:  (sides: array [0..1] of TSideRecord)
    end;
    
var
    gameSide: integer;
    pieceCount, cWarning: integer;
    gamePly, gameMove, humanSide: integer;
    moveNumHi, moveNumLo: integer;
    plyQS: integer;
    disableAlphaBetaPruning: boolean;
    
procedure ClearBitboard (var b: bitboard);
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
        res: bitboard;
    begin
        {check if own king attacked by opposite trim board}
        res := board.sides [turn].kingBitboard and combineTrimSide (turn = 0, board);
        isKingChecked := not isClear (res)
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
            clearBit (own.bitboards [id], startSq);
            
            {remove attacked piece from opponent's bitboards}
            foundFlag := false;
            if attackFlag = 1 then
                begin
                    j := Pawn;
                    repeat
                        if getBit (opponent.bitboards [j], endSq) <> 0 then
                            begin
                                foundFlag := true;
                                attackId := id;
                                capId := j;
                                clearBit (opponent.bitboards [j], endSq);
                                clearBit (opponentPieces, endSq)
                            end;
                        inc (j)
                    until (foundFlag) or (j > King);

                    {en passant capture handling}
                    if not foundFlag and (id = Pawn) and (abs (startSq - endSq) in [7, 9]) then
                        begin
                            if turn = 0 then
                                epSquare := endSq - 8
                            else
                                epSquare := endSq + 8;
                            clearBit (opponent.pawnBitboard, epSquare);
                            clearBit (opponentPieces, epSquare);
                            clearBit (board.allPieces, epSquare);
                            attackId := pawn;
                            capId := pawn
                        end
                end;

            {place piece at end position}
            setBit (board.allPieces, endSq);
            setBit (ownPieces, endSq);
            if (id = Pawn) and (endSq in [0..7, 56..63]) then
                // TODO: ask for human side
                setBit (own.queenBitboard, endSq)
            else
                setBit (own.bitboards [id], endSq);
              
            {set EP rights in board}  
            if (id = Pawn) and (abs (startSq - endSq) = 16) then
                begin
                    board.castleFlags := board.castleFlags or (startSq and 7) or epMoveFlag;
                    if endSq in [24..31] then 
                        board.castleFlags := board.castleFlags or epWhiteFlag
                end
        end;
    
    begin
        board.castleFlags := board.castleFlags and not (epMoveFlag + epWhiteFlag + epColBitmask);
        if turn = 0 then
            begin
                updateBitboards (board.white, board.black, board.white.pieces, board.black.pieces, move.id, move.startsq, move.endsq);
                if (move.id = King) and (move.startSq = 4) and (move.endSq = 6) then
                    updateBitboards (board.white, board.black, board.white.pieces, board.black.pieces, Rook, 7, 5);
                if (move.id = King) and (move.startSq = 4) and (move.endSq = 2) then
                    updateBitboards (board.white, board.black, board.white.pieces, board.black.pieces, Rook, 0, 3);
                if move.id = King then
                    board.castleFlags := board.castleFlags and not (whiteLeftCastle or whiteRightCastle)
            end
        else
            begin
                updateBitboards (board.black, board.white, board.black.pieces, board.white.pieces, move.id, move.startsq, move.endsq);
                if (move.id = King) and (move.startSq = 60) and (move.endSq = 58) then
                    updateBitboards (board.black, board.white, board.black.pieces, board.white.pieces, Rook, 56, 59);
                if (move.id = King) and (move.startSq = 60) and (move.endSq = 62) then
                    updateBitboards (board.black, board.white, board.black.pieces, board.white.pieces, Rook, 63, 61);
                if move.id = King then
                    board.castleFlags := board.castleFlags and not (blackLeftCastle or blackRightCastle)
            end;
        if getBit (board.white.rookBitBoard, 0) = 0 then
            board.castleFlags := board.castleFlags and not whiteLeftCastle;
        if getBit (board.white.rookBitboard, 7) = 0 then
            board.castleFlags := board.castleFlags and not whiteRightCastle;
        if getBit (board.black.rookBitBoard, 56) = 0 then
            board.castleFlags := board.castleFlags and not blackLeftCastle;
        if getBit (board.black.rookBitboard, 63) = 0 then
            board.castleFlags := board.castleFlags and not blackRightCastle
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
    begin
        result := board.castleFlags;
            
        {check back row interposing pieces}
        if turn = 0 then 
            begin
                if bytearray (board.allPieces) [0] and $70 <> 0 then
                    result := result and not whiteLeftCastle;
                if bytearray (board.allPieces) [0] and $06 <> 0 then
                    result := result and not whiteRightCastle;
                if result and (whiteLeftCastle or whiteRightCastle) = 0 then
                   exit
            end
        else
            begin
                if bytearray (board.allPieces) [7] and $07 <> 0 then
                    result := result and not blackLeftCastle;
                if bytearray (board.allPieces) [7] and $06 <> 0 then
                    result := result and not blackRightCastle;
                if result and (blackLeftCastle or blackRightCastle) = 0 then
                    exit
            end;
            
        {check for back row attack and remove affected rights}
        bits := combineTrimSide (turn = 0, board);
        if turn = 0 then
            begin
                if bytearray (bits) [0] and $38 <> 0 then		// not correct - rook may be attacked
                    result := result and not whiteLeftCastle;
                if bytearray (bits) [0] and $0e <> 0 then
                    result := result and not whiteRightCastle
            end
        else
            begin
                if bytearray (bits) [7] and $38 <> 0 then
                    result := result and not blackLeftCastle;
                if bytearray (bits) [7] and $0e <> 0 then
                    result := result and not blackRightCastle
            end
    end;        
           

function getKeyInt: integer;
    begin
        getKeyInt := ord (upcase (getkey ()))
    end;

procedure ClearBitboard (var b: bitboard);
    begin
        fillChar (b, sizeof (b), 0)
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

begin
    disableAlphaBetaPruning := false
end.
