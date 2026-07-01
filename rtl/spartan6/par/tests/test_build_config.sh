#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_file_contains() {
    local path="$1"
    local pattern="$2"
    local label="$3"

    if ! grep -Eq "$pattern" "$path"; then
        fail "$label: '$path' does not contain pattern '$pattern'"
    fi
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

"$PAR_DIR/write_build_config.sh" 8bit-mono "$tmpdir/8bit-mono.vh"
assert_file_contains "$tmpdir/8bit-mono.vh" '`define CASTER_COLORMODE "MONO"' "8bit mono color mode"
assert_file_contains "$tmpdir/8bit-mono.vh" '`define CASTER_OUTPUT_WIDTH 8' "8bit mono width"

"$PAR_DIR/write_build_config.sh" 8bit-k3 "$tmpdir/8bit-k3.vh"
assert_file_contains "$tmpdir/8bit-k3.vh" '`define CASTER_COLORMODE "K3"' "8bit K3 color mode"
assert_file_contains "$tmpdir/8bit-k3.vh" '`define CASTER_OUTPUT_WIDTH 8' "8bit K3 width"

"$PAR_DIR/write_build_config.sh" 16bit-mono "$tmpdir/16bit-mono.vh"
assert_file_contains "$tmpdir/16bit-mono.vh" '`define CASTER_COLORMODE "MONO"' "16bit mono color mode"
assert_file_contains "$tmpdir/16bit-mono.vh" '`define CASTER_OUTPUT_WIDTH 16' "16bit mono width"

"$PAR_DIR/write_build_config.sh" 16bit-k3 "$tmpdir/16bit-k3.vh"
assert_file_contains "$tmpdir/16bit-k3.vh" '`define CASTER_COLORMODE "K3"' "16bit K3 color mode"
assert_file_contains "$tmpdir/16bit-k3.vh" '`define CASTER_OUTPUT_WIDTH 16' "16bit K3 width"

if "$PAR_DIR/write_build_config.sh" 8bit-color "$tmpdir/invalid.vh" 2>"$tmpdir/invalid.err"; then
    fail "invalid color variant unexpectedly succeeded"
fi
assert_file_contains "$tmpdir/invalid.err" "unknown Caster build variant" "invalid variant error"

echo "PASS: Caster build config variants"
