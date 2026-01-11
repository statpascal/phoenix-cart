unit scorepos;

interface

uses globals, bitops, board;

function evaluateMove (turn: integer; var prevBoard: TBoardRecord; attackFlag: boolean; var move: TMoveRecord; capId: integer): integer;
function evaluatePosition (turn: integer; var board: TBoardRecord): integer;


implementation

uses trimprocs, resources;

function evaluateMove (turn: integer; var prevBoard: TBoardRecord; attackFlag: boolean; var move: TMoveRecord; capId: integer): integer;
    const
        captureBonus: array [0..5, 0..5] of uint8 = (
        //     P    R    N    B    Q    K
            ( 10, 100, 100, 100, 100, 100),         // pawn
            (  0,  50,   0,   0,  50,   0),         // rook
            (  0,  50,  25,  25,  50,   0),         // knight
            (  0,  50,  25,  25,  50,   0),         // bishop
            (  0,   0,   0,   0,   0,   0),         // queen
            (  0,   0,   0,   0,   0,   0));   	    // king

    begin
        result := 0;
        
        {capture bonus}
        if attackFlag then
            inc (result, captureBonus [move.pieceType, capId]);

        {bonus for castling/penalty for moving king if castling possible}
        if move.pieceType = King then
            if abs (move.startSq - move.endSq) = 2 then
                inc (result, 20)
            else 
                if (turn = 0) and (prevBoard.castleFlags and (whiteLeftCastle or whiteRightCastle) <> 0) or
                   (turn = 1) and (prevBoard.castleFlags and (blackLeftCastle or blackRightCastle) <> 0) then
                    dec (result, 20);

        {penalty for moving the rook if castling possible on its side}
        if (move.pieceType = Rook) and (gameMove < 13) then
            if (turn = 0) and (prevBoard.castleFlags and (whiteLeftCastle or whiteRightCastle) <> 0) or
               (turn = 1) and (prevBoard.castleFlags and (blackLeftCastle or blackRightCastle) <> 0) then
            dec (result, 10);
  
        {penalty if moving queen too early in game}
        if (move.pieceType = Queen) and (gameMove < 5) then
            dec (result, 100);
            
        {check bonus}
//        if isKingChecked (1 - turn, board) then
//            inc (result, 200)
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
                    inc (evalScore, 150);
                    
                    if side = 0 then
                        begin
                             {promote pawn advancement in end game}
                             if (endGame > 0) and (row >= 3) then
                                 inc (evalScore, row * 50);
                             {check for pawn promotion}
                             if row = 7 then
                                 inc (evalScore, 1000);
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
                             inc (evalScore, getPieceScoreValue (WhitePawnScore, pLoc))
                        end
                    else
                        begin
                            {promote pawn advancement in endgame}
                            if (endGame > 0) and (row <= 4) then
                                inc (evalScore, (7 - row) * 50);
                             {check for pawn promotion}
                            if row = 0 then
                                inc (evalScore, 1000);
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
                            inc (evalScore, getPieceScoreValue (BlackPawnScore, pLoc))
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
            inc (evalScore, 525 * locArray [0]);
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
        
    procedure evaluateKnightsBishops (var bits: bitboard; scoreType: TPieceScoreType);
        var
            locArray: bitarray;
            i: integer;
        begin
            BitPos (bits, locArray);
            for i := 1 to locArray [0] do
                inc (evalScore, 400 + getPieceScoreValue (scoreType, locArray [i]))
        end;
        
    procedure evaluateQueen;
        begin
            inc (evalScore, 973 * bitCount (sideBoards.queenBitboard))
        end;
        
    function distance (p1, p2: integer): integer;
        begin
            distance := abs (p1 shr 3 - p2 shr 3) + abs (p1 and 7 - p2 and 7)
        end;
        
    procedure evaluateKing (var ownKing, opponentKing: bitboard);
        const
            KingEdge: array [0..7] of uint8 = ($ff, $81, $81, $81, $81, $81, $81, $ff);
        var
            bits: bitboard;
            locArray: bitarray;
            ownPos: integer;
        begin
            {own king immediate check penalty}
            if isClear (ownKing) then
                begin
                    evalScore := -20000;
                    exit
                end;
                
            BitPos (ownKing, locArray);
            ownPos := locArray [1];
            
            if endGame > 0 then
                inc (evalScore, getPieceScoreValue (KingEndScore, ownPos))
            else
                inc (evalScore, getPieceScoreValue (KingMidScore, ownPos));
                
            {bonus for checking opposite king}
//            if isClear (opponentKing) then
//                inc (evalScore, 50)
//            else if side = gameSide then
            if (side = gameSide) and (endGame > 0) then
                begin
                    {encourage moving opposite king to board edge}
                    bits := opponentKing and bitboard (KingEdge);
                    if not isClear (bits) then
                        inc (evalScore, 100);
                    {move own king toward opposite king}
                    BitPos (opponentKing, locArray);
                    inc (evalScore, (15 - distance (ownPos, locArray [1])) * 15);
                end
        end;    

    begin 
        evalScore := 0;
        
        evaluatePawns;
        evaluateRooks;
        evaluateKnightsBishops (sideBoards.knightBitboard, KnightScore);
        evaluateKnightsBishops (sideBoards.bishopBitboard, BishopScore);
        evaluateQueen;
        evaluateKing (board.sides [side].kingBitboard, board.sides [1 - side].kingBitBoard);
            
        evaluateSide := evalScore
    end;
    

function evaluatePosition (turn: integer; var board: TBoardRecord): integer;
    var
        endGame: integer;
        
        
    begin
        {endgame determination}
        case bitCount (board.allPieces) of
            2..5: 
                endGame := 2;
            6..10:
                endGame := 1
            else
                endGame := 0
        end;
        
        evaluatePosition := evaluateSide (board.white, board, 0, endGame) - evaluateSide (board.black, board, 1, endGame)
    end;
    
end.
