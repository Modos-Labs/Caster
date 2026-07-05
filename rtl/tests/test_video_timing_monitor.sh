#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RTL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${TMPDIR:-/tmp}/caster_video_timing_monitor_tb"

mkdir -p "${BUILD_DIR}"
iverilog -g2012 -I "${RTL_DIR}" \
    -o "${BUILD_DIR}/video_timing_monitor_tb" \
    "${RTL_DIR}/spartan6/video_timing_monitor.v" \
    "${SCRIPT_DIR}/video_timing_monitor_tb.v"
(cd "${BUILD_DIR}" && vvp ./video_timing_monitor_tb)
