program testphoenix;

uses
    globals, board, move, logger;

var
    board: TBoardRecord;
    side, movenr: integer;
    
const
    ply = 6;
    
procedure answerUciInit;
    begin
        writeln ('id name PHOENIX-', versionString);
//        writeln ('id author Vorticon');
//        writeln ('option name OwnBook type check default true');
        writeln ('uciok')
    end;
    
procedure calcMove (side: integer);
    var
        null: moverec;
        score: integer;
        move: moverec;
        
    procedure writeCoord (sq: integer);
        begin
            write (chr (97 + sq and 7));
            write (chr (49 + sq shr 3))
        end;
        
    begin
        fillChar (null, sizeof (null), 0);
        MoveGen (board, null, move, score, 0, -20000, 20000, ply, side);
        write ('bestmove ');
        writeCoord (move.startSq);
        writeCoord (move.endSq)
    end;

procedure handlePosition (s: string);
    var
        index: integer;
        t: string;
        isMoves: boolean;
        
    function interpretMove (t: string; side: integer; var move: moverec): boolean;
        begin
            if (length (t) >= 4) and
               (t [1] in ['a'..'h']) and (t [2] in ['1'..'8']) and
               (t [3] in ['a'..'h']) and (t [4] in ['1'..'8']) then
                begin
                    move.startSq := ord (t [1]) - ord ('a') + 8 * (ord (t [2]) - ord ('1'));
                    move.endSq   := ord (t [3]) - ord ('a') + 8 * (ord (t [4]) - ord ('1'));
                    move.id := findPieceType (board, side, move.startSq);
                    interpretMove := true
                end
            else
                interpretMove := false
        end;
        
    procedure handle (t: string);
        var
            move: moverec;
        begin
            if t = 'startpos' then
                setInitPosition (board, side, movenr);
            if t = 'moves' then
                isMoves := true;
            if isMoves and interpretMove (t, side, move) then
                begin
                    enterMoveSimple (side, board, move);
                    inc (movenr, side);
                    side := 1 - side
                end
        end;
        
    begin
        index := 9;
        isMoves := false;
        repeat
            while (index <= length (s)) and (s [index] = ' ') do
                inc (index);
            t := '';
            while (index <= length (s)) and (s [index] <> ' ') do
                begin
                    t := t + s [index];
                    inc (index)
                end;
            if t <> '' then
                handle (t)
        until index > length (s)
    end;

procedure commandLoop;
    var
        s: string;
    begin
        writeln ('PHOENIX Chess');
        repeat
            readln (s);
            if s = 'uci' then
                answerUciInit;
            if s = 'isready' then
                writeln ('readyok');
            if copy (s, 1, 8) = 'position' then
                handlePosition (s);
            if copy (s, 1, 2) = 'go' then
                calcMove (side);
            flush (output)
//            if s = 
        until s = 'quit'
    end;

procedure testPosition (fenStr, move: string; ply, qsdeepening: integer);
    const
        alpha = -20000;
        beta = 20000;

    var 
        mainBoard: TBoardRecord;
        lastMove, playMove: moverec;
        moveScore: integer;

    begin
        setFENPosition (mainBoard, gameSide, gameMove, fenStr);
        gamePly := ply;
        plyQS := 1 - qsdeepening;
        fillChar (lastMove, sizeof (lastMove), 0);

        writeln ('Analyzing: ', fenStr);
//        startLogging ('ticket.log');
        MoveGen (mainBoard, lastMove, playMove, moveScore, 0, alpha, beta, gamePly, gameSide);
        printMove (output, playMove);
//        writeln (' ', move);
//        stopLogging;
    end;

begin
    plyQs := -3;
    commandLoop
end.
