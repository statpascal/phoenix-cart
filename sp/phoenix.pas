program phoenix;

uses globals, main, resources, vdp;

begin
    clrscr;
    setBackColor (white);
    writeln('Phoenix Chess SP - 2025-12-10-14-30');
    chainMain;

    writeln;
    writeln;    
    writeln ('Phoenix Chess terminating');
    writeln ('Press any key for main title screen');
    while keyPressed do;
    waitkey
end.
