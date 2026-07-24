# dotfiles

My personal configuration for macOS.

## Nix (nix-darwin + Home Manager)

```text
nix/
  modules/          # shared across machines
    packages.nix    # global CLI packages
    home.nix        # Home Manager (packages only for now)
    darwin.nix      # shared macOS / nix-darwin settings
  hosts/
    macbook-pro.nix # this Mac (packages + system defaults)
```

Shared tools live in `nix/modules/packages.nix`. This Mac’s packages and Dock / Finder / trackpad / locale defaults live in `nix/hosts/macbook-pro.nix`.

nix-darwin runs system activation as root, so rebuilds need `sudo`.

First apply (installs `darwin-rebuild` and activates):

```bash
cd ~/Workspace/Projects/dotfiles
sudo nix run nix-darwin -- switch --flake .#mac
```

Later updates:

```bash
sudo darwin-rebuild switch --flake .#mac
```

Stow still manages configs under `config/` (zsh, aerospace.toml, etc.).

## Automated steps (legacy Homebrew / Stow)

Run `bash install.sh --all` to install everything:

* Brew packages, casks, Mac App Store apps
* Link dotfiles with Stow (from `config/` only; `private/` is a submodule for sensitive config)

macOS defaults are applied via Nix (`nix/hosts/macbook-pro.nix`), not `install.sh`.

## Manual steps

### Alfred
Point Alfred’s preference folder to `private/Alfred.alfredpreferences` (or your synced path after linking the repo).

### Configure crontabs

```
2 * * * * /Users/xavier/Workspace/Projects/dotfiles/scripts/obsidian-commit.sh >/dev/null 2>&1
```
