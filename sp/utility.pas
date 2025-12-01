unit utility;

interface

procedure saveGame (gname: string; showMsg: boolean);
procedure Utility(var switch: integer);


implementation

uses globals, ui;

procedure UpdateBoard(gBase, gOffset: integer);
    var 
        offset: integer;
        buffer: array[0..59] of integer;

    begin
        startPage := gBase;
        dataSize := 120;
        offset := gOffset;
        DataOps(2, startPage, dataSize, offset, buffer);
        startPage := BASE;
        offset := WPO;
        DataOps(1, startPage, dataSize, offset, buffer);

        BoardDisplay;
        gotoxy(0, 2);
        if gameSide = 0 then
            write('turn: white')
        else
            write('turn: black');

        gotoxy(10, 1);
        write('move: ', gameMove);

        gotoxy(20, 1);
        if cWarning = 1 then
            write(chr(7), chr(7), 'check!')
        else
            write('      ');

        dataSize := 8;
    end;

procedure ClearFields;
    var 
        y: integer;
    begin
        for y := 3 to 13 do
            begin
                gotoxy(20, y);
                write('                ');
            end;
    end;

procedure saveGame (gname: string; showMsg: boolean);
    var
        gamefile: file of integer;
        ioCheck: integer;
        i, startPage, offset, storePtr, storeBase: integer;
        mBuffer: array[0..2048] of integer;
        gBuffer: array[0..67] of integer;
    
    begin    
    (*
        startPage := BASE2;
        dataSize := 2;
        offset := 4000;
        DataOps(2, startPage, dataSize, offset, storePtr);
        offset := 4002;
        DataOps(2, startPage, dataSize, offset, storeBase);
        assign (gamefile, gname);
        rewrite (gamefile);
        //        rewrite(gamefile, gname);
        ioCheck := IORESULT;
        if ioCheck = 0 then
            begin
                if showMsg then begin
                    gotoxy(20, 11);
                    write('saving...');
                end;
                startPage := BASE2;
                dataSize := 4096;
                offset := 0;
                DataOps(2, startPage, dataSize, offset, mBuffer);
                for i := 0 to 2047 do
                    begin
                        write (gamefile, mBuffer [i]);
                        //            gamefile^ := mBuffer[i];
                        //            put(gamefile);
                    end;
                startPage := BASE4;
                dataSize := 136;
                offset := 0;

                write (gamefile, storePtr);
                //          gamefile^ := storePtr;
                //          put(gamefile);
                write (gamefile, storeBase);
                //          gamefile^ := storeBase;
                //          put(gamefile);
                write (gamefile, gamePly);
                //          gamefile^ := gamePly;
                //          put(gamefile);
                write (gameFile, gameSide);
                //          gamefile^ := gameSide;
                //          put(gamefile);
                write (gameFile, gamePointer);
                //          gamefile^ := gamePointer;
                //          put(gamefile);

                repeat
                    DataOps(2, startPage, dataSize, offset, gBuffer);
                    for i := 0 to 67 do
                        begin
                            write (gamefile, gBuffer [i]);
                            //             gamefile^ := gBuffer[i];
                            //             put(gamefile);
                        end;
                    offset := offset + 136;
                    if offset > 4079 then
                        begin
                            startPage := succ(startPage);
                            offset := 0;
                        end;
                until (offset = storePtr) and (startPage = storeBase);
                close(gamefile);
            end
        else
            begin
                gotoxy(20, 11);
                write(chr(7), chr(7), 'file error #', ioCheck);
                readln;
            end;
        if showMsg then begin
            gotoxy(20, 10);
            write('                  ');
            gotoxy(20, 11);
            write('           ')
        end
*)        
    end;

