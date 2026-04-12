unit Main;

interface

procedure chainMain;

implementation
// uses random,

uses 
    globals, genmove, trimprocs, ui, pmove, utility, resources, logger;

var 
    cWarning, gameSide, humanSide: integer;


procedure SaveMove;
    begin
    end;

procedure initGame (var mainBoard: TBoardRecord);
    var
        ans: integer;
    begin
        // Randomize;	// TODO
//        gameSide := 0;
//        gameMove := 1;

        write(chr(7), 'enter ply: [1-6] ');
        repeat
            ans := GetKeyInt;
        until ans in[49..54];
        writeln(chr(ans));
        gamePly := ans - 48;

        writeln(chr(7), 'select side to play: [w]hite/[b]lack');
        repeat
            ans := GetKeyInt;
        until ans in[66, 87];
        if ans = 66 then
            begin
                humanSide := 1;
                writeln('***playing as black***');
            end
        else
            begin
                humanSide := 0;
                writeln('***playing as white***');
            end;
            
        cWarning := 0;
        write(chr(7), 'enter position? (y/n)');
        repeat
            ans := GetKeyInt;
        until ans in[78, 89];
        if ans = 89 then
            begin
                EnterPos (mainBoard, gameside);
//                gameSide := turn;	<->
               {look for check condition}
               
(* TODO: check cehck               
                lastMove .id := 0;
                lastMove.startSq := 0;
                lastMove.endSq := 0;
                CombineTrim(bit3, bit5, lastMove, mainBoard);
                if gameSide = 0 then
                    offset := WKO
                else
                    offset := BKO;
                DataOps(2, startPage, dataSize, offset, bit1);
                if gameSide = 0 then
                    BitAnd(bit1, bit5, bit2)
                else
                    BitAnd(bit1, bit3, bit2);
                if not(IsClear(bit2)) then
                    cWarning := 1;
*)                    
            end
        else
            gameSide := 0;	// turn := gameside

        writeln;            
        write(chr(7), 'debug log to DSK0.phoenix.log (y/n)');
        repeat
            ans := GetKeyInt;
        until ans in[78, 89];
        if ans = 89 then
            startLogging ('DSK0.phoenix.log');
            
        writeln;
        write ('QS deepening (0-9/u)');
        repeat
            ans := getKeyInt
        until ans in [48..57, 85];
        if ans = 85 then 
            plyQS := -Maxint
        else 
            plyQS := 1 - (ans - 48)
    end;

function isMate (turn: integer; var board: TBoardRecord): boolean;
    var
        tempBoard: TBoardRecord;
    begin
        result := true;
        createAllMoves (board, 1, turn, 0);
        while result and (moveStackPointer > 0) do
            begin
                tempBoard := board;
                dec (moveStackPointer);
                enterMoveSimple (turn, tempBoard, moveStack [moveStackPointer]);
                result := isKingChecked (turn, tempBoard)
            end
    end;
    
procedure chainMain;
    var mainBoard: TBoardRecord;
        compressedBoard: TCompressedBoard;
        checkFlag: boolean;
        playMove: TMoveScoreRecord;
        dummy: integer;

    begin
        setInitPosition (mainboard, gameSide, gameMove);
        initGame (mainBoard);

     {start game}
        BoardDisplay (mainBoard);
        if cWarning = 1 then
            begin
                gotoxy(20, 1);
                write(chr(7), chr(7), 'check!');
            end;

        repeat
        
            gotoxy(10, 1);
            writeln('move: ', gameMove);
            if gameSide = 0 then
                write('turn: white')
            else
                write('turn: black');
        
            if humanSide = gameSide then
                {TODO: save current game state}
                playerMove (mainBoard, playMove.move, gameSide, humanSide);	// may change game side
            if humanSide <> gameSide then
                begin
                    gotoxy(20, 7);
                    write('thinking...');
                    playMove := generateMove (gamePly, gameSide, mainBoard);
                    
                    if playMove.move.pieceType = InvalidPiece then
                        begin
                            gotoxy(20, 1);
                            write(chr(7), chr(7), 'stalemate!');
                            readln;
                            Utility (dummy);
                            exit                            
                        end
                end;
                
            {update move list}
(*            
        TODO: save move history
            sPage := BASE2;
            dataSize := 8;
            offset := PLAYLIST + gamePointer;
            DataOps(1, sPage, dataSize, offset, playMove);
            gamePointer := gamePointer + 8;
            moveStore.id := 99;
            offset := offset + 8;
            DataOps(1, sPage, dataSize, offset, moveStore);
*)            

            enterMoveSimple (gameSide, mainBoard, playMove.move);
            enterPositionHash (playMove.move, mainBoard.hash);

            BoardDisplay (mainBoard);
            
            if isThreeFoldRepetition then
                begin
                    gotoxy (20, 2);
                    write ('3-fold rep')
                end;

            {look for check condition}
            checkFlag := isKingChecked (1 - gameSide, mainBoard);
            if checkFlag then
                begin
                    gotoxy(20, 1);
                    write(chr(7), chr(7), 'check!');
                    cWarning := 1;
                end;

            {look for checkmate or stalemate condition}
            if checkFlag then
                if isMate (1 - gameSide, mainBoard) then
                    begin
                        gotoxy(20, 1);
                        write(chr(7), chr(7), 'checkmate!');
                        readln;
                        Utility (dummy);
                        exit;
                    end
                else if abs (playMove.Score) >= infinity then
                    begin
                        gotoxy(20, 1);
                        write(chr(7), chr(7), 'resign!');
                        readln;
                        Utility (dummy);
                        exit;
                    end;
                
            inc (gameMove, gameSide);	// add 1 if black
            showMove (playMove, gameSide = humanSide);
            gameSide := 1 - gameSide;

//            check3Rep;

        until FALSE;
    end;

end.
