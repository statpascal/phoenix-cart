unit scorepos;

interface

uses globals, bitops, board;

const
    MoveQueenExchangeWhite = 1;
    MoveQueenExchangeBlack = 2;
    MoveEndGame = 4;

(*  
    PawnValue = 150;
    RookValue = 525;
    KnightValue = 400;
    BishopValue = 400;
    QueenValue = 973;
*)    
    PawnValue = 100;
    RookValue = 505;
    KnightValue = 325;
    BishopValue = 350;
    QueenValue = 900;
    KingValue = 20000;
    
    EndGameReached = 3000;

type
    TMoveScore = record
        bonus, flags: integer
    end;

procedure evaluateMove (turn: integer; var prevBoard: TBoardRecord; attackFlag: boolean; var move: TMoveRecord; ply, capId: integer; var moveScore: TMoveScore);
function evaluatePosition (var board: TBoardRecord; moveScore: TMoveScore): integer;


implementation

uses trimprocs, resources;

procedure evaluateMove (turn: integer; var prevBoard: TBoardRecord; attackFlag: boolean; var move: TMoveRecord; ply, capId: integer; var moveScore: TMoveScore);
    const
        captureBonus: array [0..5, 0..5] of uint8 = (
        //     P    R    N    B    Q    K
            ( 10,  25,  25,  25,  50,   0),         // pawn
            (  0,  25,   0,   0,  50,   0),         // rook
            (  0,  25,   0,   0,  50,   0),         // knight
            (  0,  25,   0,   0,  50,   0),         // bishop
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
                        moveScore.flags := moveScore.flags or MoveQueenExchangeWhite
                    else
                        moveScore.flags := moveScore.flags or MoveQueenExchangeBlack
            end;

        {bonus for castling/penalty for moving king if castling possible}
        if move.pieceType = King then
            if abs (move.startSq - move.endSq) = 2 then
                inc (bonus, 50 + ply)
            else 
                if (turn = 0) and (prevBoard.flags and (whiteLeftCastle or whiteRightCastle) <> 0) or
                   (turn = 1) and (prevBoard.flags and (blackLeftCastle or blackRightCastle) <> 0) then
                    dec (bonus, 50);

        {penalty for moving the rook if castling possible on its side}
        if (move.pieceType = Rook) and (prevBoard.moveNr < 13) then
            if (turn = 0) and (prevBoard.flags and (whiteLeftCastle or whiteRightCastle) <> 0) or
               (turn = 1) and (prevBoard.flags and (blackLeftCastle or blackRightCastle) <> 0) then
            dec (bonus, 25);
  
        {penalty if moving queen too early in game}
        if (move.pieceType = Queen) and (prevBoard.moveNr < 5) then
            dec (bonus, 50);
            
//        {check bonus}
//        if isKingChecked (1 - turn, prevBoard) then
//            inc (bonus, 200);

        if turn = 0 then
            inc (moveScore.bonus, bonus)
        else
            dec (moveScore.bonus, bonus)
            
    end;

var    
    sideCache: array [0..1] of bitboard;
    
function evaluateSide (var sideBoards: TSideRecord; var board: TBoardRecord; side, endGame: integer): integer;
{$ifdef ti99}
    procedure ext_psd; external '../resources/piecescore.dat';
    var
        pieceScoreData: TPieceScoreData absolute ext_psd;
{$endif}

    var
        evalScore: integer;

    procedure evaluatePawns;
        var
            row, col, pLoc, i, pr, pc: integer;
            passed: boolean;
            locArray: bitarray;
        const
            sideVals: array [0..1] of integer = (0, 0);
        begin
            if compareByte (sideCache [side], sideBoards.pawnBitboard, sizeof (bitboard)) = 0 then
                begin
                    inc (evalScore, sideVals [side]);
                    exit
                end;
                
            sideCache [side] := sideBoards.pawnBitboard;
            sideVals [side] := 0;
        
            BitPos (sideBoards.pawnBitboard, locArray);
            for i := 1 to locArray [0] do
                begin
                    pLoc := locArray [i];
                    row := pLoc shr 3;
                    col := pLoc and 7;
                    inc (sideVals [side], PawnValue);
                    
                    if side = 0 then
                        begin
                             {promote advancement of passed paawns in end game}
                             if (endGame > 0) and (row >= 3) then
                                 begin
                                     passed := true;
                                     for pr := row + 1 to 7 do
                                         for pc := col - 1 to col + 1 do
                                             if (pc >= 0) and (pc <= 7) then
                                                 if getBit (board.sides [1 - side].pawnBitboard, pr * 8 + pc) <> 0 then
                                                     passed := false;
                                     if passed then
                                         inc (sideVals [side], row * 50)
                                 end;
                             {check pawn support}
                             if row >= 2 then
                                 begin
                                     if (col <> 0) and (getBit (sideBoards.pawnBitboard, pLoc - 9) <> 0) then
                                         inc (sideVals [side], 20);
                                     if (col <> 7) and (getBit (sideBoards.pawnBitboard, ploc - 7) <> 0) then
                                         inc (sideVals [side], 20)
                                  end;
                             {doubled pawns penalty}
                             if (row < 7) and (getBit (sideBoards.pawnBitboard, pLoc + 8) <> 0) then
                                 dec (sideVals [side], 50);
                             inc (sideVals [side], pieceScoreData [PawnScore, pLoc])
                        end
                    else
                        begin
                            {promote advancement of passed pawns in endgame}
                            if (endGame > 0) and (row <= 4) then
                                begin
                                    passed := true;
                                    for pr := 0 to row - 1 do
                                        for pc := col - 1 to col + 1 do
                                            if (pc >= 0) and (pc <= 7) then
                                                if getBit (board.sides [1 - side].pawnBitboard, pr * 8 + pc) <> 0 then
                                                    passed := false;
                                    if passed then
                                        inc (sideVals [side], (7 - row) * 50)
                                end;
                            {check pawn support}
                            if row <= 5 then 
                                begin
                                    if (col <> 0) and (getBit (sideBoards.pawnBitboard, ploc + 7) <> 0) then
                                        inc (sideVals [side], 20);
                                    if (col <> 7) and (getBit (sideBoards.pawnBitboard, ploc + 9) <> 0) then
                                        inc (sideVals [side], 20)
                                 end;
                            {doubled pawns penalty}
                            if (row > 0) and (getBit (sideBoards.pawnBitboard, pLoc - 8) <> 0) then
                                dec (sideVals [side], 50);
                            inc (sideVals [side], pieceScoreData [PawnScore, pLoc xor 56])
                        end
                end;
                
            inc (evalScore, sideVals [side])
        end;
        
    procedure evaluateRooks;
        var
            locArray: bitarray;
            epDummy: integer;
            bits: bitboard;
        begin
            inc (evalScore, RookValue * bitCount (sideBoards.rookBitboard));
(*        
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
*)                
        end;
        
    procedure evaluateKnightsBishops (var bits: bitboard; scoreType: TPieceScoreType; pieceValue: integer);
        var
            locArray: bitarray;
            i: integer;
        begin
            BitPos (bits, locArray);
            if side = 0 then
                for i := 1 to locArray [0] do
                    inc (evalScore, pieceValue + pieceScoreData [scoreType, locArray [i]])
            else
                for i := 1 to locArray [0] do
                    inc (evalScore, pieceValue + pieceScoreData [scoreType, locArray [i] xor 56]);
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
                evalPos := ownPos xor 56;
        
            if endGame > 0 then
                begin
                    inc (evalScore, pieceScoreData [KingEndScore, evalPos]);
                    {move own king toward opposite king}
                    BitPos (opponentKing, locArray);
                    inc (evalScore, (15 - distance (ownPos, locArray [1])) * 15)
                end
            else
                inc (evalScore, pieceScoreData [KingMidScore, evalPos])
        end;    
        
    procedure evaluateRookFiles;
        var
            locArray: bitarray;
            i, rsq, col, r, ownPawn, oppPawn: integer;
        begin
            BitPos (sideBoards.rookBitboard, locArray);
            for i := 1 to locArray [0] do
                begin
                    rsq := locArray [i];  col := rsq and 7;
                    ownPawn := 0;  oppPawn := 0;
                    for r := 0 to 7 do
                        begin
                            if getBit (sideBoards.pawnBitboard,            r * 8 + col) <> 0 then ownPawn := 1;
                            if getBit (board.sides [1 - side].pawnBitboard, r * 8 + col) <> 0 then oppPawn := 1
                        end;
                    if (ownPawn = 0) and (oppPawn = 0) then
                        inc (evalScore, 25)          { fully open file }
                    else if ownPawn = 0 then
                        inc (evalScore, 12)          { half-open file }
                end
        end;

    procedure evaluateKingShield;
        var
            locArray: bitarray;
            ksq, krow, kcol, dc, c, shieldRow, cnt: integer;
        begin
            if endGame > 0 then exit;              { shield only matters in the middlegame }
            BitPos (sideBoards.kingBitboard, locArray);
            ksq := locArray [1];  krow := ksq shr 3;  kcol := ksq and 7;
            cnt := 0;
            if side = 0 then shieldRow := krow + 1 else shieldRow := krow - 1;
            if (shieldRow >= 0) and (shieldRow <= 7) then
                for dc := -1 to 1 do
                    begin
                        c := kcol + dc;
                        if (c >= 0) and (c <= 7) then
                            if getBit (sideBoards.pawnBitboard, shieldRow * 8 + c) <> 0 then
                                inc (cnt)
                    end;
            inc (evalScore, cnt * 12)
        end;

    // TODO: check folding with pawn evaluation
    procedure evaluateIsoPawns;
        var
            locArray: bitarray;
            i, psq, col, r, hasAdj: integer;
        begin
            BitPos (sideBoards.pawnBitboard, locArray);
            for i := 1 to locArray [0] do
                begin
                    psq := locArray [i];  col := psq and 7;  hasAdj := 0;
                    for r := 0 to 7 do
                        begin
                            if (col > 0) and (getBit (sideBoards.pawnBitboard, r * 8 + col - 1) <> 0) then hasAdj := 1;
                            if (col < 7) and (getBit (sideBoards.pawnBitboard, r * 8 + col + 1) <> 0) then hasAdj := 1
                        end;
                    if hasAdj = 0 then
                        dec (evalScore, 15)
                end
        end;

    procedure evaluateMobility;
        const
            mobWeight: array [Pawn..Queen] of integer = (0, 2, 4, 4, 1);   { P R N B Q }
        var
            locArray: bitarray;
            piece, i, epDummy: integer;
            mb: bitboard;
        begin
            for piece := Rook to Queen do
                begin
                    BitPos (sideBoards.bitboards [piece], locArray);
                    for i := 1 to locArray [0] do
                        begin
                            mb := Trim (side, piece, locArray [i], board, epDummy);
                            inc (evalScore, BitCount (mb) * mobWeight [piece])
                        end
                end
        end;

    begin 
        evalScore := 0;
        
        evaluatePawns;
        evaluateRooks;
//        evaluateRookFiles;
        evaluateKnightsBishops (sideBoards.knightBitboard, KnightScore, KnightValue);
        evaluateKnightsBishops (sideBoards.bishopBitboard, BishopScore, BishopValue);
        evaluateQueen;
        evaluateKing (board.sides [side].kingBitboard, board.sides [1 - side].kingBitBoard);
        
//        evaluateKingShield;
//        evaluateIsoPawns;
//        evaluateMobility;
            
        evaluateSide := evalScore
    end;
    

function evaluatePosition (var board: TBoardRecord; moveScore: TMoveScore): integer;
    var
        endGame: integer;
    begin
        endGame := moveScore.flags and MoveEndGame;
        
        result := evaluateSide (board.white, board, 0, endGame) 
                  - evaluateSide (board.black, board, 1, endGame)
                  + moveScore.bonus;
                  
        if (result >= 50) and (moveScore.flags and MoveQueenExchangeWhite <> 0) then
            inc (result, 75)
        else if (result <= -50) and (moveScore.flags and MoveQueenExchangeBlack <> 0) then
            dec (result, 75)
    end;

begin
    fillChar (sideCache, sizeof (sideCache), 0);    
end.
