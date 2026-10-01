# dotfiles

My personal configuration for Omarchy Linux and macOS.

## Omarchy with Stow

Shared settings are selected in `profiles/omarchy-common.stow`. Each machine adds its own profile:

* `omachine`: this PC's displays, scaling and audio routing.
* `macbook-m2`: the common layer; preserves the laptop's existing display/audio setup.

Apple AZERTY, keyboard shortcuts, workspace rules, themes and service plumbing are shared. Monitor settings and audio routing are never in the common layer. Credentials and generated account/cache data remain local.

This is the capture/review stage. Preview without changing any files:

```bash
scripts/preview-omarchy-stow.sh omachine
scripts/preview-omarchy-stow.sh macbook-m2
```

The preview command has no apply mode. See [configuration ownership and deployment notes](docs/omarchy-stow.md) before linking anything.

* [Original Omarchy audit](docs/omarchy-audit.md)
* [Sync options and tradeoffs](docs/omarchy-sync-options.md)
* [Historical audit snapshot](docs/omarchy-inventory.json)

## Legacy macOS setup

The Nix and Homebrew workflow below is for macOS, not the M2's Asahi Linux installation. The legacy installer uses the explicit macOS Stow profile and refuses to run on Linux.

## Nix (nix-darwin + Home Manager)

```text
nix/
  modules/          # shared across machines
    packages.nix    # global CLI packages
    home.nix        # Home Manager (packages + direnv / nix-direnv)
    darwin.nix      # shared macOS / nix-darwin settings
  hosts/
    macbook-pro.nix # this Mac (packages + system defaults)
```

Shared tools live in `nix/modules/packages.nix`. Direnv + nix-direnv are enabled in `home.nix` so every flake project caches its shell on `cd`. This Mac’s packages and Dock / Finder / trackpad / locale defaults live in `nix/hosts/macbook-pro.nix`.

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
