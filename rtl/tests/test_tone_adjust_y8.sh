#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RTL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${TMPDIR:-/tmp}/caster_tone_adjust_y8_tb"

mkdir -p "${BUILD_DIR}"
iverilog -g2012 -I "${RTL_DIR}" \
    -o "${BUILD_DIR}/tone_adjust_y8_tb" \
    "${RTL_DIR}/mulib/rtl/baseip/mu_ram_2rw.v" \
    "${RTL_DIR}/tone_adjust_y8.v" \
    "${SCRIPT_DIR}/tone_adjust_y8_tb.v"
(cd "${BUILD_DIR}" && vvp ./tone_adjust_y8_tb)
