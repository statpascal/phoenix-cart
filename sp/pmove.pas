unit pmove;

interface

uses globals, board;

procedure PlayerMove (var board: TBoardRecord; var playMove: TMoveRecord; turn: integer);

implementation

uses trimprocs, ui, utility;

procedure clearEntryField;
    begin
        soundBell;
        gotoxy (whereX - 2, whereY);
        write ('  ');
        gotoxy (whereX - 2, whereY)
    end;
            
procedure PlayerMove (var board: TBoardRecord; var playMove: TMoveRecord; turn: integer);
    label 
        l_1, l_2;
    var 
        i, j, k, iLoc, eLoc, switchState, ans: integer;
        validSq, foundFlag: boolean;
        fn: string [20];
        castleRights, epCapDummy: integer;
        playerPieces, bits: bitboard;
        workBoard: TBoardRecord;
                
    begin
        l_1: 
        workBoard := board;
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
                playerPieces := workBoard.white.pieces
            else
                playerPieces := workBoard.black.pieces;
            validSq := getBit (playerPieces, iLoc) <> 0;
            if not validSq then
                clearEntryField
        until validSq;

        playMove.startSq := iLoc;
        playMove.pieceType := findPieceType (workBoard, turn, iLoc);

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
            if getBit (playerPieces, eLoc) = 0 then
                begin
                    {check if castling move}
                    if (playMove.pieceType = King) and (abs(iLoc - eLoc) = 2) then
                        begin
                            castleRights := checkCastleRights (workBoard, turn);
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
                            bits := Trim (turn, playMove.pieceType, iLoc, workBoard, epCapDummy);
                            validSq := getBit (bits, eLoc) <> 0
                        end
                end;

            if not validSq then
                clearEntryField
        until validSq;
        
        playMove.endSq := eLoc;

        {verify if own king in check after move}
        enterMoveSimple (turn, workBoard, playMove);
        if isKingChecked (turn, workBoard) then
            begin
                {king in check. undo move}
                validSq := FALSE;
                clearEntryField;
                workBoard := board;
                goto l_2;
            end;
    end; {playerMove}

end.
