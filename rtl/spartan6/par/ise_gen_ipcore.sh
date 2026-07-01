#!/usr/bin/env bash

set -e

if [ -z "${XILINX:-}" ]; then
    source /opt/Xilinx/14.7/ISE_DS/settings64.sh
fi

xtclsh ise_gen_ipcore.txt
