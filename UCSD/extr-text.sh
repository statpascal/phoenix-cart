#!/bin/bash

if [ "$1" == "" ]; then
    echo "Extract text files from UCSD disk image given as argument"
    exit 1
fi

for a in $(~/ti99/emul99/bin/ucsddskman $1 list | grep "TEXT" | awk '{print $7}'); do
    echo "Extracting " $a
    ~/ti99/emul99/bin/ucsddskman $1 extract $a $a
done
