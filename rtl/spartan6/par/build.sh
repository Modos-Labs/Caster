#!/bin.sh

echo Building bitstream
./ise_flow.bat
cp top.bit fpga.bit
./clean.bat
