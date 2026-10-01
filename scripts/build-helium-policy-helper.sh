#!/usr/bin/env bash
# Build on the target machine; never copy an x86_64 library onto the M2.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
output=${1:-$HOME/.local/lib/libhide-chromium-policies.so}
[[ $# -le 1 ]] || { printf 'Usage: %s [OUTPUT.so]\n' "${0##*/}" >&2; exit 2; }
mkdir -p -- "$(dirname -- "$output")"
"${CC:-cc}" -shared -fPIC -O2 -o "$output" \
  "$repo/config/helium/.local/src/hide-chromium-policies.c" -ldl
printf 'Built %s\n' "$output"
