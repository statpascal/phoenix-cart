# Phoenix-Cart

Native code version of Walid Maalouli's UCSD-Pascal chess engine for the
TI99/4A (https://github.com/wmaalouli/Phoenix-Chess).

The repository contains a port of the UCSD sources to StatPascal, enabling
native 9900 code running in a bank switched cart. To build the
cart under Linux, one needs to install StatPascal as a 9900 cross
compiler.
(https://www.github.com/statpascal/spc). Moreover, the Free Pascal Compiler
for Linux is required to generate a binary representation of the the opening book
that is linked into the cart.

The original sources are stored in the UCSD directory, the port is contained
in the sp directory. The main branch is kept as close as possible to the
original UCSD sources and requires SAMS memory. The major changes are
a split of some procedures that exceeded the code size limit of 8 KB
(the size of a single bank in cartridge address space) and different calling
conventions for assembly modules.

Current development is done on the development branch, which only requires a
32K memory extension. Dropping the rather time-consuming SAMS memory management
required to interoperate with TI's UCSD system and using native 9900 code it is about 50 times 
faster than the original UCSD version.

## Building the cart

Install the SP compiler and build it as cross compiler for the TI99:

    git clone https://github.com/statpascal/spc statpascal
    cd statpascal
    make ti99=1

The cart uses an opening book that may contain up to 20000 positions, with
up to 20 moves for each position (the actual move is picked randomly).  A
simple example (that one may to replace) is stored in the file
book/opening.txt: the file consists of lines with moves in coordinate
notation and optional comment lines starting with #:

    # Four knights
    e2e4 e7e5 g1f3 b8c6 b1c3 g8f6 f1b5 f8b4 e1g1 e8g8 d2d3 d7d6
    e2e4 e7e5 g1f3 b8c6 b1c3 g8f6 f1b5 f8c5 d2d3 d7d6

For inclusion into the cart, it must be converted to an internal hash format by
changing to the book directory and executing the script compile.sh:

    cd book
    bash compile.sh opening.txt

This generates the source file sp/cartbook.pas and one or more binary files
book0.dat, book1.dat, ... in the book directory.

After that, return to the previous directory and build the cart with

    cd ..
    bash build.sh

The last step produces a bank switched cart (phoenix.bin) that can
be loaded in an emulator or executed on the real hardware with an FG99.