procedure Utility(var switch: integer);
    label 
        l_1, l_2;
    var 
        y, i, ans, offset, storeBase, storePtr, tmpPtr, tmpBase, ioCheck: integer;
        tempGPointer: integer;
        utilFlag: boolean;
        gBuffer: array[0..67] of integer;
        mBuffer: array[0..2048] of integer;
        gname: string;
        tempStore: moverec;
        gamefile: file of integer;

    begin
        tempGPointer := gamePointer;
        utilFlag := FALSE;
        switch := 0;
        startPage := BASE2;
        dataSize := 2;
        offset := 4000;
        DataOps(2, startPage, dataSize, offset, storePtr);
        offset := 4002;
        DataOps(2, startPage, dataSize, offset, storeBase);
        tmpPtr := storePtr - 136;
        tmpBase := storeBase;

        repeat
            gotoxy(20, 3);
            write('[1] load game');
            gotoxy(20, 4);
            write('[2] save game      ');
            gotoxy(20, 5);
            write('[3] backup');
            gotoxy(20, 6);
            write('[4] forward');
            gotoxy(20, 7);
            write('[5] first move');
            gotoxy(20, 8);
            write('[6] last move');
            gotoxy(20, 9);
            write('[7] switch sides');
            gotoxy(20, 10);
            write('[8] change ply');
            gotoxy(20, 11);
            write('[9] play');
            gotoxy(20, 12);
            write('[0] end game');
            gotoxy(20, 13);
            write('[P] print game');
            repeat
                ans := getKeyInt;
            until ans in[48..57, 80];

            ClearFields;

            case ans of 
                80: 
                begin {print}
                    PrintGame;
                end;
                49: 
                begin {load}
(*                
                    gotoxy(20, 9);
                    write('file name: ');
                    ans := ord (getKeyInt ());
                    gotoxy(20, 10);
                    readln(gname);
            {$I-}
                    assign (gamefile, gname);
                    reset (gamefile);
                    //        reset(gamefile, gname);
                    ioCheck := IORESULT;
            {$I+}
                    if ioCheck = 0 then
                        begin
                            gotoxy(20, 11);
                            write('loading...');
                            startPage := BASE2;
                            dataSize := 4096;
                            offset := 0;
                            for i := 0 to 2047 do
                                begin
                                    read (gamefile, mBuffer [i])
                                    //            mBuffer[i] := gamefile^;
                                    //            get(gamefile);
                                end;
                            DataOps(1, startPage, dataSize, offset, mBuffer);

                            read (gamefile, storePtr);
                            //          storePtr := gamefile^;
                            //          get(gamefile);
                            read (gamefile, storeBase);
                            //          storeBase := gamefile^;
                            //          get(gamefile);
                            read (gamefile, gamePly);
                            //          gamePly := gamefile^;
                            //          get(gamefile);
                            read (gamefile, gameSide);
                            //          gameSide := gamefile^;
                            //          get(gamefile);
                            read (gameFile, gamePointer);
                            //          gamePointer := gamefile^;

                            tempGPointer := gamePointer;
                            tmpPtr := storePtr - 136;
                            tmpBase := storeBase;

                            startPage := BASE2;
                            dataSize := 2;
                            offset := 4000;
                            DataOps(1, startPage, dataSize, offset, storePtr);
                            offset := 4002;
                            DataOps(1, startPage, dataSize, offset, storeBase);

                            startPage := BASE4;
                            dataSize := 136;
                            offset := 0;
                            repeat
                                for i := 0 to 67 do
                                    begin
                                        read (gamefile, gBuffer [i]);
                                        //             get(gamefile);
                                        //             gBuffer[i] := gamefile^;
                                    end;

                                DataOps(1, startPage, dataSize, offset, gBuffer);
                                offset := offset + 136;
                                if offset > 4079 then
                                    begin
                                        offset := 0;
                                        startPage := succ(startPage);
                                    end;
                            until (offset = storePtr) and (startPage = storeBase);

                            wCastleFlag := gBuffer[60];
                            bCastleFlag := gBuffer[61];
                            wRookLFlag := gBuffer[62];
                            wRookRFlag := gBuffer[63];
                            bRookLFlag := gBuffer[64];
                            bRookRFlag := gBuffer[65];
                            cWarning := gBuffer[66];
                            gameMove := gBuffer[67];
                            if storePtr > 0 then
                                UpdateBoard(storeBase, storePtr - 136)
                            else
                                UpdateBoard(pred(storeBase), 3943);
                            close(gamefile);
                        end
                    else
                        begin
                            gotoxy(20, 10);
                            write(chr(7), chr(7), 'file error #', ioCheck);
                            readln;
                        end;
                    gotoxy(20, 10);
                    write('                  ');
                    gotoxy(20, 11);
                    write('           ');
*)                    
                end;
                50: 
                begin {save}
                    gotoxy(20, 9);
                    write('file name: ');
                    ans := getKeyInt;
                    gotoxy(20, 10);
                    readln(gname);
                    saveGame (gname, true)
                end;
                51:                 
                begin {backup}
