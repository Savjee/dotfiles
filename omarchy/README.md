# Omarchy

Config shared between my Omarchy machines:

| Host | Machine |
|---|---|
| `omabook` | MacBook Pro M2 Pro (Asahi, aarch64) |
| `omachine` | Minisforum mini PC (x86_64) |

## Layout

```
omarchy/
├── bin/dotfiles          # apply | status | capture | adopt (linked to ~/.local/bin/dotfiles)
├── home/<pkg>/           # stow packages for every machine (hypr, omarchy, …)
├── etc/                  # copied to /etc with sudo (not symlinked)
├── packages.txt          # packages for every machine
├── setup.d/              # idempotent scripts for things that aren't files
└── hosts/<hostname>/
    ├── home/             # stow package for this machine only
    ├── etc/
    ├── setup.d/          # run after the shared setup.d
    ├── packages.txt
    └── packages.ignore   # installed packages `dotfiles capture` should not suggest
```

Also linked from `config/` (shared with macOS): `agents`, `shell`, `vim`.

Machine-specific Hyprland config goes in `hosts/<hostname>/home/.config/hypr/host.lua`.
The shared `hyprland.lua` loads it last, if it exists. `monitors.lua` is not tracked.

## Workflow

```bash
# on the machine where you changed something
dotfiles status        # repo changes, files Omarchy overwrote, missing/new packages
dotfiles capture       # sort new packages into packages.txt / the host list / ignore
git commit -am "…" && git push

# on the other machine
dotfiles apply         # pull, link, install missing packages, sync /etc, run setup.d
```

Packages are installed from the Arch/Omarchy repos, or from the AUR when no repo has
them. `apply` never removes packages.

## Gotchas

- Some Omarchy commands rewrite config files with `sed -i` or `omarchy refresh`, which
  replaces the symlink with a plain file. `dotfiles status` reports these as
  "overwritten"; `dotfiles adopt` takes the changed version back into the repo.
- The Omarchy shell recreates `~/.config/omarchy/shell.json` as soon as it disappears.
  To replace it by hand, swap it atomically: `ln -s <repo file> tmp && mv -T tmp shell.json`.
- A change under `etc/modprobe.d` makes `apply` rebuild the initramfs. Reboot afterwards.

## First run on a new machine

```bash
git clone https://github.com/savjee/dotfiles ~/Projects/dotfiles
~/Projects/dotfiles/omarchy/bin/dotfiles apply
```

If stow reports existing files, apply still installs packages, syncs `/etc`, and runs
`setup.d`. Run `dotfiles adopt` to take this machine's versions into the repo, then
compare with `git diff` and keep what you want (`git checkout -- <file>` restores the
repo version). Run `dotfiles apply` again afterwards so anything adopt just linked is
picked up.

## omabook keyboard

Belgian Apple keyboard, with Mac-style app shortcuts and Omarchy shortcuts in the
same position as on a PC keyboard:

| Key | Acts as |
|---|---|
| Cmd | Ctrl (Cmd+T, Cmd+C, …), set in the kernel: `etc/modprobe.d/hid_apple.conf` |
| Option | Super (Omarchy shortcuts) |
| Ctrl | Alt |
| right Cmd / right Option | AltGr |
| key left of 1 | `@` / `#` |

Cmd→Ctrl has to happen in the kernel. Helium/Chromium on Wayland look at the physical
keycode, so an xkb-only remap (or forwarding the key from Hyprland) doesn't work there.
The rest is in `hosts/omabook/home/.config/xkb/symbols/be_apple`.
