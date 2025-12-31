program openbook;

uses board, logger;

const
    maxMoves = 200;
    maxPositions = 20000;

type
    THashedPosition = record
        compressed: TCompressedBoard;
        count: integer;
        nextMoves: array [1..maxMoves] of moverec;
        moveWeights: array [1..maxMoves] of integer;
    end;
        
var
    openings: array [1..maxPositions] of THashedPosition;
    posCount: integer;
    maxPosMoves: integer;
    
    
procedure registerMove (var board: TBoardRecord; turn: integer; var move: moverec);
    var
        compressed: TCompressedBoard;
        index, moveIndex: integer;
    begin
        compressBoard (board, compressed);
        index := 1;
        if turn = 1 then
            compressed.flags := compressed.flags or moveBlackFlag;
        while (index <= posCount) and (compareByte (compressed, openings [index].compressed, sizeof (compressed)) <> 0) do
            inc (index);
        if (index = succ (posCount)) and (posCount < maxPositions) then
            begin
                inc (posCount);
                openings [index].compressed := compressed;
                openings [index].count := 0
            end;
        if posCount <> maxPositions then
            begin
                if openings [index].count < maxMoves then
                    begin
                        for moveIndex := 1 to openings [index].count do
                            if compareByte (move, openings [index].nextMoves [moveIndex], sizeof (move)) = 0 then
                                begin
                                    inc (openings [index].moveWeights [moveIndex]);
                                    exit
                                end;
                        inc (openings [index].count);
                        if openings [index].count > maxPosMoves then
//                            if index <> 1 then
                            maxPosMoves := openings [index].count;
                        openings [index].nextMoves [openings [index].count] := move;
                        openings [index].moveWeights [openings [index].count] := 1
                    end
            end
    end;
    
procedure handlePositions (var mainBoard: TBoardRecord; line: string);
    const
        maxLength = 40;
    var
        count, index, turn, i: integer;
        moveSeq: array [1..maxLength] of moverec;
    begin
        writeln ('Analyzing: ', line);
        index := 1;
        count := 1;
        while (count <= maxLength) and (index + 3 <= length (line)) and (line [index] in ['a'..'h']) do
            begin
                moveSeq [count].startSq := ord (line [index]) - ord ('a') + 8 * (ord (line [index + 1]) - ord ('1'));
                moveSeq [count].endSq := ord (line [index + 2]) - ord ('a') + 8 * (ord (line [index + 3]) - ord ('1'));
                if not (moveSeq [count].startSq in [0..63]) or not (moveSeq [count].endSq in [0..63]) then 
                    begin
                        writeln ('Error: invalid square -ignoring sequence');
                        exit
                    end;
                inc (count);
                inc (index, 5)
            end;
        turn := 0;
        for i := 1 to pred (count) do
            begin
                moveSeq [i].id := findPieceType (mainBoard, turn, moveSeq [i].startSq);
                registerMove (mainBoard, turn, moveSeq [i]);
                enterMoveSimple (turn, mainBoard, moveSeq [i]);
                turn := 1 - turn
            end
    end;
    
function makehexstr (var s: TCompressedBoard): string;
    type
        bytearr = array [0..100] of uint8;
    var 
        i: integer;
        b: bytearr;
    begin
        move (s, b, sizeof (s));
        result := '';
        for i := 0 to pred (sizeof (s)) do
            result := result + hexstr (b [i], 2)
    end; 
    
procedure printOpenings;
    var
        mainboard: TBoardRecord;
        i, j: integer;
    begin
        writeln ('Size of board is ', sizeof (TCompressedBoard));
        writeln ('Opening moves: ', posCount, ' positions, max moves is ', maxPosMoves);
        for i := 1 to posCount do
            begin
                inflateBoard (openings [i].compressed, mainboard);
                writeln ('Position: ', i);
                writeln ('Hex: ', makehexstr (openings [i].compressed));
                printBoard (output, mainBoard);
                write ('Moves: ', openings [i].count, ' ');
                for j := 1 to openings [i].count do
                    begin
                        printMove (output, openings [i].nextMoves [j]);
                        write ('(', openings [i].moveWeights [j], ') ')
                    end;
                writeln
            end
    end;

var
    mainBoard: TBoardRecord;
    f: text;
    desc, line: string;
    side, move: integer;
    
begin
    writeln ('Analyzing ', ParamStr (1));
    assign (f, ParamStr (1));
    reset (f);
    posCount := 0;
    maxPosMoves := 0;
    while not eof (f) do
        begin
            readln (f, desc);
            readln (f, line);
            setInitPosition (mainBoard, side, move);
            handlePositions (mainBoard, line)
        end;
    close (f);
    printOpenings
end.
    
