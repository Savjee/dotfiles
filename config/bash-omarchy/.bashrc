# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# Shared aliases (lg, artisan, …) — also sourced from macOS ~/.zshrc
if [ -r "$HOME/.config/shell/aliases.sh" ]; then
  # shellcheck source=/dev/null
  source "$HOME/.config/shell/aliases.sh"
fi

# Nix: user profile + daemon client env (Arch package; skip if missing)
if [[ -r /etc/profile.d/nix-daemon.sh ]]; then
  # shellcheck source=/dev/null
  . /etc/profile.d/nix-daemon.sh
fi

# direnv: load flake.nix / .envrc when you enter a project directory
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook bash)"
fi
