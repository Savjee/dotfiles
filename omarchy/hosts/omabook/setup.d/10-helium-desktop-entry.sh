#!/bin/bash
# Make app launchers and `omarchy launch browser` start Helium through
# ~/.local/bin/helium-browser (smaller UI font). Omarchy's browser launcher only
# uses the first word of Exec=, so the wrapper is put there as an absolute path.
# Regenerated from the packaged entry on every apply, so package updates come through.
src=/usr/share/applications/helium.desktop
dst="$HOME/.local/share/applications/helium.desktop"
wrapper="$HOME/.local/bin/helium-browser"
[[ -f $src ]] || exit 0
# The wrapper is stowed. Skip until it exists so a conflicted apply doesn't
# point launchers at a missing binary; the next apply rewrites this entry.
[[ -x $wrapper ]] || exit 0

entry="$(sed "s|^Exec=helium-browser|Exec=$wrapper|" "$src")"
if [[ ! -f $dst || $(<"$dst") != "$entry" ]]; then
  mkdir -p "${dst%/*}"
  printf '%s\n' "$entry" >"$dst"
  echo "updated $dst"
fi
