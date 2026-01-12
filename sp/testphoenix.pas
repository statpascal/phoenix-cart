program testphoenix;

uses
    globals, board, genmove, logger;

procedure testPosition (fenStr, move, log: string; ply, qsdeepening: integer);
    const
        alpha = -20000;
        beta = 20000;

    var 
        mainBoard: TBoardRecord;
        lastMove, playMove: TMoveRecord;
        moveScore: integer;

    begin
        setFENPosition (mainBoard, gameSide, gameMove, fenStr);
        gamePly := ply;
        plyQS := 1 - qsdeepening;
        fillChar (lastMove, sizeof (lastMove), 0);

        writeln ('Analyzing: ', fenStr);
        if log <> '' then
            startLogging (log);
        generateMove (ply, gameSide, mainBoard, playMove, moveScore);
        printMove (output, playMove);
        if move <> '' then
            write (', should be: ', move);
        writeln;
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


procedure evalTests;
    begin
    writeln ('Starting tests');
    testPosition ('rnbqkbnr/ppp1pppp/8/3p4/4P3/3P4/PPP2PPP/RNBQKBNR b KQkq - 0 2', 'PD5-E4', 'DSK0.opening-ply3.log', 3, 2);    
    testPosition ('r1b4r/pp1p2pp/7k/5Q2/8/2PB4/P4PPP/2K1R2R w - - 0 40', 'QF5-H3', 'DSK0.queen-h5-ply4.log', 3, 2);
    testPosition ('4k3/8/8/8/8/8/1B2P3/R3K3 b Q - 0 40', '', 'DSK0.castle-ply3.log', 3, 2);
    testPosition ('rnb1kb1r/ppp1pppp/4qn2/8/3P4/2N5/PPP1BPPP/R1BQK1NR w KQkq - 0 40', '', 'DSK0.knight-lost-ply4.log', 3, 2);
    testPosition ('8/P7/8/8/8/4k3/8/4K3 w - - 0 40', 'PA/-A8Q', 'DSK0.promotion-1.log', 2, 0);
    testPosition ('b7/k1P5/p7/8/8/8/3K4/1R6 w - - 0 40', '', 'DSK0.promotion-knight.log', 4, 0);
    testPosition ('8/4k3/8/8/8/8/p6K/8 w - - 0 40', '', 'DSK0.promotion-2.log', 4, 0);

    
    disableAlphaBetaPruning := true;
    testPosition ('4k3/p1p3p1/8/1P5P/1p1p4/8/P1P1P3/4K3 w - - 0 10', '', 'DSK0.ep-test.log', 3, 0);
    disableAlphaBetaPruning := false;

//    testPosition ('r3k2r/1pp2ppp/p2bbn2/4N3/4P3/2N1B3/PPP1B1PP/R1K4R b kq - 0 12', 'BD6-E5', 'DSK0.ticket1.log', 4, 7);
//    testPosition ('rn1qkb1r/ppp1pppp/4b3/4P3/2pP2n1/N4N2/PP3PPP/R1BQKB1R b KQkq - 2 6', 'PC7-C5', 'DSK0.ticket2.log', 4, 7);
    writeln;
    writeln ('** DONE **');    end;


  
begin
//    BratkoKopecTest;
//    testPosition ('rnbqkbnr/ppp1pppp/8/3p4/4P3/3P4/PPP2PPP/RNBQKBNR b KQkq - 0 2', '', 'DSK0.opening-ply3.log', 3, 2);
    evalTests
end.
