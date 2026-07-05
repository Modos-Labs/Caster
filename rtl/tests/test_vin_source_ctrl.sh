#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RTL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${TMPDIR:-/tmp}/caster_vin_source_ctrl_tb"

mkdir -p "${BUILD_DIR}"
iverilog -g2012 -I "${RTL_DIR}" \
    -o "${BUILD_DIR}/vin_source_ctrl_tb" \
    "${RTL_DIR}/spartan6/vin_source_ctrl.v" \
    "${SCRIPT_DIR}/vin_source_ctrl_tb.v"
(cd "${BUILD_DIR}" && vvp ./vin_source_ctrl_tb)
