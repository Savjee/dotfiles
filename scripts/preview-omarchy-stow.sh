#!/usr/bin/env bash
# Review links and collisions without changing any target files.
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
usage() {
  printf 'Usage: %s {omachine|macbook-m2} [--target DIRECTORY]\n' "${0##*/}"
  printf '%s\n' 'This command always runs Stow in simulation mode.'
}

if [[ ${1:-} == --help ]]; then
  usage
  exit 0
fi
case ${1:-} in
  omachine|macbook-m2) profile=$1 ;;
  *) usage >&2; exit 2 ;;
esac
shift
target=$HOME
if (( $# )); then
  if [[ $# != 2 || $1 != --target ]]; then usage >&2; exit 2; fi
  target=$2
fi
[[ -d $target ]] || { printf 'Target is not a directory: %s\n' "$target" >&2; exit 2; }
command -v stow >/dev/null || { printf '%s\n' 'GNU Stow is required.' >&2; exit 1; }

packages=()
while IFS= read -r package || [[ -n $package ]]; do
  [[ -z $package || $package == \#* ]] && continue
  [[ $package =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ && -d $repo/config/$package ]] || {
    printf 'Invalid or missing Stow package: %s\n' "$package" >&2
    exit 2
  }
  packages+=("$package")
done < <(cat "$repo/profiles/omarchy-common.stow" "$repo/profiles/$profile.stow")

printf 'Previewing %s (%s); no files will be changed.\n' "$profile" "$target"
exec stow --simulate --verbose --no-folding --dir="$repo/config" --target="$target" "${packages[@]}"
