program testphoenix;

uses
    globals, board, genmove, logger;

procedure testPosition (fenStr, move, log: string; ply, qsdeepening: integer);
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
        if log <> '' then
            startLogging (log);
        MoveGen (mainBoard, lastMove, playMove, moveScore, 0, alpha, beta, gamePly, gameSide);
        printMove (output, playMove);
        if move <> '' then
            writeln (', should be: ', move);
        if log <> '' then
            stopLogging;
    end;

procedure BratkoKopecTest;
    const
        ply = 6;
        qs = 3;
    var
        f: text;
        logFn, fenstr, s, move: string;
        n, count: integer;
    begin
        assign (f, '/home/goose/Downloads/BK.pos');
        reset (f);
        count := 1;
        while not eof (f) do
            begin
                readln (f, s);
                n := pos (' ', s);
                fenstr := copy (s, 1, pred (n));
                fenstr [length (fenstr) - 1] := ' ';
                fenstr := fenstr + ' - - 0 10';
                move := copy (s, succ (n), 4);
                str (count, logFn);
                inc (count);
//                logFn := 'DSK0.KP-' + logFn + '.log';
                logFn := '';
                testPosition (fenstr, move, logFn, ply, qs);
                writeln
            end;
        close (f)
    end;

(*    
procedure evalTests;
    const
        ply = 4;
        qs = 2;
    var
        f: text;
        pos, move: string;
    begin
        assign (f, 'testpos/tests.txt');
        reset (f);
        while not eof (f) do
            begin
                readln (f, pos);
//                readln (f, move));
                testPosition (pos, move, ply, qs)
            end;
        close (f)
    end;
*)


  
begin
//    BratkoKopecTest;

//    writeln ('Starting tests');
    testPosition ('rnbqkbnr/ppp1pppp/8/3p4/4P3/3P4/PPP2PPP/RNBQKBNR b KQkq - 0 2', '', 'DSK0.opening-ply3.log', 3, 2);
//    evalTests
    
    

end.
