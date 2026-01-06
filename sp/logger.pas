unit logger;

interface

uses globals, bitops, board;

var
    doLogging: boolean;
    logFile: text;

procedure dumpBitBoard (var b: bitboard);
procedure printBoard (var f: text; var board: TBoardRecord);

procedure indent (ply: integer);
procedure printMove (var f: text; var move: moverec);

procedure startLogging (fn: string);
procedure stopLogging;


implementation

procedure startLogging (fn: string);
    begin
        doLogging := true;
{$ifdef fpc}
        if copy (fn, 1, 5) = 'DSK0.' then
            fn := copy (fn, 6, length (fn) - 5);
{$endif}        
        assign (logFile, fn);
        rewrite (logFile)
    end;
    
procedure stopLogging;
    begin
        if doLogging then
            begin
                doLogging := false;
                close (logFile);
                assign (logFile, '')
            end
    end;

procedure indent (ply: integer);
    begin
        write (logFile, ' ' : 4 * (gameply - ply))
    end;        

procedure dumpBitBoard (var b: bitboard);
    var
        i, k: integer;
    begin
        for i := 7 downto 0 do
            for k := 0 to 7 do
                write (logFile, ord (bytearray (b) [i] and (1 shl (7 - k)) <> 0));
            writeln (logFile);
    end;

procedure printBoard (var f: text; var board: TBoardRecord);
    var
        s: array [0..7] of string [8];
        side, piece, i, j: integer;
        pos: bitarray;
    begin
        for i := 0 to 7 do
            if odd (i) then
                s [i] := ' = = = ='
            else
                s [i] := '= = = = ';
        for side := 0 to 1 do
            for piece := Pawn to King do
                begin
                    if side = 0 then
                        BitPos (board.white.bitboards [piece], pos)
                    else
                        BitPos (board.black.bitboards [piece], pos);
                    for i := 1 to pos [0] do
                        s [pos [i] shr 3][succ (pos [i] and 7)] := Figure [side, piece]
                end;
                
        writeln (f);
        writeln (f, '========================================');
        writeln (f, 'Move: ', gameMove);
        writeln (f);
        for i := 7 downto 0 do
            begin
                write (f, '|');
                for j := 1 to 8 do
                    write (f, s [i][j], '|');
                writeln (f);
            end;
        writeln (f)
    end;
                    
procedure printMove (var f: text; var move: moverec);
    
    procedure writeCoord (sq: integer);
        begin
            write (f, chr (65 + sq mod 8));
            write (f, chr (49 + sq div 8))
        end;
    
    begin
        if move.id <> InvalidPiece then
            begin
                write (f, Figure [0, move.id]);
                writeCoord (move.startSq);
                write (f, '-');
                writecoord (move.endSq)
            end
        else
            write (f, 'None')
    end;

begin
    assign (logFile, '');
    doLogging := false
end.
