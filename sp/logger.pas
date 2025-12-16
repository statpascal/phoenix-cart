unit logger;

interface

uses globals;

var
    doLogging: boolean;
    logFile: text;

procedure dumpBitBoard (var b: bitboard);
procedure printBoard (var board: TBoardRecord);

procedure indent (ply: integer);
procedure printMove (var f: text; var move: moverec);

procedure startLogging (fn: string);
procedure stopLogging;


implementation

procedure startLogging (fn: string);
    begin
        doLogging := true;
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
        i, j, k, val: integer;
    begin
        for i := 7 downto 0 do
            for k := 0 to 7 do
                write (logFile, ord (b.b [i] and (1 shl (7 - k)) <> 0));
            writeln (logFile);
    end;

procedure printBoard (var board: TBoardRecord);
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
            for piece := 0 to 5 do
                begin
                    if side = 0 then
                        BitPos (board.white.bitboards [piece], pos)
                    else
                        BitPos (board.black.bitboards [piece], pos);
                    for i := 1 to pos [0] do
                        s [pos [i] shr 3][succ (pos [i] and 7)] := Figure [side, piece]
                end;
                
        writeln (logFile);
        writeln (logFile, '========================================');
        writeln (logFile, 'Move: ', gameMove);
        writeln (logFile);
        for i := 7 downto 0 do
            begin
                write (logFile, '|');
                for j := 1 to 8 do
                    write (logFile, s [i][j], '|');
                writeln (logFile);
            end;
        writeln (logFile)
    end;
                    
procedure printMove (var f: text; var move: moverec);
    const
        pieceName: string = 'PRNBQK';
    
    procedure writeCoord (sq: integer);
        begin
            write (f, chr (65 + sq mod 8));
            write (f, chr (49 + sq div 8))
        end;
    
    begin
        if move.id <> InvalidPiece then
            begin
                write (f, pieceName [succ (move.id)]);
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
