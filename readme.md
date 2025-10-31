# Phoenix-Cart

Native code version of Walid Maalouli's UCSD-Pascal chess engine for the
TI99/4A.

The repository contains a port of the UCSD sources to StatPascal, enabling
native 9900 code running in a bank switched cartridge. 

The original sources are stored in the UCSD directory, the port is contained
in the sp directory. They are kept as close as possible - the major changes
are a split of some procedures that exceeded the code size limit of 8 KB
(the size of a single bank in cartridge address space) and different calling
conventions for assembly modules.

A build script and the resulting cartridge (phoenix.bin) are stored in the root directory.

To execute the cartridge, SAMS support is required.
