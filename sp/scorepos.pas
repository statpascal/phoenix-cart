unit scorepos;

interface

uses globals;

function evaluate (cMoveFlag, attackFlag, attackId, capId: integer; var lastMove, tempMove: moverec; var board: TBoardRecord): integer;


implementation

uses trimprocs, resources;

function evaluateSide (var sideBoards: TSideRecord; var board: TBoardRecord; var lastMove: moverec; cMoveFlag, side, endGame: integer): integer;
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
                    bits := Trim (1 - side, 0, locArray [1], LastMove, board, epDummy);
                    if getBit (bits, locArray [2]) <> 0 then
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
        
    procedure evaluateKing;
        const
            KingEdge: bitboard = ($ff81, $8181, $8181, $81ff);
        var
            ownKing, opponentKing, bits: bitboard;
            locArray: bitarray;
            ownPos: integer;
        begin
            if side = 0 then
                begin
                    ownKing := board.white.kingBitboard;
                    opponentKing := board.black.kingBitboard
                end
            else
                begin
                    ownKing := board.black.kingBitboard;
                    opponentKing := board.white.kingBitboard
                end;

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
                
            {apply castling bonus}
            if (cMoveFlag = 1) and (side = gameSide) then
                 evalScore := evalScore + 150;
                    
            {bonus for checking opposite king}
            if isClear (opponentKing) then
                inc (evalScore, 50)
            else
                begin
                    {encourage moving opposite king to board edge}
                    if endGame > 0 then
                        begin
                            BitAnd (opponentKing, KingEdge, bits);
                            if not isClear (bits) then
                                inc (evalScore, 100)
                    end;

                    {move own king toward opposite king when <=4 pieces left}
                    if endGame = 2 then
                        begin
                            BitPos (opponentKing, locArray);
                            if not (abs (ownPos - locArray[1]) in [2, 15, 16, 17]) then
                                inc (evalScore, (8 - (abs (ownPos - locArray [1]) div 2)) * 10)
                           end
                end
        end;    

    begin 
        evalScore := 0;
        
        evaluatePawns;
        evaluateRooks;
        evaluateKnightsBishops (sideBoards.knightBitboard, KnightScore);
        evaluateKnightsBishops (sideBoards.bishopBitboard, BishopScore);
        evaluateQueen;
        evaluateKing;
            
        evaluateSide := evalScore
    end;

function evaluate(cMoveFlag, attackFlag, attackId, capId: integer; var lastMove, tempMove: moverec; var board: TBoardRecord): integer;
    var
        wScore, bScore, evalScore, endGame: integer;
        locArray: bitarray;
        
    procedure checkEnPassant (isBlack: boolean; var pawnBitboard: bitboard; startSq: integer; var score: integer);
            var
                bits: bitboard;
            begin
                bits := getEnPassantBitboard (isBlack, startSq and 7);
                BitAnd (bits, pawnBitboard, bits);
                if not isClear (bits) then
                    dec (score, 100)
            end;
        
    const
        captureBonus: array [0..5, 0..5] of uint8 = (
        //     P    R    N    B    Q    K
            ( 10, 100, 100, 100, 100, 100),         // pawn
            (  0, 100,   0,   0, 100,   0),         // rook
            (  0, 100,  50,  50, 100,   0),         // knight
            (  0, 100,  50,  50, 100,   0),         // bishop
            (  0,   0,   0,   0,  75,   0),         // queen
            (  0,   0,   0,   0,   0,   0));   	    // king

    begin
        wScore := 0;
        bScore := 0;
        endGame := 0;

        {capture bonus}
        if attackFlag = 1 then
            if turn = 0 then
                inc (wScore, captureBonus [attackId shr 3, capId shr 3])
            else
                inc (bScore, captureBonus [attackId shr 3, capId shr 3]);

        {penalty for moving king if castling possible}
        if (tempMove.id = 40) and (cMoveFlag = 0) then
            if (turn = 0) and (wCastleFlag = 0) then
                dec (wScore, 400)
            else if (turn = 1) and (bCastleFlag = 0) then
                dec (bScore, 400);

        {penalty for moving the rook if castling possible on its side}
        if (tempMove.id = 8) and (gameMove < 13) then
            if (turn = 0) and (wCastleFlag = 0) then
                dec (wScore, 500)
            else if (turn = 1) and (bCastleFlag = 0) then
                dec (bScore, 500);
  
        {penalty if moving queen too early in game}
        if (tempMove.id = 32) and (gameMove < 5) then
            if turn = 0 then
                dec (wScore, 300)
            else
                dec (bScore, 300);
                
        {endgame determination}
        if turn = 0 then
            BitPos (board.blackPieces, locArray)
        else
            BitPos (board.whitePieces, locArray);
        if locArray[0] <= 3 then
            endGame := 2
        else if locArray[0] <= 5 then
            endGame := 1;
            
        if (tempMove.id = Pawn) and (abs(tempMove.startSq - tempMove.endSq) = 16) then
            if turn = 0 then
                checkEnPassant (false, tempboard.black.pawnBitboard, tempMove.startSq, wScore)
            else
                checkEnPassant (true, tempboard.white.pawnBitboard, tempMove.startSq, bScore);

        evaluate := wScore + evaluateSide (board.white, board, lastMove, cMoveFlag, 0, endGame) -
                    bScore - evaluateSide (board.black, board, lastMove, cMoveFlag, 1, endGame)
    end;
    
end.
