#!/bin/bash
# Source the shared aliases (stow package config/shell) from ~/.bashrc.
line='[[ -r ~/.config/shell/aliases.sh ]] && source ~/.config/shell/aliases.sh'
if ! grep -qF "$line" ~/.bashrc; then
  printf '\n# Shared aliases (lg, artisan, …) from dotfiles\n%s\n' "$line" >>~/.bashrc
  echo "added shared aliases to ~/.bashrc"
fi
