#!/bin/sh

set -e

variant="${1:-8bit-mono}"

echo "Building bitstream for $variant"
./ise_flow.sh "$variant"
cp top.bit fpga.bit
./clean.sh
