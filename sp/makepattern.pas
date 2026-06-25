program makepattern;

// combines the piece bitmap image data from PBM files to a resource file

uses
    board, sysutils;

const
    basePath = 'resources/pieces/';

var
    pattern: array [0..5, 0..31] of uint8;
    
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
            for i := 0 to 31 do
                begin
                    read (f, val);
                    pattern [pieceType, i] := val
                end;
        close (f);
        writeln ('Added ', fn)
    end;
    
var
    i, j, k: integer;
    
procedure dumpHex (piece, offset: integer);
    var
        i: integer;
    begin
        write ('CH:');
        for i := 0 to 7 do
            write (IntToHex (pattern [piece, offset + 2 * i], 2));
        writeln
    end;
    
begin
    addPattern (Pawn, 'pawn.pbm');
    addPattern (Rook, 'rook.pbm');
    addPattern (Knight, 'knight.pbm');
    addPattern (Bishop, 'bishop.pbm');
    addPattern (Queen, 'queen.pbm');
    addPattern (King, 'king.pbm');
    
    // write 32 character defintions suited for Magellan
    
    for i := 0 to 1 do
        begin
            for j := Pawn to King do
                for k := 0 to 1 do
                    dumpHex (j, 16 * i + k);
            for j := 0 to 3 do
                writeln ('CH:0000000000000000')
        end
end.
        