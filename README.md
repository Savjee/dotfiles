# dotfiles

My personal configuration for macOS.

## Automated steps

Run `bash install.sh --all` to install everything:

* macOS defaults
* Brew packages, casks, Mac App Store apps
* Link dotfiles with Stow
* 

## Manual steps

### Alfred
Set the preference folder to `linked_files/alfred/`.

### Configure crontabs

```
2 * * * * /Users/xavier/Workspace/Projects/dotfiles/scripts/obsidian-commit.sh >/dev/null 2>&1
```
