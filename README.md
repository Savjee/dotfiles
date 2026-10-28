# dotfiles

My personal configuration for macOS.

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

## Shared agent skills (Linux and macOS)

Skills live in `config/agents/.agents/skills/`. The `agents` Stow package also
links them into `~/.claude/skills/` and `~/.codex/skills/`. OpenCode and Cursor
discover the shared `~/.agents/skills/` directory directly; T3 Code uses the
skills of its selected harness.

After cloning or pulling this repository on each machine, run from the repo root:

```bash
stow --dir=config --target="$HOME" agents
```

This only installs the shared skills and works independently of the legacy
macOS installer. GNU Stow must be installed. Start a new agent turn/session
after linking so the harness discovers the skills.

All nine [tstack skills](docs/tstack/README.md) are imported unchanged.
Their PR workflows require an authenticated GitHub CLI (`gh`), and
`babysit-pr` also needs Python 3. `council` and `sol-loop` need a harness
capable of delegating to the requested providers/models.

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
