# Shared aliases and helpers for bash and zsh (macOS + Linux).
# Sourced from ~/.zshrc and ~/.bashrc.

alias lg='lazygit'

# Walk up from $PWD to find Laravel's artisan. A function (not an alias)
# so zsh completion stays on artisan commands, not filenames.
unalias artisan 2>/dev/null || true
artisan() {
  local dir="$PWD"
  while [ "$dir" != / ]; do
    if [ -x "$dir/artisan" ] || [ -f "$dir/artisan" ]; then
      php "$dir/artisan" "$@"
      return $?
    fi
    dir=$(dirname "$dir")
  done
  echo "No artisan found above $PWD" >&2
  return 1
}
