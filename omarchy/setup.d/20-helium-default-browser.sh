#!/bin/bash
# Helium as default browser. `omarchy default browser` doesn't know Helium,
# so set it the way that command does.
[[ -f /usr/share/applications/helium.desktop ]] || exit 0
if [[ $(omarchy-cmd-default-browser) != helium.desktop ]]; then
  env -u BROWSER XDG_CURRENT_DESKTOP= xdg-settings set default-web-browser helium.desktop
  echo "Helium is now the default browser"
fi
