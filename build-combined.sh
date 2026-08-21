#!/bin/bash

# set path to compiler and assembler

SP=../statpascal/obj/sp
XAS99=../xdt99/xas99.py
XGA99=../xdt99/xga99.py
EMUL99=../emul99/bin/emul99

rm -f out.a99
$SP --no-header --bank 8 sp/phoenix.pas
rm -f phoenix_b*.bin phoenix.bin
$XAS99 -R -b -q -L out.lst out.a99 -o phoenix.bin
rm -f phoenix_b0[0-7].bin

# combine 8K banks to cartridge

echo -n 0 >chessc.bin
dd if=TACTICON-v20_2.bin bs=1 skip=1 >>chessc.bin
cat phoenix_b*.bin >>chessc.bin

# compile GPL header

$XGA99 chess.gpl -o chessg.bin
dd if=/dev/zero bs=1 seek=6144 count=0 of=chessg.bin

# start emulator

$EMUL99 phoenix-cart.cfg cart_rom=chessc.bin cart_groms=chessg.bin