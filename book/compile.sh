#!/bin/bash
#
# Usage: ./compile openbook.txt

fpc -Mdelphi -O3 -Fu../sp makeopenbook.pas
./makeopenbook $1
mv cartbook.pas ../sp
