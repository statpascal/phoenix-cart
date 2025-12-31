unit openbook;

interface

const
    MaxMoves = 20;
    BookSize = 128;

type
    TBookMoves: array [0..MaxMoves] of integer;
    TBookEntry = record
        compressedBoard: TCompressedBoart;
        bookMoves: TBookMoves
    end;
    
implementation

type 
    TOpeningBook = array [0..BookSize] of 
    
function getMove0 (n: integer): TBookEntry;
    procedure book_0; external 'book0.dat';
    begin
        getMove0 := TBookEntry (addr (book_0)) [n]
    end;

function getMove1 (n: integer): TBookEntry;
    procedure book_1; external 'book1.dat';
    begin
        result := TBookEntry (addr (book_1)) [n]
    end;

function getMove2 (n: integer): TBookEntry;
    procedure book_2; external 'book2.dat';
    begin
        result := TBookEntry (addr (book_2)) [n]
    end;

function searchMove (var compressed: TCompressedBoard): TBookMoves;

    function getMove (n: integer): TBookEntry;
        begin
            case n div BookSize of
                0: result := getMove0 (n mod BookSize);
                1: result := getMove1 (n mod BookSize);
                2: result := getMove2 (n mod BookSize)
            end;
        end;

    var
        hi, lo, mid: integer;
    begin
        lo := 0;
        hi := 100;
        repeat
            med := (hi + lo) shr 1;
            bookEntry = getMove (med);
            case compareWord (comopressed, bookEntry.compressBoard, sizeof (TCompressedBoard) div 2) of
                1:
                    lo := med;
                -1:
                    hi := med
                0:
                    begin
                        result := bookEntry.bookMoves
                        exit
                    end
            end
        until lo = hi;
        // indicate not found
    end;
    
end.
    