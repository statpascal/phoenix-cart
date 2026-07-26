unit readbook;

(* Free Pascal code only *)

interface

uses board;

const
    maxMoves = 20;
    maxPositions = 20000;
    
type
    THashedPosition = record
        hash: uint64;
        count: integer;
        nextMoves: array [1..maxMoves] of TMoveRecord;
        moveWeights: array [1..maxMoves] of integer;
    end;

var
    openings: array [1..maxPositions] of THashedPosition;
    posCount: integer;
    maxPosMoves: integer;

procedure loadOpeningBook (fn: string);


implementation

procedure registerMove (var board: TBoardRecord; turn: integer; var move: TMoveRecord);
    var
        index, moveIndex: integer;
    begin
        index := 1;
        while (index <= posCount) and (openings [index].hash <> board.hash) do
            inc (index);
        if (index = succ (posCount)) and (posCount < maxPositions) then
            begin
                inc (posCount);
                openings [index].hash := board.hash;
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
        moveSeq: array [1..maxLength] of TMoveRecord;
    begin
        index := 1;
        count := 1;
        while (count <= maxLength) and (index + 3 <= length (line)) and (line [index] in ['a'..'h']) do
            begin
                moveSeq [count].startSq := ord (line [index]) - ord ('a') + 8 * (ord (line [index + 1]) - ord ('1'));
                moveSeq [count].endSq := ord (line [index + 2]) - ord ('a') + 8 * (ord (line [index + 3]) - ord ('1'));
                moveSeq [count].flags := 0;
                if not (moveSeq [count].startSq in [0..63]) or not (moveSeq [count].endSq in [0..63]) then 
                    begin
                        writeln ('Error: invalid square -ignoring sequence in ', line);
                        exit
                    end;
                inc (count);
                inc (index, 5)
            end;
        turn := 0;
        for i := 1 to pred (count) do
            begin
                moveSeq [i].pieceType := findPieceType (mainBoard, turn, moveSeq [i].startSq);
                registerMove (mainBoard, turn, moveSeq [i]);
                enterMoveSimple (mainBoard, moveSeq [i]);
                turn := 1 - turn
            end
    end;
    
procedure sortOpenings;

    procedure swap (i, j: integer);
        var
            h: THashedPosition;
        begin
            h := openings [i];
            openings [i] := openings [j];
            openings [j] := h
        end;

    procedure qsort (left, right: integer);
        var
            i, j: integer;
            m: uint64;
        begin
            m := openings [(left + right) div 2].hash;
            i := Left; 
            j := right;
            repeat
                while openings [i].hash < m do
                    inc (i);
                while openings [j].hash > m do
                    dec (j);
                if i <= j then
                    begin
                        swap (i, j);
                        inc (i);
                        dec (j)
                    end
            until i > j;
            if i < right then 
                qsort (i, right);
            if left < j then
                qsort (left, j)
        end;

    begin
        qsort (1, posCount)
    end;                    
    
procedure loadOpeningBook (fn: string);
    var
        mainBoard: TBoardRecord;
        f: text;
        desc, line: string;
    begin
        assign (f, fn);
        {$i-}
        reset (f);
        if IOResult <> 0 then
            exit;
        posCount := 0;
        maxPosMoves := 0;
        while not eof (f) do
            begin
                readln (f, line);
                if (length (line) <> 0) and (line [1] <> '#') then 
                    begin
                        setInitPosition (mainBoard);
                        handlePositions (mainBoard, line)
                    end
            end;
        close (f);
        sortOpenings
    end;

begin
    posCount := 0;
    maxPosMoves := 0
end.
    
