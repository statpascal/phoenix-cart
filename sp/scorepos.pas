unit scorepos;

interface

uses globals, bitops, board;

const
    MoveQueenExchangeWhite = 1;
    MoveQueenExchangeBlack = 2;
    MoveEndGame = 4;
  
    PawnValue = 150;
    RookValue = 525;
    KnightValue = 400;
    BishopValue = 400;
    QueenValue = 973;
(*    
    PawnValue = 100;
    RookValue = 505;
    KnightValue = 300;
    BishopValue = 300;
    QueenValue = 900;
*)    
    EndGameReached = 3000;

type
    TMoveScore = record
        bonus, flags: integer
    end;

procedure evaluateMove (turn: integer; var prevBoard: TBoardRecord; attackFlag: boolean; var move: TMoveRecord; capId: integer; var moveScore: TMoveScore);
function evaluatePosition (var board: TBoardRecord; moveScore: TMoveScore): integer;


implementation

uses trimprocs, resources;

procedure evaluateMove (turn: integer; var prevBoard: TBoardRecord; attackFlag: boolean; var move: TMoveRecord; capId: integer; var moveScore: TMoveScore);
    const
        captureBonus: array [0..5, 0..5] of uint8 = (
        //     P    R    N    B    Q    K
            ( 10, 100, 100, 100, 100, 100),         // pawn
            (  0,  50,   0,   0,  50,   0),         // rook
            (  0,  50,  25,  25,  50,   0),         // knight
            (  0,  50,  25,  25,  50,   0),         // bishop
            (  0,   0,   0,   0,   0,   0),         // queen
            (  0,   0,   0,   0,   0,   0));   	    // king
    var
        bonus: integer;

    begin
        bonus := 0;
    
        {capture bonus}
        if attackFlag then
            begin
                inc (bonus, captureBonus [move.pieceType, capId]);
                if (move.pieceType = Queen) and (capId = Queen) then
                    if turn = 0 then
                        move.flags := move.flags or MoveQueenExchangeWhite
                    else
                        move.flags := move.flags or MoveQueenExchangeBlack
            end;

        {bonus for castling/penalty for moving king if castling possible}
        if move.pieceType = King then
            if abs (move.startSq - move.endSq) = 2 then
                inc (bonus, 20)
            else 
                if (turn = 0) and (prevBoard.flags and (whiteLeftCastle or whiteRightCastle) <> 0) or
                   (turn = 1) and (prevBoard.flags and (blackLeftCastle or blackRightCastle) <> 0) then
                    dec (bonus, 20);

        {penalty for moving the rook if castling possible on its side}
        if (move.pieceType = Rook) and (gameMove < 13) then
            if (turn = 0) and (prevBoard.flags and (whiteLeftCastle or whiteRightCastle) <> 0) or
               (turn = 1) and (prevBoard.flags and (blackLeftCastle or blackRightCastle) <> 0) then
            dec (bonus, 10);
  
        {penalty if moving queen too early in game}
        if (move.pieceType = Queen) and (gameMove < 5) then
            dec (bonus, 100);
            
//        {check bonus}
//        if isKingChecked (1 - turn, prevBoard) then
//            inc (bonus, 200);

        if turn = 0 then
            inc (moveScore.bonus, bonus)
        else
            dec (moveScore.bonus, bonus)
            
    end;
    
