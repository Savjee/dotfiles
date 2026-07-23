#!/usr/bin/env bash
# Center + resize the frontmost window if its app is listed in floating-apps.conf.
#
# aerospace.toml:
#   on-focus-changed = ['exec-and-forget ~/.config/aerospace/scripts/center-floating-apps.sh']
#
# Config sizes accept % or px, e.g. 70% 80% or 480px 800px (bare numbers = %).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="${HOME}/.config/aerospace/floating-apps.conf"

[[ -f "$CONF" ]] || exit 0

FRONT_ASN="$(lsappinfo front 2>/dev/null || true)"
[[ -n "$FRONT_ASN" ]] || exit 0

APP_ID="$(lsappinfo info -only bundleID "$FRONT_ASN" 2>/dev/null | sed -E 's/^"CFBundleIdentifier"="(.*)"$/\1/')"
[[ -n "$APP_ID" ]] || exit 0

WIDTH_SPEC=""
HEIGHT_SPEC=""
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  # shellcheck disable=SC2086
  set -- $line
  [[ $# -eq 3 ]] || continue
  if [[ "$1" == "$APP_ID" ]]; then
    WIDTH_SPEC="$2"
    HEIGHT_SPEC="$3"
    break
  fi
done < "$CONF"

[[ -n "$WIDTH_SPEC" && -n "$HEIGHT_SPEC" ]] || exit 0

PID="$(lsappinfo info -only pid "$FRONT_ASN" 2>/dev/null | sed -E 's/^"pid"=(.*)$/\1/')"

for _ in 1 2 3 4 5 6 8; do
  if osascript "$SCRIPT_DIR/center-floating-apps.applescript" \
    "$APP_ID" "$WIDTH_SPEC" "$HEIGHT_SPEC" "$PID" 2>/dev/null
  then
    exit 0
  fi
  sleep 0.05
done

exit 0
