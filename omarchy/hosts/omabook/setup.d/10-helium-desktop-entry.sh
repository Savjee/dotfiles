#!/bin/bash
# Make app launchers and `omarchy launch browser` start Helium through
# ~/.local/bin/helium-browser (smaller UI font). Omarchy's browser launcher only
# uses the first word of Exec=, so the wrapper is put there as an absolute path.
# Regenerated from the packaged entry on every apply, so package updates come through.
src=/usr/share/applications/helium.desktop
dst="$HOME/.local/share/applications/helium.desktop"
[[ -f $src ]] || exit 0

entry="$(sed "s|^Exec=helium-browser|Exec=$HOME/.local/bin/helium-browser|" "$src")"
if [[ ! -f $dst || $(<"$dst") != "$entry" ]]; then
  mkdir -p "${dst%/*}"
  printf '%s\n' "$entry" >"$dst"
  echo "updated $dst"
fi
