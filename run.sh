#!/bin/bash
~/ti99/emul99/bin/emul99 ~/ti99/emul99/bin/common.cfg mem_ext=1 disksim_dsr=~/ti99/emul99/roms/disksim.bin disksim_dir=~/src/phoenix cart_rom=phoenix.bin disksim_text=1 rs232_dsr=~/ti99/emul99/roms/RS232.Bin PIO/1_out=pio,nozero,append $1
