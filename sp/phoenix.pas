program phoenix;

uses globals, main, resources, vdp;

begin
    clrscr;
    setBackColor (white);
    writeln('Phoenix Chess ', versionString);
    chainMain;

    writeln;
    writeln;    
    writeln ('Phoenix Chess terminating');
    writeln ('Press any key for main title screen');
    while keyPressed do;
    waitkey
end.
