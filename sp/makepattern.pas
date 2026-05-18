program makepattern;

// combines the piece bitmap image data from PBM files to a resource file

uses
    board;

const
    basePath = 'resources/pieces/';

var
    pattern: array [Pawn..King, 0..31] of uint8;
    
procedure addPattern (pieceType: integer; fn: string);
    var 
        f: file of uint8;
        val: uint8;
        count, block, i: integer;
    begin
        assign (f, basePath + fn);
        reset (f);
        count := 0;
        repeat
            read (f, val);
            if val = $0a then
                inc (count)
        until eof (f) or (count = 2);
        if count = 2 then 
            for block := 0 to 1 do
                for i := 0 to 15 do
                    begin
                        read (f, val);
                        pattern [pieceType, 16 * block + 8 * ord (odd (i)) + i div 2] := val
                    end;
        close (f);
        writeln ('Added ', fn)
    end;
    
var
    f: file;
    
begin
    addPattern (Pawn, 'pawn.pbm');
    addPattern (Rook, 'rook.pbm');
    addPattern (Knight, 'knight.pbm');
    addPattern (Bishop, 'bishop.pbm');
    addPattern (Queen, 'queen.pbm');
    addPattern (King, 'king.pbm');
    
    assign (f, 'resources/pattern.dat');
    rewrite (f, 1);
    blockwrite (f, pattern, sizeof (pattern));
    close (f)
end.
        