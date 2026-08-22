#/bin/bash

# Convert the pattern/color descriptions in Magellan files to 
# internal data structures linked with the cart

fpc -Mdelphi convmag.pas
./convmag phoenix-light.mag pattern-light.dat
./convmag phoenix-dark.mag pattern-dark.dat
rm convmag
