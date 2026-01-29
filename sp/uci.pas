program uci;

uses
    globals, board, genmove, logger, readbook;

var
    board: TBoardRecord;
    side, movenr: integer;
    
procedure answerUciInit;
    begin
        writeln ('id name PHOENIX-', versionString);
//        writeln ('option name OwnBook type check default true');
        writeln ('uciok')
    end;
    
procedure calcMove (side: integer);
    var
        score: integer;
        move: TMoveRecord;
        
    procedure writeCoord (sq: integer);
        begin
            write (chr (97 + sq and 7));
            write (chr (49 + sq shr 3))
        end;
        
    begin
        generateMove (gamePly, side, board, move, score);
        write ('bestmove ');
        writeCoord (move.startSq);
        writeCoord (move.endSq);
        if move.flags and $f0 <> 0 then
            write (figure [1, move.flags shr 4]);
        writeln
    end;

procedure handlePosition (s: string);
    var
        index: integer;
        t: string;
        isMoves: boolean;
        
    function interpretMove (t: string; side: integer; var move: TMoveRecord): boolean;
        begin
            if (length (t) >= 4) and
               (t [1] in ['a'..'h']) and (t [2] in ['1'..'8']) and
               (t [3] in ['a'..'h']) and (t [4] in ['1'..'8']) then
                begin
                    move.startSq := ord (t [1]) - ord ('a') + 8 * (ord (t [2]) - ord ('1'));
                    move.endSq   := ord (t [3]) - ord ('a') + 8 * (ord (t [4]) - ord ('1'));
                    move.pieceType := findPieceType (board, side, move.startSq);
                    move.flags := 0;
                    if length (t) = 5 then
                        case t [5] of
                            'r': move.flags := Rook shl 4;
                            'b': move.flags := Bishop shl 4;
                            'n': move.flags := Knight shl 4;
                            'q': move.flags := Queen shl 4
                        end;
                    interpretMove := true
                end
            else
                interpretMove := false
        end;
        
    procedure handle (t: string);
        var
            move: TMoveRecord;
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
        f: text;
    begin
        writeln ('PHOENIX Chess');
//        assign (f, '/tmp/uci.log');
//        rewrite (f);
        repeat
            readln (s);
//            writeln (f, s);
//            flush (f);
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
    
var
    i, h: integer;
    cmd, v: string;

begin
    plyQs := -3;
    gamePly := 6;
    
    for i := 0 to pred (ParamCount div 2) do
        begin
            cmd := ParamStr (2 * i + 1);
            v := ParamStr (2 * i + 2);
            if cmd = '-ply' then
                val (v, gamePly);
            if cmd = '-qs' then
                begin
                    val (v, h);
                    plyQs := 1 - h
                end;
            if cmd = '-opening' then
                loadOpeningBook (v)
        end;
        
    commandLoop
end.
