#!/bin/bash

# set path to compiler and assembler

SP=../statpascal/obj/sp
XAS99=../xdt99/xas99.py

rm -f out.a99
$SP sp/phoenix.pas
rm -f phoenix_b*.bin phoenix.bin
$XAS99 -R -b -q -L out.lst out.a99 -o phoenix.bin

# combine 8K banks to cartridge

cat phoenix_b*.bin >phoenix.bin

# pad to 512 KB

while [ $(du -k phoenix.bin | cut -f 1) -lt 512 ]
do
    cat phoenix_b00.bin >> phoenix.bin
done