function evaluateSide (var sideBoards: TSideRecord; var board: TBoardRecord; side, endGame: integer): integer;
    var
        evalScore: integer;
        
    procedure evaluatePawns;
        var
            row, col: integer;
            pLoc, i: integer;            
            locArray: bitarray;
        begin
            BitPos (sideBoards.pawnBitboard, locArray);
            for i := 1 to locArray [0] do
                begin
                    pLoc := locArray [i];
                    row := pLoc shr 3;
                    col := pLoc and 7;
                    inc (evalScore, PawnValue);
                    
                    if side = 0 then
                        begin
                             {promote pawn advancement in end game}
                             if (endGame > 0) and (row >= 3) then
                                 inc (evalScore, row * 50);
                             {check pawn support}
                             if row >= 2 then
                                 begin
                                     if (col <> 0) and (getBit (sideBoards.pawnBitboard, pLoc - 9) <> 0) then
                                         inc (evalScore, 15);
                                     if (col <> 7) and (getBit (sideBoards.pawnBitboard, ploc - 7) <> 0) then
                                         inc (evalScore, 15)
                                  end;
                             {doubled pawns penalty}
                             if (row < 7) and (getBit (sideBoards.pawnBitboard, pLoc + 8) <> 0) then
                                 dec (evalScore, 25);
                             inc (evalScore, getPieceScoreValue (PawnScore, pLoc))
                        end
                    else
                        begin
                            {promote pawn advancement in endgame}
                            if (endGame > 0) and (row <= 4) then
                                inc (evalScore, (7 - row) * 50);
                            {check pawn support}
                            if row <= 5 then 
                                begin
                                    if (col <> 0) and (getBit (sideBoards.pawnBitboard, ploc + 7) <> 0) then
                                        inc (evalScore, 15);
                                    if (col <> 7) and (getBit (sideBoards.pawnBitboard, ploc + 9) <> 0) then
                                        inc (evalScore, 15)
                                 end;
                            {doubled pawns penalty}
                            if (row > 0) and (getBit (sideBoards.pawnBitboard, pLoc - 8) <> 0) then
                                dec (evalScore, 25);
                            inc (evalScore, getPieceScoreValue (PawnScore, (7 - row) shl 3 + col))
                        end
                end
        end;
        
    procedure evaluateRooks;
        var
            locArray: bitarray;
            epDummy: integer;
            bits: bitboard;
        begin
            BitPos (sideBoards.rookBitboard, locArray);
            inc (evalScore, RookValue * locArray [0]);
            if locArray [0] = 2 then
                begin
                    {bonus for connected rooks - check if other rook could be caught as opponent}
                    bits := Trim (1 - side, Rook, locArray [1], board, epDummy);
                    if getBit (bits, locArray [2]) <> 0 then
                        if (endGame = 0) and (locArray [1] and not 7 = locArray [2] and not 7) then
                            inc (evalScore, 50)
                        else
                            inc (evalScore, 100)
                end
        end;
        
    procedure evaluateKnightsBishops (var bits: bitboard; scoreType: TPieceScoreType; pieceValue: integer);
        var
            locArray: bitarray;
            i: integer;
        begin
            BitPos (bits, locArray);
            if side = 0 then
                for i := 1 to locArray [0] do
                    inc (evalScore, pieceValue + getPieceScoreValue (scoreType, locArray [i]))
            else
                for i := 1 to locArray [0] do
                    inc (evalScore, pieceValue + getPieceScoreValue (scoreType, (7 - locArray [i] shr 3) shl 3 + locArray [i] and 7))
        end;
        
    procedure evaluateQueen;
        begin
            inc (evalScore, QueenValue * bitCount (sideBoards.queenBitboard))
        end;
        
    function distance (p1, p2: integer): integer;
        begin
            distance := abs (p1 shr 3 - p2 shr 3) + abs (p1 and 7 - p2 and 7)
        end;
        
    procedure evaluateKing (var ownKing, opponentKing: bitboard);
        var
            locArray: bitarray;
            ownPos, evalPos: integer;
        begin
            BitPos (ownKing, locArray);
            ownPos := locArray [1];
            
            if side = 0 then
                evalPos := ownPos
            else
                evalPos := (7 - ownPos shr 3) shl 3 + ownPos and 7;
            
            if endGame > 0 then
                begin
                    inc (evalScore, getPieceScoreValue (KingEndScore, evalPos));
                    {move own king toward opposite king}
                    BitPos (opponentKing, locArray);
                    inc (evalScore, (15 - distance (ownPos, locArray [1])) * 15)
                end
            else
                inc (evalScore, getPieceScoreValue (KingMidScore, evalPos))
        end;    

    begin 
        evalScore := 0;
        
        evaluatePawns;
        evaluateRooks;
        evaluateKnightsBishops (sideBoards.knightBitboard, KnightScore, KnightValue);
        evaluateKnightsBishops (sideBoards.bishopBitboard, BishopScore, BishopValue);
        evaluateQueen;
        evaluateKing (board.sides [side].kingBitboard, board.sides [1 - side].kingBitBoard);
            
        evaluateSide := evalScore
    end;
    

function evaluatePosition (var board: TBoardRecord; moveScore: TMoveScore): integer;
    var
        endGame: integer;
    begin
        {update number of positions evaluated}
        inc (moveNumLo);
        if (moveNumLo = 1000) then
            begin
                moveNumLo := 0;
                inc (moveNumHi)
            end;
        
    
        endGame := moveScore.flags and MoveEndGame;
        
        result := evaluateSide (board.white, board, 0, endGame) 
                  - evaluateSide (board.black, board, 1, endGame)
                  + moveScore.bonus;
                  
        if (result >= 50) and (moveScore.flags and MoveQueenExchangeWhite <> 0) then
            inc (result, 75)
        else if (result <= -50) and (moveScore.flags and MoveQueenExchangeBlack <> 0) then
            dec (result, 75)
    end;
    
end.
