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
    pattern: array [0..255, 0..7] of uint8;
    colorTable: array [0..31] of uint8;
    backColor: uint8;
    
var 
    f: text;
    g: file;
    s: string;    
    j, countChar, countColor, countBackground: integer;
    val1, val2: uint8;
    

procedure readInt (var s: string; var index: integer; var val: uint8);
    begin
        val := 0;
        while s [index] in ['0'..'9'] do
            begin
                val := 10 * val + ord (s [index]) - ord ('0');
                inc (index)
            end
    end;
    
begin
    assign (f, ParamStr (1));
    reset (f);
    countChar := 0;
    countColor := 0;
    countBackground := 0;
    while not eof (f) do
        begin
            readln (f, s);
            if (copy (s, 1, 3) = 'CH:') and (countChar < 256) then
                begin
                    for j := 0 to 7 do
                        pattern [countChar, j] := hexstr (copy (s, 2 * j + 4 , 2));
                    inc (countChar)
                end
            else if (copy (s, 1, 3) = 'CC:') and (countColor < 32) then
                begin
                    j := 4;
                    readInt (s, j, val1);
                    inc (j);
                    readInt (s, j, val2);
                    colorTable [countColor] := 16 * val1 + val2;
                    inc (countColor)
                end
            else if (copy (s, 1, 3) = 'MB:') and (countBackground < 1) then
                begin
                    j := 4;
                    readInt (s, j, backColor);
                    inc (countBackground)
                end
        end;
    close (f);
            
    assign (g, ParamStr (2));
    rewrite (g, 1);
    blockwrite (g, pattern, sizeof (pattern));
    blockwrite (g, colorTable, sizeof (colorTable));
    blockwrite (g, backColor, 1);
    close (g);
end.
