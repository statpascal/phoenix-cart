unit pmove;

interface

uses globals, board;

procedure PlayerMove (var board: TBoardRecord; var playMove: TMoveRecord; turn: integer; var humanSide: integer);

implementation

uses trimprocs, ui, utility;

procedure clearEntryField;
    begin
        soundBell;
        gotoxy (whereX - 2, whereY);
        write ('  ');
        gotoxy (whereX - 2, whereY)
    end;
            
procedure PlayerMove (var board: TBoardRecord; var playMove: TMoveRecord; turn: integer; var humanSide: integer);
    label 
        l_1, l_2;
    var 
        i, j, k, iLoc, eLoc, ans: integer;
        validSq, foundFlag: boolean;
        fn: string [20];
        castleRights, epCapDummy: integer;
        playerPieces, bits: bitboard;
        testBoard: TBoardRecord;
                
    begin
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
                    Utility(humanSide);
                    if humanSide <> turn then
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
            validSq := getBit (board.sides [turn].bitboards [SidePieces], iLoc) <> 0;
            if not validSq then
                clearEntryField
        until validSq;

        playMove.startSq := iLoc;
        playMove.pieceType := findPieceType (board, turn, iLoc);
        playMove.flags := 0;

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
            if (playMove.pieceType = King) and (abs(iLoc - eLoc) = 2) then
                begin
                    castleRights := checkCastleRights (board, turn);
                    if turn = 0 then
                        begin
                            if (((iLoc - eLoc) > 0) and (castleRights and whiteLeftCastle <> 0)) or
                               (((iLoc - eLoc) < 0) and (castleRights and whiteRightCastle <> 0)) then
                                validSq := true
                        end
                    else
                        begin
                            if (((iLoc - eLoc) > 0) and (castleRights and blackLeftCastle <> 0)) or
                               (((iLoc - eLoc) < 0) and (castleRights and blackRightCastle <> 0)) then
                                validSq := true
                        end

                end
            else
                begin
                    {trim movement to blocks}
                    bits := Trim (turn, playMove.pieceType, iLoc, board, epCapDummy);
                    validSq := getBit (bits, eLoc) <> 0
                end;

            {verify if own king in check after move}
            if validSq then 
                begin
                    playMove.endSq := eLoc;
                    testBoard := board;
                    enterMoveSimple (turn, testBoard, playMove);
                    if isKingChecked (turn, testBoard) then
                        validSq := false;
                end;
                
            if not validSq then
                clearEntryField
        until validSq;
        
        {promote pawn if applicable}
        if (playMove.pieceType = pawn) and (playMove.endSq in [0..7, 56..63]) then
            begin
                gotoxy (20, 8);
                writeln ('promote pawn to');
                gotoxy (22, 9);
                writeln ('1- rook');
                gotoxy (22, 10);
                writeln ('2- knight');
                gotoxy (22, 11);
                writeln ('3- bishop');
                gotoxy (22, 12);
                writeln ('4- queen');
                repeat
                    ans := GetKeyInt
                until ans in [49..52];
                playMove.flags := (ans - 48) shl 4
            end

    end;

end.