(*                
                    tmpPtr := tmpPtr - 136;
                    if tmpPtr < 0 then
                        begin
                            tmpBase := pred(tmpBase);
                            tmpPtr := 0;
                        end;
                    if tmpBase < 24 then
                        begin
                            tmpBase := 24;
                            writeln(chr(7));
                        end
                    else
                        begin
                            tempGPointer := tempGPointer - 16;
                            if tempGPointer < 0 then
                                tempGPointer := 0;
                            l_2: 
                            dataSize := 16;
                            offset := tmpPtr + 120;
                            dataOps(2, tmpBase, dataSize, offset, gBuffer);
                            wCastleFlag := gBuffer[0];
                            bCastleFlag := gBuffer[1];
                            wRookLFlag := gBuffer[2];
                            wRookRFlag := gBuffer[3];
                            bRookLFlag := gBuffer[4];
                            bRookRFlag := gBuffer[5];
                            cWarning := gBuffer[6];
                            gameMove := gBuffer[7];
                            UpdateBoard(tmpBase, tmpPtr);
                        end;
*)                        
                end;
                52: 
                begin {forward}
(*                
                    if (tmpBase <> storeBase) or ((tmpBase = storeBase) and
                       (tmpPtr < (storePtr - 136))) then
                        begin
                            tempGPointer := tempGPointer + 16;
                            if tempGPointer > gamePointer then
                                tempGPointer := gamePointer;
                            tmpPtr := tmpPtr + 136;
                            if tmpPtr > 4079 then
                                begin
                                    tmpBase := succ(tmpBase);
                                    tmpPtr := 0;
                                end;
                            goto l_2;
                        end
                    else
                        writeln(chr(7));
*)                        
                end;
                54: 
                begin {last move}
(*                
                    tempGPointer := gamePointer;
                    tmpPtr := storePtr - 136;
                    tmpBase := storeBase;
                    goto l_2;
*(                    
                end;
                53: 
                begin {first move}
(*                
                    tempGPointer := 0;
                    tmpPtr := 0;
                    tmpBase := 24;
                    goto l_2;
*)                    
                end;
                55: 
                begin {switch sides}
                    if humanSide = 0 then
                        humanSide := 1
                    else
                        humanSide := 0;
                    switch := 1;
                    goto l_1;
                end;
                56: 
                begin {change ply}
                    ClearFields;
                    repeat
                        gotoxy(20, 10);
                        write(chr(7), 'ply: ');
                        ans := getKeyInt;
                        readln(gamePly);
                    until gamePly in[1..6];
//                    ply := gamePly;
                    gotoxy(0, 1);
                    write('ply : ', gamePly);
                    ClearFields;
                end;
                57: 
                begin {play}
                    l_1: 
                    storeBase := tmpBase;
                    storePtr := tmpPtr + 136;
                    startPage := BASE2;
                    dataSize := 2;
                    offset := 4000;
                    DataOps(1, startPage, dataSize, offset, storePtr);
                    offset := 4002;
                    DataOps(1, startPage, dataSize, offset, storeBase);
                    utilFlag := TRUE;
                    turn := gameSide;
                    gamePointer := tempGPointer;
                    tempStore.id := 99;
                    startPage := BASE2;
                    dataSize := 8;
                    offset := PLAYLIST + gamePointer;
                    DataOps(1, startPage, dataSize, offset, tempStore);
                    ClearFields;
                end;
                48: 
                begin {end game}
                    ClearFields;
                    gotoxy(20, 10);
                    write(chr(7), 'end game? [y/n]');
                    repeat
                        ans := getKeyInt;
                    until ans in[89, 78];
                    if ans = 89 then
                        begin
                            pieceCount := -1;
                            utilFlag := TRUE;
                        end;
                    ClearFields;
                end;
            end;
            startPage := BASE;
            dataSize := 8;
        until utilFlag;
    end;

end.
