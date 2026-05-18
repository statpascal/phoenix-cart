program phoenix;

uses globals, main, resources, ui;

begin
    initVideoMode;
    writeln('Phoenix Chess ', versionString);
    chainMain;

    clrscr;
    writeln ('Phoenix Chess terminating');
    writeln ('Press any key for main title screen');
    waitKeypressed
end.
