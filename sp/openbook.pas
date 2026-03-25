unit openbook;

interface

uses board, globals;
    
function searchMove (hash: uint64): TBookMoves;
    
    
implementation

{$ifdef ti99}
uses cartbook;

function searchMove (hash: uint64): TBookMoves;
    var
        hi, lo, mid: integer;
        bookEntry: TBookEntry;
        i: integer;
    begin
        fillChar (result, sizeof (TBookMoves), 0);
        lo := 0;
        hi := pred (OpeningPositions);
        repeat
            mid := (hi + lo) shr 1;
            bookEntry := getMove (mid);
            case compareWord (hash, bookEntry.hash, sizeof (uint64) div 2) of
                1:
                    lo := mid + 1;
                -1:
                    hi := mid - 1;
                0:
                    begin
                        result := bookEntry.bookMoves;
                        exit
                    end
            end
        until lo > hi
    end;
{$endif}

{$ifdef fpc}
uses readbook;

function searchMove (hash: uint64): TBookMoves;
    var
        i, diff, hi, lo, mid: integer;
        move: TMoveRecord;
    begin
        fillChar (result, sizeof (TBookMoves), 0);
        if posCount > 0 then 
            begin
                lo := 1;
                hi := posCount;
                repeat
                    mid := (hi + lo) shr 1;
                    if hash > openings [mid].hash then
                        lo := mid + 1
                    else if hash < openings [mid].hash then
                        hi := mid - 1
                    else                            
                        begin
                            for i := 0 to pred (openings [mid].count) do
                                begin
                                    move := openings [mid].nextMoves [succ (i)];
                                    result [i] := move.startSq shl 6 or move.endSq
                                end;
                            exit
                        end
                until lo > hi
            end
    end;
{$endif}
    
end.
    