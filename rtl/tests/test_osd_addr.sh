#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RTL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${TMPDIR:-/tmp}/caster_osd_addr_tb"

mkdir -p "${BUILD_DIR}"
iverilog -g2012 -I "${RTL_DIR}" \
    -o "${BUILD_DIR}/osd_addr_tb" \
    "${RTL_DIR}/osd_addr.v" \
    "${SCRIPT_DIR}/osd_addr_tb.v"
(cd "${BUILD_DIR}" && vvp ./osd_addr_tb)
