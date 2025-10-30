unit scorepos;

interface

uses globals;

function evaluate(cMoveFlag, attackFlag, attackId, capId: integer; lastMove, tempMove: moverec): integer;

implementation

uses trimprocs;

function evaluate(cMoveFlag, attackFlag, attackId, capId: integer; lastMove, tempMove: moverec): integer;
    label 
        l_1;
    var 
        sPage1, dSize, initOffset, offset, offset1, offset2, i, j, k, l: integer;
        sPage2, side, wScore, bScore, evalScore, pawnCount, bonus: integer;
        endGame, pLoc: integer;
        locArray: bitarray;

    begin
        sPage1 := BASE1;
        dSize := 2;
        wScore := 0;
        bScore := 0;
        endGame := 0;
        startPage := BASE;
        dataSize := 8;
        
        {capture bonus}
        if (attackFlag = 1) and (turn = gameSide) then
            begin
                bonus := 0;
                case attackId of
                    0 : 
                        if capId = 0 then
                            bonus := 10
                        else
                            bonus := 50;
                    8 : 
                        if capId in [8, 32] then
                            bonus := 50;
                    16, 24 : 
                        if capId in [8, 32] then
                             bonus := 50
                        else
                            if capId in [16, 24] then
                                bonus := 25;
                    32 : 
                        if capId = 32 then
                            bonus := 50;
                end;
                if turn = 0 then
                    wScore := wScore + bonus
                else
                    bScore := bScore + bonus;
            end;

     {penalty for moving king if castling possible}
        if (tempMove.id = 40) and (cMoveFlag = 0) then
            begin
                if (turn = 0) and (wCastleFlag = 0) then
                    wScore := wScore - 400
                else
                    if (turn = 1) and (bCastleFlag = 0) then
                        bScore := bScore - 400;
            end;

     {penalty for moving the rook if castling possible on its side}
        if (tempMove.id = 8) and (gameMove < 13) then
            begin
                if (turn = 0) and (wCastleFlag = 0) then
                    wScore := wScore - 500
                else
                    if (turn = 1) and (bCastleFlag = 0) then
                        bScore := bScore - 500;
            end;

     {endgame determination}
        if turn = 0 then
            offset1 := TBPIECES
        else
            offset1 := TWPIECES;
        DataOps(2, startPage, dataSize, offset1, bit1);
        BitPos(bit1, locArray);
        if locArray[0] <= 5 then
            endGame := 1;
        if locArray[0] <= 3 then
            endGame := 2;

     {mobility advantage determination}
        if wMobility > bMobility then
            wScore := wScore + 100
        else
            if bMobility > wMobility then
                bScore := bScore + 100;

     {determine base score for each side}
        for side := 0 to 1 do
            begin
       {en passant capture risk}
                if (tempMove.id = 0) and (abs(tempMove.startSq - tempMove.endSq) = 16) then
                    begin
                        if side = 0 then
                            begin
                                offset1 := WEP + ((tempMove.startSq - 8) * 8);
                                offset2 := TBPO;
                            end
                        else
                            begin
                                offset1 := BEP + ((tempMove.startSq - 48) * 8);
                                offset2 := TWPO;
                            end;
                        DataOps(2, sPage1, dataSize, offset1, bit2);
                        DataOps(2, startPage, dataSize, offset2, bit3);
                        BitAnd(bit2, bit3, bit2);
                        if not(IsClear(bit2)) then
                            if side = 0 then
                                wScore := wScore - 100
                        else
                            bScore := bScore - 100;
                    end;

                sPage1 := BASE2;

                if side = 0 then
                    initOffset := TWPO
                else
                    initOffset := TBPO;

                evalScore := 0;

       {loop through all own pieces}
                j := 0;
                repeat
                    offset := initOffset + j;
                    dataOps(2, startPage, dataSize, offset, bit1);
                    if not(IsClear(bit1)) then
                        begin
           {calculate piece scores}
                            BitPos(bit1, locArray);
                            for i := 1 to locArray[0] do
                                begin
                                    pLoc := locArray[i];
                                    offset2 := PIECELOC + (pLoc * 8);
                                    DataOps(2, startPage, dataSize, offset2, bit2);
                                    case j of 
                                        0: 
                                        begin
                                            evalScore := evalScore + 100;
                                            if side = 0 then
                                                begin
                                                    offset1 := WPAWN + (pLoc * 2);
                     {promote pawn advancement in end game}
                                                    if (endGame > 0) and (pLoc >= 24) then
                                                        evalScore := evalScore + ((pLoc div 8) * 50);
                     {check for pawn promotion}
                                                    if pLoc >= 56 then
                                                        evalScore := evalScore + 1000;
                     {check pawn support}
                                                    if pLoc > 15 then
                                                        begin
                                                            for l := 0 to 1 do
                                                                begin
                                                                    offset2 := FILEBLANK + (56 * l);;
                                                                    DataOps(2, startPage, dataSize,
                                                                            offset2, bit4);
                                                                    BitAnd(bit2, bit4, bit4);
                                                                    if not(IsClear(bit4)) then
                                                                        begin
                                                                            if l = 0 then
                                                                                offset2 := PIECELOC + ((
                                                                                           pLoc - 9) * 8
                                                                                           )
                                                                            else
                                                                                offset2 := PIECELOC + ((
                                                                                           pLoc - 7) * 8
                                                                                           );
                                                                            DataOps(2, startPage,
                                                                                    dataSize, offset2,
                                                                                    bit4);
                                                                            DataOps(2, startPage,
                                                                                    dataSize, initOffset
                                                                                    , bit5);
                                                                            BitAnd(bit5, bit4, bit4);
                                                                            if not(IsClear(bit4)) then
                                                                                evalScore := evalScore +
                                                                                             15;
                                                                        end;
                                                                end;
                                                        end;

                     {doubled pawns penalty}
                                                    if pLoc <56 then
                                                        begin
                                                            offset2 := PIECELOC + ((pLoc + 8) * 8);
                                                            DataOps(2, startPage, dataSize, offset2,
                                                                    bit4);
                                                            BitAnd(bit1, bit4, bit4);
                                                            if not(IsClear(bit4)) then
                                                                evalScore := evalScore - 25;
                                                        end;
                                                end
                                            else
                                                begin
                                                    offset1 := BPAWN + (pLoc * 2);
                     {promote pawn advancement in endgame}
                                                    if (endGame > 0) and (pLoc <= 32) then
                                                        evalScore := evalScore + (((63 - pLoc) div 8) *
                                                                     50);
                     {check for pawn promotion}
                                                    if pLoc <= 7 then
                                                        evalScore := evalScore + 1000;
                     {check pawn support}
                                                    if pLoc < 55 then
                                                        begin
                                                            for l := 0 to 1 do
                                                                begin
                                                                    offset2 := FILEBLANK + (56 * l);;
                                                                    DataOps(2, startPage, dataSize,
                                                                            offset2, bit4);
                                                                    BitAnd(bit2, bit4, bit4);
                                                                    if not(IsClear(bit4)) then
                                                                        begin
                                                                            if l = 0 then
                                                                                offset2 := PIECELOC + ((
                                                                                           pLoc + 9) * 8
                                                                                           )
                                                                            else
                                                                                offset2 := PIECELOC + ((
                                                                                           pLoc + 7) * 8
                                                                                           );
                                                                            DataOps(2, startPage,
                                                                                    dataSize, offset2,
                                                                                    bit4);
                                                                            DataOps(2, startPage,
                                                                                    dataSize, initOffset
                                                                                    , bit5);
                                                                            BitAnd(bit5, bit4, bit4);
                                                                            if not(IsClear(bit4)) then
                                                                                evalScore := evalScore +
                                                                                             15;
                                                                        end;
                                                                end;
                                                        end;

                     {doubled pawns penalty}
                                                    if pLoc > 7 then
                                                        begin
                                                            offset2 := PIECELOC + ((pLoc - 8) * 8);
                                                            DataOps(2, startPage, dataSize, offset2,
                                                                    bit4);
                                                            BitAnd(bit1, bit4, bit4);
                                                            if not(IsClear(bit4)) then
                                                                evalScore := evalScore - 25;
                                                        end;
                                                end;

                   {apply piece square table offset}
                                            DataOps(2, sPage1, dSize, offset1, l);
                                            evalScore := evalScore + l;
                                        end;
                                        8: 
                                        begin
                                            evalScore := evalScore + 525;
                                        end;
                                        16: 
                                        begin
                                            evalScore := evalScore + 400;
                   {apply piece square table offset}
                                            offset1 := KNIGHT + (pLoc * 2);
                                            DataOps(2, sPage1, dSize, offset1, l);
                                            evalScore := evalScore + l;
                                        end;
                                        24: 
                                        begin
                                            evalScore := evalScore + 400;
                   {apply piece square table offset}
                                            offset1 := BISHOP + (pLoc * 2);
                                            DataOps(2, sPage1, dSize, offset1, l);
                                            evalScore := evalScore + l;
                                        end;
                                        32: 
                                        begin
                                            evalScore := evalScore + 973;
                                        end;
                                        40: 
                                        begin
                   {apply piece square table offset}
                                            if endGame > 0 then
                                                offset1 := KINGEND + (pLoc * 2)
                                            else
                                                offset1 := KINGMID + (pLoc * 2);
                                            DataOps(2, sPage1, dSize, offset1, l);
                                            evalScore := evalScore + l;
                   {apply castling bonus}
                                            if (cMoveFlag = 1) and (side = gameSide) then
                                                evalScore := evalScore + 300;
                                        end;
                                    end;
                                end;
                        end;
                    j := j + 8;
                until j > 40;

        {own king immediate check penalty}
                if IsClear(bit1) then
                    evalScore := -20000
                else
                    begin
          {bonus for checking opposite king}
                        if side = 0 then
                            offset := TBKO
                        else
                            offset := TWKO;

                        DataOps(2, startPage, dataSize, offset, bit1);
                        if IsClear(bit1) then
                            evalScore := evalScore + 50;

          {encourage moving opposite king to board edge}
                        if endGame > 0 then
                            begin
                                if side = 0 then
                                    offset := TBKO
                                else
                                    offset := TWKO;
                                DataOps(2, startPage, dataSize, offset, bit1);
                                offset := KINGEDGE;
                                DataOps(2, sPage1, dataSize, offset, bit2);
                                BitAnd(bit1, bit2, bit3);
                                if not(IsClear(bit3)) then
                                    evalScore := evalScore + 100;

            {move own king toward opposite king when <=4 pieces left}
                                if endGame = 2 then
                                    begin
                                        BitPos(bit1, locArray);
                                        if not(abs(pLoc - locArray[1]) in[2, 15, 16, 17]) then
                                            begin
                                                evalScore := evalScore + ((8 - (abs(pLoc - locArray[1])
                                                             div 2)) * 10);
                                            end;
                                    end;
                            end;
                        l_1: 
                    end;

        {calculate side's final score}
                if side = 0 then
                    wScore := wScore + evalScore
                else
                    bScore := bScore + evalScore;
            end;

     {final position score}
        Evaluate := wScore - bScore;

    end;

end.
