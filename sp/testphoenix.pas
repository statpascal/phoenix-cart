program testphoenix;

uses
    globals, board, move, logger;

procedure testPosition (fenStr, logfn: string; ply, qsdeepening: integer);
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

{$ifdef ti99}        
        startLogging (logfn);
{$endif}
{$ifdef fpc}
        startLogging (copy (logfn, 6, 100));
{$endif}        
        writeln ('Analyzing: ', fenStr);
        MoveGen (mainBoard, lastMove, playMove, moveScore, 0, alpha, beta, gamePly, gameSide);
        printMove (output, playMove);
        writeln (' ', moveScore);
        writeln;
        stopLogging
    end;

procedure BratkoKopecTest;
    const
        ply = 5;
        qs = 4;
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
                logFn := 'DSK0.KP-' + logFn + '.log';
                testPosition (fenstr, logFn, ply, qs);
                writeln (', should be: ', move);
                writeln
            end;
        close (f)
    end;
  
begin
//    BratkoKopecTest;

    writeln ('Starting tests');

    testPosition ('rnbqkbnr/ppp1pppp/8/3p4/4P3/3P4/PPP2PPP/RNBQKBNR b KQkq - 0 2', 'DSK0.opening-ply3.log', 3, 2);    
    testPosition ('r1b4r/pp1p2pp/7k/5Q2/8/2PB4/P4PPP/2K1R2R w - - 0 40', 'DSK0.queen-h5-ply4.log', 3, 2);
    testPosition ('4k3/8/8/8/8/8/1B2P3/R3K3 b Q - 0 40', 'DSK0.castle-ply3.log', 3, 2);
    testPosition ('rnb1kb1r/ppp1pppp/4qn2/8/3P4/2N5/PPP1BPPP/R1BQK1NR w KQkq - 0 40', 'DSK0.knight-lost-ply4.log', 3, 2);
    testPosition ('6k1/8/8/6p1/4Q3/8/5KRq/7N b - - 0 40', 'DSK0.queen-lost-ply3.log', 3, 2);;
    testPosition ('4k3/8/1b6/8/4p2p/7K/3P4/8 w - - 0 40', 'DSK0.ep-ply3.log', 3, 2);
//    testPosition ('1k1r4/pp1b1R2/3q2pp/4p3/2B5/4Q3/PPP2B2/2K5 b - - 0 40', 'DSK0.Kopec1.log', 5, 3);

    disableAlphaBetaPruning := true;
    testPosition ('4k3/p1p3p1/8/1P5P/1p1p4/8/P1P1P3/4K3 w - - 0 10', 'DSK0.ep-test.log', 3, 0);
    disableAlphaBetaPruning := false;
    
    testPosition ('r3k2r/1pp2ppp/p2bbn2/4N3/4P3/2N1B3/PPP1B1PP/R1K4R b kq - 0 12', 'DSK0.ticket.log', 4, 7);

    testPosition ('rn1qkb1r/ppp1pppp/4b3/4P3/2pP2n1/N4N2/PP3PPP/R1BQKB1R b KQkq - 2 6', 'DSK0.ticket.log', 4, 7);

    writeln;
    writeln ('** DONE **');
{$ifdef ti99}    
    waitKey
{$endif}
end.
