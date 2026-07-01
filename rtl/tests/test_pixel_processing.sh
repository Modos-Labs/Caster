#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RTL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${TMPDIR:-/tmp}/caster_pixel_processing_tb"

mkdir -p "${BUILD_DIR}"
iverilog -g2012 -I "${RTL_DIR}" \
    -o "${BUILD_DIR}/pixel_processing_tb" \
    "${RTL_DIR}/pixel_processing.v" \
    "${SCRIPT_DIR}/pixel_processing_tb.v"
(cd "${BUILD_DIR}" && vvp ./pixel_processing_tb)
