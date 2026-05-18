program makemag;

function hexstr (s: string): uint8;
    begin
        if s [1] > '9' then 
            result := 10 + (ord (s [1]) - ord ('a'))
        else
            result := ord (s [1]) - ord ('0');
        result := result * 16;
        if s [2] > '9' then 
            inc (result, 10 + (ord (s [2]) - ord ('a')))
        else
            inc (result, ord (s [2])  - ord ('0'))
    end;
        
var
    pattern: array [0..3, 0..5, 0..31] of uint8;
    
var 
    f: text;
    g: file;
    s: string;    
    i, j, k, l, offset: integer;
    
    
begin
    assign (f, '/tmp/test.dat');
    reset (f);
    for i := 0 to 3 do
         for j := 0 to 5 do
             begin
                 offset := 0;
                 for k := 0 to 3 do
                     begin
                         readln (f, s);
                         writeln (s);
                         for l := 0 to 7 do
                             begin
                                 writeln (i, ' ', offset);
                                 pattern [i, j, offset] := hexstr (copy (s, 2 * l +4 , 2));
                                 inc (offset)
                             end
                    end
            end;
    close (f);
            
    assign (g, '/home/goose/src/phoenix/resources/pattern.dat');
    rewrite (g, sizeof (pattern));
    blockwrite (g, pattern, 1);
    close (g);
end.

         
    
    
