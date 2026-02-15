program dumpresources;

// FPC only
// writes the initialized array in resources.pas to seperate files 
// to be linked with the cart.

uses resources;

var 
    i: TPieceScoreType;
    j: integer;
    f: file of uint16;
    g: file;
    
begin
    assign (f, 'resources/piecescore.dat');
    rewrite (f);
    for i := PawnScore to KingEndScore do
        for j := 0 to 63 do
            write (f, swapEndian (pieceScoreData [i, j]));
    close (f);
    
    assign (g, 'resources/pawnmove.dat');
    rewrite (g, 1);
    blockwrite (g, pawnMovementBitboards, sizeof (pawnMovementBitboards));
    close (g);
    
    assign (g, 'resources/pawncapture.dat');
    rewrite (g, 1);
    blockwrite (g, pawnCaptureBitboards, sizeof (pawnCaptureBitboards));
    close (g);
    
    assign (g, 'resources/knightmove.dat');
    rewrite (g, 1);
    blockwrite (g, knightMovementBitboards, sizeof (knightMovementBitboards));
    close (g);
    
    assign (g, 'resources/kingmove.dat');
    rewrite (g, 1);
    blockwrite (g, kingMovementBitboards, sizeof (kingMovementBitboards));
    close (g);
    
    assign (g, 'resources/epcapture.dat');
    rewrite (g, 1);
    blockwrite (g, enPassantBitboards, sizeof (enPassantBitboards));
    close (g)
end.
