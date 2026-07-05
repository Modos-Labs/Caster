#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RTL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${TMPDIR:-/tmp}/caster_memif_tb"

mkdir -p "${BUILD_DIR}"
iverilog -g2012 -I "${RTL_DIR}" \
    -o "${BUILD_DIR}/memif_tb" \
    "${RTL_DIR}/spartan6/memif.v" \
    "${SCRIPT_DIR}/memif_tb.v"
(cd "${BUILD_DIR}" && vvp ./memif_tb)
