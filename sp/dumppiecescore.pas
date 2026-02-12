program dumppiecescore;

// FPC only
// writes the TPieceScoreData array in resvals to file piecescore.dat in big 16 bit big endian format
// to be linked with the cart.

uses resvals;

var 
    i, j: integer;
    f: file of uint16;
    g: file;
    
begin
    assign (f, 'piecescore.dat');
    rewrite (f);
    for i := 0 to 4 do
        for j := 0 to 63 do
            write (f, swapEndian (data_score [i, j]));
    close (f);
    
    assign (g, 'whitepawncapture.dat');
    rewrite (g, 1);
    blockwrite (g, whitePawnCapture, sizeof (whitePawnCapture));
    close (g);
    
    assign (g, 'blackpawncapture.dat');
    rewrite (g, 1);
    blockwrite (g, blackPawnCapture, sizeof (blackPawnCapture));
    close (g);
end.
