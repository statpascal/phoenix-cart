program openbook;

uses readbook, board, logger, math;

const
    BankSize = 100;

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
//                writeln ('Position: ', i);
                write (i:4, ' ', makehexstr (openings [i].compressed));
//                printBoard (output, mainBoard);
                write ('Moves: ', openings [i].count, ' ');
                for j := 1 to openings [i].count do
                    begin
                        printMove (output, openings [i].nextMoves [j]);
                        write ('(', openings [i].moveWeights [j], ') ')
                    end;
                writeln
            end
    end;
    
procedure saveOpenings;
    var 
        count, i, j: integer;
        s: string;
        f: file;
        g, h: text;
        m: uint16;
    begin
        count := 0;
        assign (g, 'open-inc.pas');
        assign (h, 'open-case.pas');
        rewrite (g);
        rewrite (h);
        while count * bankSize < posCount do
            begin
                str (count, s);
                assign (f, 'book' + s + '.dat');
                rewrite (f, 1);
                for i := succ (bankSize * count) to min (posCount, bankSize * succ (count)) do
                    begin
                        blockwrite (f, openings [i].compressed, sizeof (TCompressedBoard));
                        for j := 1 to maxMoves do
                            begin
                                if j <= openings [i].count then
                                    m := (openings [i].nextMoves [j].startSq shl 6) or openings [i].nextMoves [j].endSq
                                else
                                    m := 0;
                                m := swapEndian (m);
                                blockwrite (f, m, sizeof (m))
                            end
                    end;
                writeln (g, 'function getMove' + s + ' (n: integer): TBookEntry;');
                writeln (g, '    procedure book_' + s + '; external ''book' + s + '.dat'';');
                writeln (g, '    begin');
                writeln (g, '        result := TOpeningBook (addr(book_' + s + ')) [n]');
                writeln (g, '    end;');
                writeln (g);
                writeln (h, '               ' + s + ': result := getMove' + s + '  (n mod BookSize);');
                close (f);
                inc (count)
            end;
        close (g);
        close (h)
    end;

    
begin
    writeln ('Analyzing ', ParamStr (1));
    loadOpeningBook (ParamStr (1));
    printOpenings;
    saveOpenings
end.
    
