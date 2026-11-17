#!/bin/bash
# Let Helium use the native messaging hosts that 1Password and Omarchy install
# for Chromium (1Password browser integration, copy-url, yt-dlp).
# 1Password also needs Helium in /etc/1password/custom_allowed_browsers (omarchy/etc).
src=~/.config/chromium/NativeMessagingHosts
dst=~/.config/net.imput.helium/NativeMessagingHosts
[[ -d $src ]] || exit 0
mkdir -p "$dst"
for f in "$src"/*.json; do
  [[ -e $f ]] || continue
  [[ -L $dst/${f##*/} ]] || { ln -sf "$f" "$dst/"; echo "linked ${f##*/} for Helium"; }
done
