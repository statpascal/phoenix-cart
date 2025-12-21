program testphoenix;

uses
    globals, move, fen, logger;

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
        
        startLogging (logfn);
        writeln ('Analyzing: ', fenStr);
        MoveGen (mainBoard, lastMove, playMove, moveScore, alpha, beta, gamePly, gameSide);
        printMove (output, playMove);
        writeln (' ', moveScore);
        writeln;
        stopLogging
    end;
    
begin
    testPosition ('rnbqkbnr/ppp1pppp/8/3p4/4P3/3P4/PPP2PPP/RNBQKBNR b KQkq - 0 2', 'DSK0.opening-ply3.log', 3, 2);
    testPosition ('r1b4r/pp1p2pp/7k/5Q2/8/2PB4/P4PPP/2K1R2R w - - 0 40', 'DSK0.queen-h5-ply4.log', 3, 2);
    testPosition ('4k3/8/8/8/8/8/1B2P3/R3K3 b Q - 0 40', 'DSK0.castle-ply3.log', 3, 2);
    testPosition ('rnb1kb1r/ppp1pppp/4qn2/8/3P4/2N5/PPP1BPPP/R1BQK1NR w KQkq - 0 40', 'DSK0.knight-lost-ply4.log', 3, 2);
    testPosition ('6k1/8/8/6p1/4Q3/8/5KRq/7N b - - 0 40', 'DSK0.queen-lost-ply3.log', 3, 2);;
    testPosition ('4k3/8/1b6/8/4p2p/7K/3P4/8 w - - 0 40', 'DSK0.ep-ply3.log', 3, 2);
//      testPosition ('1k1r4/pp1b1R2/3q2pp/4p3/2B5/4Q3/PPP2B2/2K5 b - - 0 40', 'DSK0.Kopec1.log', 5, 3);
    
    writeln;
    writeln ('** DONE **');
    waitKey
end.
