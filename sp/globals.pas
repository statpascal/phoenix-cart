unit Globals;

interface

uses samsutil, vdp, bitops;

const
    Pawn = 0;
    Rook = 1;
    Knight = 2;
    Bishop = 3;
    Queen = 4;
    King = 5;
    InvalidPiece = 6;

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
    
    versionString = '2025-12-16-14-00';
    
    const 
        Figure: array [0..1, 0..5] of char = (('P', 'R', 'N', 'B', 'Q', 'K'),
                                              ('p', 'r', 'n', 'b', 'q', 'k'));
    
    
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
            true:  (side: array [0..1] of TSideRecord)
    end;
    
var
    gameSide: integer;
    pieceCount, cWarning: integer;
    gamePly, gameMove, humanSide: integer;
    moveNumHi, moveNumLo: integer;
    plyQS: integer;
    
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
        dummyMove: moverec;
        opponentMoves, res: bitboard;
    begin
        {ignore en passant - cannot affect king}
        fillchar (dummyMove, sizeof (dummyMove), 0);
        
        {check if own king attacked by opposite trim board}
        opponentMoves := combineTrimSide (turn = 0, dummyMove, board);
        if turn = 0 then
            BitAnd (opponentMoves, board.white.kingBitboard, res)
        else
            BitAnd (opponentMoves, board.black.kingBitboard, res);
            
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
                        end
                end;

            {place piece at end position}
            setBit (board.allPieces, endSq);
            setBit (ownPieces, endSq);
            if (id = Pawn) and (endSq in [0..7, 56..63]) then
                setBit (own.queenBitboard, endSq)
            else
                setBit (own.bitboards [id], endSq)
        end;
    
    begin
        if turn = 0 then
            begin
                updateBitboards (board.white, board.black, board.white.pieces, board.black.pieces, move.id, move.startsq, move.endsq);
                if (move.id = King) and (move.startSq = 4) and (move.endSq = 6) then
                    updateBitboards (board.white, board.black, board.white.pieces, board.black.pieces, Rook, 7, 5);
                if (move.id = King) and (move.startSq = 4) and (move.endSq = 2) then
                    updateBitboards (board.white, board.black, board.white.pieces, board.black.pieces, Rook, 0, 3);
                if getBit (board.white.rookBitBoard, 0) = 0 then
                    board.castleFlags := board.castleFlags or whiteRookLeftFlag;
                if getBit (board.white.rookBitboard, 7) = 0 then
                    board.castleFlags := board.castleFlags or whiteRookRightFlag;
                if (move.id = King) or (board.castleFlags and (whiteRookLeftFlag or whiteRookRightFlag) = (whiteRookLeftFlag or whiteRookRightFlag)) then
                    board.castleFlags := board.castleFlags or whiteCastleFlag;
            end
        else
            begin
                updateBitboards (board.black, board.white, board.black.pieces, board.white.pieces, move.id, move.startsq, move.endsq);
                if (move.id = King) and (move.startSq = 60) and (move.endSq = 58) then
                    updateBitboards (board.black, board.white, board.black.pieces, board.white.pieces, Rook, 56, 59);
                if (move.id = King) and (move.startSq = 60) and (move.endSq = 62) then
                    updateBitboards (board.black, board.white, board.black.pieces, board.white.pieces, Rook, 63, 61);
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
                if (board.castleFlags and whiteRookLeftFlag = 0) and (board.allPieces.b [0] and $70 = 0) then
                    result := whiteLeftCastleRight;
                if (board.castleFlags and whiteRookRightFlag = 0) and (board.allPieces.b [0] and $06 = 0) then
                    result := result or whiteRightCastleRight
            end
        else
            begin
                if (board.castleFlags and blackRookLeftFlag = 0) and (board.allPieces.b [7] and $07 = 0) then
                    result := blackLeftCastleRight;
                if (board.castleFlags and blackRookRightFlag = 0) and (board.allPieces.b [7] and $06 = 0) then
                    result := result or blackRightCastleRight
            end;
        if result = 0 then
            exit;
            
        {check for back row attack and remove affected rights}
        fillChar (dummyMove, sizeof (dummyMove), 0);
        bits := combineTrimSide (turn = 0, dummyMove, board);
        if turn = 0 then
            begin
                if bits.b [0] and $f0 <> 0 then		// not correct - rook may be attacked
                    result := result and not whiteLeftCastleRight;
                if bits.b [0] and $0f <> 0 then
                    result := result and not whiteRightCastleRight
            end
        else
            begin
                if bits.b [7] and $f0 <> 0 then
                    result := result and not blackLeftCastleRight;
                if bits.b [7] and $0f <> 0 then
                    result := result and not blackRightCastleRight
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

end.
