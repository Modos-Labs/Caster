#!/bin/sh

set -e

echo Building bitstream
./ise_flow.sh
cp top.bit fpga.bit
./clean.sh
