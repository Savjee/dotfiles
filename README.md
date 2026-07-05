# dotfiles

My personal configuration for macOS.

## Automated steps

Run `bash install.sh --all` to install everything:

* macOS defaults
* Brew packages, casks, Mac App Store apps
* Link dotfiles with Stow (from `config/` only; `private/` is a submodule for sensitive config)

## Manual steps

### Alfred
Point Alfred’s preference folder to `private/Alfred.alfredpreferences` (or your synced path after linking the repo).

### Configure crontabs

```
2 * * * * /Users/xavier/Workspace/Projects/dotfiles/scripts/obsidian-commit.sh >/dev/null 2>&1
```
