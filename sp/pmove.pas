unit pmove;

interface

uses globals;

procedure PlayerMove(var playMove : moverec; lastMove: moverec; pturn: integer);

implementation

uses trimprocs, ui, utility;


const
    gameSaveChar: char = 'A';

procedure PlayerMove(var playMove: moverec; lastMove: moverec; pturn: integer);
    label 
        l_1, l_2;
    var 
        i, j, k, iLoc, eLoc, initOffset, offset, offset1, ans: integer;
        sideOffset, offset2, offset3, offset4, switchState: integer;
        validSq, foundFlag: boolean;
        fn: string [20];
        castleRights, epCapDummy: integer;
    begin
        turn := pturn;
        startPage := BASE;
        dataSize := 8;

     {back up current game state}
        for i := 0 to 14 do
            begin
                offset := WPO + (i * 8);
                DataOps(2, startPage, dataSize, offset, bit1);
                offset := TWPO + (i * 8);
                DataOps(1, startPage, dataSize, offset, bit1);
            end;
(*
        if savePositions then 
            begin            
                fn := 'DSK0.GAME';
                fn [10] := gameSaveChar;
                inc (fn [0]);
                gotoxy (0, 23);
                write ('Saving position to: ', fn);
                saveGame (fn, false);
                inc (gameSaveChar);
                if gameSaveChar = succ ('Z') then
                    gameSaveChar := 'a'
            end;
*)
        l_1: 
        gotoxy(20, 6);
        write(chr(7), 'enter move');
        gotoxy(20, 7);
        write('              ');
        gotoxy(20, 7);
     {get start square}
        validSq := FALSE;
        repeat
            gotoxy(20, 7);
            write('from: ');
            repeat
                ans := getKeyInt;
            until ans in[65..72, 84, 85];

      {utility menu}
            if ans = 85 then
                begin
                    Utility(switchState);
                    if switchState = 1 then
                        if humanSide <> gameSide then
                            exit;
                    if pieceCount = -1 then
                        exit;
                    goto l_1;
                end;

            iLoc := ans - 65;
            write(chr(ans));
            repeat
                ans := getKeyInt;
            until ans in[49..56, 82];
            if ans = 82 then
                goto l_1;
            iLoc := iLoc + ((ans - 49) * 8);
            write(chr(ans));

      {validate square}
            if turn = 0 then
                begin
                    offset := WPIECES;
                    sideOffset := offset;
                end
            else
                begin
                    offset := BPIECES;
                    sideOffset := offset;
                end;

            DataOps(2, startPage, dataSize, offset, bit1);
            offset := PIECELOC + (iLoc * 8);
            DataOps(2, startPage, dataSize, offset, bit2);
            BitAnd(bit1, bit2, bit3);
            if not(IsClear(bit3)) then
                validSq := TRUE
            else
                write(chr(7), chr(8), chr(8));
            write('  ', chr(8), chr(8));
        until validSq = TRUE;

        playMove.startSq := iLoc;
     {determine piece type}
        i := 0;
        foundFlag := FALSE;
        if turn = 0 then
            initOffset := WPO
        else
            initOffset := BPO;
        repeat
            offset := initOffset + i;
            DataOps(2, startPage, dataSize, offset, bit3);
            BitAnd(bit3, bit2, bit3);
            if not(IsClear(bit3)) then
                begin
                    foundFlag := TRUE;
                    playMove.id := i;
                end
            else
                i := i + 8
        until foundFlag = TRUE;

        l_2: 
     {get end square}
        validSq := FALSE;
        repeat
            gotoxy(30, 7);
            write('to: ');
            repeat
                ans := getKeyInt;
            until ans in[65..72, 82];
            if ans = 82 then
                goto l_1;
            eLoc := ans - 65;
            write(chr(ans));
            repeat
                ans := getKeyInt;
            until ans in[49..56, 82];
            if ans = 82 then
                goto l_1;
            eLoc := eLoc + ((ans - 49) * 8);
            write(chr(ans));

      {validate end square}
            offset := PIECELOC + (eLoc * 8);
            DataOps(2, startPage, dataSize, offset, bit3);
            BitAnd(bit1, bit3, bit1);

            if IsClear(bit1) then
                begin
        {check if castling move}
                    if (playMove.id = 40) and (abs(iLoc - eLoc) = 2) then
                        begin
    {player castling move check}

                            castleRights := checkCastleRights (mainBoard, castleFlags, turn);

                            if turn = 0 then
                                begin
                                    if (((iLoc - eLoc) > 0) and (castleRights and whiteLeftCastleRight <> 0)) or
                                       (((iLoc - eLoc) < 0) and (castleRights and whiteRightCastleRight <> 0)) then
                                        validSq := true
                                end
                            else
                                begin
                                    if (((iLoc - eLoc) > 0) and (castleRights and blackLeftCastleRight <> 0)) or
                                       (((iLoc - eLoc) < 0) and (castleRights and blackRightCastleRight <> 0)) then
                                        validSq := true
                                end

                        end
                    else
                        begin
          {trim movement to blocks}
                            bit2 := Trim(turn, playMove.id, iLoc, lastMove, mainBoard, epCapDummy);

                            offset := PIECELOC + (eLoc * 8);
                            DataOps(2, startPage, dataSize, offset, bit3);
                            BitAnd(bit3, bit2, bit3);
                            if not(IsClear(bit3)) then
                                validSq := TRUE
                        end;
                end;

            if not(validSq) then
                begin
                    write(chr(7), chr(8), chr(8));
                    write('  ', chr(8), chr(8));
                end;
        until validSq = TRUE;
        playMove.endSq := eLoc;

     {verify if own king in check after move}
     {update appropriate piece bitboard with move}
        offset := PIECELOC + (iLoc * 8);
        DataOps(2, startPage, dataSize, offset, bit1);
        offset := PIECELOC + (eLoc * 8);
        DataOps(2, startPage, dataSize, offset, bit3);
        BitNot(bit1, bit1);
        offset := APIECES;
        DataOps(2, startPage, dataSize, offset, bit4);
        BitAnd(bit1, bit4, bit4);
        BitOr(bit3, bit4, bit4);
        DataOps(1, startPage, dataSize, offset, bit4);

        if turn = 0 then
            begin
                offset := WPO + playMove.id;
                offset1 := WPIECES;
                offset2 := BPIECES;
            end
        else
            begin
                offset := BPO + playMove.id;
                offset1 := BPIECES;
                offset2 := WPIECES;
            end;
        DataOps(2, startPage, dataSize, offset, bit4);
        BitAnd(bit1, bit4, bit4);
        BitOr(bit3, bit4, bit4);
        DataOps(1, startPage, dataSize, offset, bit4);
        DataOps(2, startPage, dataSize, offset1, bit4);
        BitAnd(bit1, bit4, bit4);
        BitOr(bit3, bit4, bit4);
        DataOps(1, startPage, dataSize, offset1, bit4);

     {remove any potential captures from opposite boards}
        DataOps(2, startPage, dataSize, offset2, bit4);
        BitNot(bit3, bit3);
        BitAnd(bit3, bit4, bit4);
        DataOps(1, startPage, dataSize, offset2, bit4);
        i := 0;
        if turn = 0 then
            offset := BPO
        else
            offset := WPO;
        repeat
            offset1 := offset + i;
            DataOps(2, startPage, dataSize, offset1, bit1);
            BitAnd(bit1, bit3, bit1);
            DataOps(1, startPage, dataSize, offset1, bit1);
            i := i + 8;
        until i > 40;

     {generate combined trimmed movement bitboards}
        CombineTrim(bit3, bit5, lastMove, mainBoard);

     {verify if king in check}
        if turn = 0 then
            offset := WKO
        else
            offset := BKO;
        DataOps(2, startPage, dataSize, offset, bit1);

        if turn = 0 then
            BitAnd(bit1, bit5, bit1)
        else
            BitAnd(bit1, bit3, bit1);

        if not(IsClear(bit1)) then
     {king in check. undo move}
            begin
                for i := 0 to 14 do
                    begin
                        offset := TWPO + (i * 8);
                        DataOps(2, startPage, dataSize, offset, bit1);
                        offset := WPO + (i * 8);
                        DataOps(1, startPage, dataSize, offset, bit1);
                    end;
                validSq := FALSE;
                write(chr(7), chr(8), chr(8), '  ', chr(8), chr(8));
                goto l_2;
            end;
    end; {playerMove}

end.
