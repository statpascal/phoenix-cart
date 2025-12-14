#!/bin/bash

# set path to compiler and assembler

SP=~/src/statpascal/obj/sp
XAS99=~/ti99/xdt99/xas99.py
EMUL99=~/ti99/emul99/bin/emul99 

rm -f out.a99
$SP sp/testphoenix.pas
rm -f testphoenix_b*.bin testphoenix.bin
$XAS99 -R -b -q -L out.lst out.a99 -o testphoenix.bin

# combine 8K banks to cartridge

cat testphoenix_b*.bin >testphoenix.bin

$EMUL99 phoenix-cart.cfg cart_rom=testphoenix.bin &
sleep 2
echo -n 2 >keyin_fifo
sleep 1
echo -n 2 >keyin_fifo
