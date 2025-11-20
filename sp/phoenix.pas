program phoenix;

uses globals, main, vdp;

var 
    n: integer;

type 
    TBoardDataPage =   array [0..4095] of byte;

function boarddat1: TBoardDataPage;
    procedure data1;
    external 'boarddat.00';
    begin
        boarddat1 := TBoardDataPage (addr (data1))
    end;

function boarddat2: TBoardDataPage;
    procedure data2;
    external 'boarddat.01';
    begin
        boarddat2 := TBoardDataPage (addr (data2))
    end;

function boarddat3: TBoardDataPage;
    procedure data3;
    external 'boarddat.02';
    begin
        boarddat3 := TBoardDataPage (addr (data3))
    end;

procedure loadBoardData;
    var 
        buf: TBoardDataPage;
    begin
        buf := boardDat1;
        DataOps (1, BASE,  4096, 0, buf);
        buf := boarddat2;
        DataOps (1, BASE1, 4096, 0, buf);
        buf := boarddat3;
        DataOps (1, BASE2, 4096, 0, buf)
    end;

begin
    initHeap ($a000, 16384);
    clrscr;
//    setTextColor (lightyellow);
    setBackColor (white);
    writeln('Phoenix Chess 2.1');
    n := SamsInit;
    if n = 0 then
         writeln('no SAMS card found! Exiting...')
    else
        begin
            SamsSize(n, dataSize);
            writeln('SAMS card detected: ',dataSize,' pages');

            writeln('loading data...');
            loadBoardData;
            writeln('starting Phoenix Chess...');

            chainMain
        end;
    waitkey
end.
