unit openbook;

interface

uses board, logger;

const
    MaxMoves = 20;
    BookSize = 100;
    OpeningPositions = 2855;

type
    TBookMoves = array [0..MaxMoves - 1] of integer;
    TBookEntry = record
        compressedBoard: TCompressedBoard;
        bookMoves: TBookMoves
    end;
    
function searchMove (var compressed: TCompressedBoard): TBookMoves;
    
    
implementation

type 
    TOpeningBook = array [0..BookSize] of TBookEntry;
    
function getMove0 (n: integer): TBookEntry;
    procedure book_0; external 'book0.dat';
    begin
        result := TOpeningBook (addr(book_0)) [n]
    end;

function getMove1 (n: integer): TBookEntry;
    procedure book_1; external 'book1.dat';
    begin
        result := TOpeningBook (addr(book_1)) [n]
    end;

function getMove2 (n: integer): TBookEntry;
    procedure book_2; external 'book2.dat';
    begin
        result := TOpeningBook (addr(book_2)) [n]
    end;

function getMove3 (n: integer): TBookEntry;
    procedure book_3; external 'book3.dat';
    begin
        result := TOpeningBook (addr(book_3)) [n]
    end;

function getMove4 (n: integer): TBookEntry;
    procedure book_4; external 'book4.dat';
    begin
        result := TOpeningBook (addr(book_4)) [n]
    end;

function getMove5 (n: integer): TBookEntry;
    procedure book_5; external 'book5.dat';
    begin
        result := TOpeningBook (addr(book_5)) [n]
    end;

function getMove6 (n: integer): TBookEntry;
    procedure book_6; external 'book6.dat';
    begin
        result := TOpeningBook (addr(book_6)) [n]
    end;

function getMove7 (n: integer): TBookEntry;
    procedure book_7; external 'book7.dat';
    begin
        result := TOpeningBook (addr(book_7)) [n]
    end;

function getMove8 (n: integer): TBookEntry;
    procedure book_8; external 'book8.dat';
    begin
        result := TOpeningBook (addr(book_8)) [n]
    end;

function getMove9 (n: integer): TBookEntry;
    procedure book_9; external 'book9.dat';
    begin
        result := TOpeningBook (addr(book_9)) [n]
    end;

function getMove10 (n: integer): TBookEntry;
    procedure book_10; external 'book10.dat';
    begin
        result := TOpeningBook (addr(book_10)) [n]
    end;

function getMove11 (n: integer): TBookEntry;
    procedure book_11; external 'book11.dat';
    begin
        result := TOpeningBook (addr(book_11)) [n]
    end;

function getMove12 (n: integer): TBookEntry;
    procedure book_12; external 'book12.dat';
    begin
        result := TOpeningBook (addr(book_12)) [n]
    end;

function getMove13 (n: integer): TBookEntry;
    procedure book_13; external 'book13.dat';
    begin
        result := TOpeningBook (addr(book_13)) [n]
    end;

function getMove14 (n: integer): TBookEntry;
    procedure book_14; external 'book14.dat';
    begin
        result := TOpeningBook (addr(book_14)) [n]
    end;

function getMove15 (n: integer): TBookEntry;
    procedure book_15; external 'book15.dat';
    begin
        result := TOpeningBook (addr(book_15)) [n]
    end;

function getMove16 (n: integer): TBookEntry;
    procedure book_16; external 'book16.dat';
    begin
        result := TOpeningBook (addr(book_16)) [n]
    end;

function getMove17 (n: integer): TBookEntry;
    procedure book_17; external 'book17.dat';
    begin
        result := TOpeningBook (addr(book_17)) [n]
    end;

function getMove18 (n: integer): TBookEntry;
    procedure book_18; external 'book18.dat';
    begin
        result := TOpeningBook (addr(book_18)) [n]
    end;

function getMove19 (n: integer): TBookEntry;
    procedure book_19; external 'book19.dat';
    begin
        result := TOpeningBook (addr(book_19)) [n]
    end;

function getMove20 (n: integer): TBookEntry;
    procedure book_20; external 'book20.dat';
    begin
        result := TOpeningBook (addr(book_20)) [n]
    end;

function getMove21 (n: integer): TBookEntry;
    procedure book_21; external 'book21.dat';
    begin
        result := TOpeningBook (addr(book_21)) [n]
    end;

function getMove22 (n: integer): TBookEntry;
    procedure book_22; external 'book22.dat';
    begin
        result := TOpeningBook (addr(book_22)) [n]
    end;

function getMove23 (n: integer): TBookEntry;
    procedure book_23; external 'book23.dat';
    begin
        result := TOpeningBook (addr(book_23)) [n]
    end;

function getMove24 (n: integer): TBookEntry;
    procedure book_24; external 'book24.dat';
    begin
        result := TOpeningBook (addr(book_24)) [n]
    end;

function getMove25 (n: integer): TBookEntry;
    procedure book_25; external 'book25.dat';
    begin
        result := TOpeningBook (addr(book_25)) [n]
    end;

function getMove26 (n: integer): TBookEntry;
    procedure book_26; external 'book26.dat';
    begin
        result := TOpeningBook (addr(book_26)) [n]
    end;

function getMove27 (n: integer): TBookEntry;
    procedure book_27; external 'book27.dat';
    begin
        result := TOpeningBook (addr(book_27)) [n]
    end;

function getMove28 (n: integer): TBookEntry;
    procedure book_28; external 'book28.dat';
    begin
        result := TOpeningBook (addr(book_28)) [n]
    end;


function searchMove (var compressed: TCompressedBoard): TBookMoves;

    function getMove (n: integer): TBookEntry;
        begin
            case n div BookSize of
               0: result := getMove0  (n mod BookSize);
               1: result := getMove1  (n mod BookSize);
               2: result := getMove2  (n mod BookSize);
               3: result := getMove3  (n mod BookSize);
               4: result := getMove4  (n mod BookSize);
               5: result := getMove5  (n mod BookSize);
               6: result := getMove6  (n mod BookSize);
               7: result := getMove7  (n mod BookSize);
               8: result := getMove8  (n mod BookSize);
               9: result := getMove9  (n mod BookSize);
               10: result := getMove10  (n mod BookSize);
               11: result := getMove11  (n mod BookSize);
               12: result := getMove12  (n mod BookSize);
               13: result := getMove13  (n mod BookSize);
               14: result := getMove14  (n mod BookSize);
               15: result := getMove15  (n mod BookSize);
               16: result := getMove16  (n mod BookSize);
               17: result := getMove17  (n mod BookSize);
               18: result := getMove18  (n mod BookSize);
               19: result := getMove19  (n mod BookSize);
               20: result := getMove20  (n mod BookSize);
               21: result := getMove21  (n mod BookSize);
               22: result := getMove22  (n mod BookSize);
               23: result := getMove23  (n mod BookSize);
               24: result := getMove24  (n mod BookSize);
               25: result := getMove25  (n mod BookSize);
               26: result := getMove26  (n mod BookSize);
               27: result := getMove27  (n mod BookSize);
               28: result := getMove28  (n mod BookSize);
            end;
        end;

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
            writeln (logfile, lo:5, mid:5, hi:5);
            for i := 0 to 25 do
                write (logfile, hexstr2 (bytearray (bookEntry.compressedBoard) [i]));
            writeln (logfile);
            for i := 0 to 25 do
                write (logfile, hexstr2 (bytearray (compressed) [i]));
            writeln (logfile);
            case compareWord (compressed, bookEntry.compressedBoard, sizeof (TCompressedBoard) div 2) of
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
    
end.
    