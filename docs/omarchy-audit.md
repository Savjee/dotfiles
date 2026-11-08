# Omarchy customization audit

This is the initial historical snapshot. Mailspring was subsequently removed and configuration sources were centralized as described in [the Stow guide](omarchy-stow.md).

Audited on **1 October 2026**. This PC runs **Omarchy 4.0.4-1 on x86_64 Linux**. The other target is an **M2 MacBook running Linux directly through Asahi**, as confirmed during the audit.

The largest reproducibility gaps are the extra-app install list, most Hyprland overrides, the bar configuration, two custom menu plugins, cloud-mount services, and several scaling/audio helpers. Stow already captures part of the setup, but the existing Nix flake only targets macOS.

## Baseline and confidence

Compared live user files with `/usr/share/omarchy/config/`, and inspected the installed package lists, hardware setup scripts, first-run hooks, default Bash setup, services, and active theme. `pacman -Qkk omarchy` reported **0 altered files**, so the packaged Omarchy files are a useful local baseline.

This is a comparison with the **currently installed version**, not a reconstruction of the original installation. Extra packages can be personal installs, optional Omarchy features, or provisioning/migration results. A differing application file can contain generated state rather than an intentional preference. Those distinctions are called out below.

No settings were applied. Account databases, browser profiles, passwords, OAuth tokens, SSH keys, and private-submodule contents were not copied into the repository. Root-only settings were not inspected; package verification reported permission errors for four Omarchy sudoers files. The MacBook itself was not inspected.

## Apps and tools beyond the current base lists

These explicitly installed packages are outside both current `omarchy-base.packages` and `omarchy-other.packages`, after separating infrastructure entries. They are a candidate personal install list, **not proof that every one was installed manually**. Some are supported optional Omarchy installs.

| Area | Packages observed | Portability notes |
| --- | --- | --- |
| Password management | `1password`, `1password-cli` | Capture integration/setup separately from credentials. |
| Browsing | `helium-browser-bin` | Local launcher and policy-library dependency described below. |
| Editors and coding apps | `cursor-bin`, `zed`, `openai-codex-desktop`, `t3code-bin`, `grok-bot` | Check each app's ARM Linux availability independently. |
| Email, chat, music | `mailspring-bin`, `teams-for-linux-bin`, `spotify` | Account setup remains separate. |
| Calendar/account integration | `gnome-calendar`, `gnome-online-accounts-gtk`, `evolution-ews` | Do not copy account databases. |
| Files and cloud storage | `thunar`, `rclone` | rclone has additional services and authenticated remotes. |
| CAD | `freecad` | App settings were not deeply audited. |
| Terminal, theming, dictation | `ghostty`, `omazed`, `voxtype-bin` | Terminal and microphone settings vary by host. |
| Development/infrastructure tools | `cloudflared`, `direnv`, `nix`, `flatpak`, `nvtop`, `fwupd`, `usbutils` | Avoid taking over firmware/driver ownership from the host OS. |

Also outside the lists: `amd-ucode`, `efibootmgr`, `linux`, `mkinitcpio`, `sudo`, `omarchy`, `omarchy-keyring`, and `omarchy-settings`. These are hardware/OS/provisioning entries, not a suggested personal-app manifest. In particular, **do not copy the PC's kernel/boot/microcode packages to the Asahi MacBook**.

Additional package managers:

* **Flatpak:** `net.donnybeelo.Convey`, installed for `x86_64`.
* **Nix user profile:** only `stow` was observed. This PC is not currently activated from the repository's Home Manager configuration.
* **mise global config:** Node `26.8.1`; Claude, Codex, Cursor Agent, GitHub CLI, Playwright, and OpenCode selected as `latest`. Cursor Agent uses a custom download recipe. This config is outside the repo. The recipe handles architecture, but still needs verification on ARM.
* Other agent launchers exist in `~/.local/bin`; their presence alone does not establish which agents are installed or selected. The active Omarchy default agent is **Codex**.

Stock software such as Docker, Obsidian, OBS, Kdenlive, LibreOffice, Chromium, lazygit, mise, and common shell tools is already in the base package list. It should not be duplicated in a personal additions manifest without a reason.

The base list names `nvim`, while this machine has **`neovim`**, which owns `/usr/bin/nvim`. Neovim is installed; the name difference is not evidence of a removed editor.

## Desktop, keyboard, and monitor changes

Unless otherwise stated, these live in `~/.config/` and are not stored in this repo yet.

| File | Observed behavior | Recommended scope |
| --- | --- | --- |
| `hypr/input.lua` | French Macintosh keyboard layout (`fr`, `mac`), Caps Lock as Compose, and a custom modifier option. | External Apple AZERTY keyboard profile; verify separately for the built-in MacBook keyboard. |
| `xkb/symbols/custom` | Left Option becomes Super; left/right Command become Control; right Option stays available for AltGr. | Keyboard profile, paired with `input.lua`. |
| `hypr/bindings.lua` | Belgian AZERTY resize bindings; Aerospace-style join/expel on Super+Ctrl+Left/Right; F-key brightness/media/menu bindings; universal-copy fix for terminals; 1Password wrapper binding. | Share general workflow, separate keyboard and scaling fixes. |
| `hypr/looknfeel.lua` | Single tiled window constrained to **16:9**; active windows fully opaque, inactive opacity `0.96`. | Shared preference; aspect-ratio choice may depend on display. The nearby comment says 16:10, but the executable value is 16:9. |
| `hypr/monitors.lua` | Kuycon G32P at `6144x3456@60`, scale 2, GTK scale 2; fallback outputs also scale 2. Old LG monitor examples are commented out. | PC/display-specific. Do not force this fallback scale onto the laptop. |
| `hypr/autostart.lua` | Runs `kuycon-dp-audio --watch`. | PC only. |
| `hypr/hyprland.lua` | Adds `require("hypr.windows")` to the stock include structure. | Small shared integration change. Keep loading packaged Omarchy defaults. |
| `hypr/windows.lua` | Spotify and Teams open on workspace 4. | Already linked to the repo, currently untracked. |
| `.XCompose` | Includes stock Omarchy compose definitions plus personal name/email expansions. | Current content is provisioned personal identity, not necessarily a manually written customization. Store privately or generate if desired. |

The PC also has `options hid_apple fnmode=2` in `/etc/modprobe.d/hid_apple.conf`. **That exact setting is stock Omarchy hardware setup**, not a personal change. The personal F-key bindings build on it.

## Appearance, bar, and themes

| Area | Observed state | Repository coverage |
| --- | --- | --- |
| Active theme | **Ristretto Light**; stock initial theme is Tokyo Night. | Only `ristretto-light/colors.toml` is captured, as an identical copy rather than an active link. |
| Additional themes | White Air, several Wallhaven-derived themes, and SpaceX; custom Ristretto backgrounds. | Not captured. Some files are generated theme outputs and should be regenerated. |
| Theme sources | Ristretto Light checkout points to `brokkoli71/omarchy-ristretto-light-theme`; White Air to `o-200/omarchy-white-air-theme` on GitHub. | Record upstream URL and selected revision, then store personal palette changes separately. |
| Bar (`omarchy/shell.json`) | Transparent top bar; clock moved to the right, time-only primary format; weather removed; rclone status added. Clock also has life-counter preferences. | Not captured. |
| Shell service plugins | `xavier.gh-repos` caches GitHub repos for menu search; `xavier.scw` adds Scaleway service search. | Plugin source not captured. |
| rclone bar plugin | `xavier.rclone` shows mount/transfer status and controls. | Already linked; tracked files have working-tree edits. |
| Menu extension | Contains rows published by the GitHub/Scaleway plugins. | Not captured; preserve plugin code and regenerate published rows instead of committing cached private-repo lists. |
| Zed theme hook | `hooks/theme-set.d/omazed` calls `omazed set "$1"`. | Hook not captured. Generated `omazed.json` exists in the repo but is untracked. |
| Aether | Wallpapers directory `~/Wallpapers`; Neovim/VS Code/Zed integration disabled in its settings. | Not captured; replace absolute home path with a host-aware value. |
| GTK preferences | Text scaling `1.1818`, light color scheme, Adwaita, Adwaita Sans 11. | Not captured. Light scheme can be derived from the selected theme; text scaling is a deliberate-looking value, but no pristine dconf baseline was available. |
| btop | Refresh interval reduced from 2000 ms to 1000 ms. Other differences mostly correspond to new version fields/comments. | Not captured. |

Idle settings are **unchanged from stock**: screensaver after 150 seconds, lock after 300 seconds.

## Terminal, editor, shell, and app preferences

| Area | Changes/state | Repository coverage |
| --- | --- | --- |
| Default terminal/browser/email | Ghostty; Helium for web URLs; Mailspring for mailto. LibreOffice Writer handles DOCX. | `xdg-terminals.list` and selected `mimeapps.list` defaults not captured. Keep generated app associations separate from intentional defaults. |
| Ghostty | Omarchy theme include, JetBrainsMono Nerd Font at 9.3 pt to compensate for GTK scaling, padding 14, clipboard/keybinding fixes. | **Live Linux config differs from repo config**. Repo version is macOS-oriented: Flexoki, Caskaydia, 14 pt, macOS titlebar setting, custom tab chords. Separate these profiles before linking. |
| Foot / Alacritty | Font increased from 9 to 11. | Not captured. |
| Kitty | Explicit 11 pt font; padding, decorations, clipboard and CSI-u shortcuts, cursor/bell and tab styling. Some repeat system defaults. | Not captured. |
| lazygit | Disable automatic fetch and self-updates; hide command log; light-theme contrast colors. | Linked and tracked. Comment still refers to Homebrew, although the Linux package is native. |
| Zed | Vim mode, clipboard isolation, VS Code base keymap, custom Control/Super chords, fonts/spacing/panels, PHP/Markdown/Nix language preferences, telemetry disabled, AI disabled plus existing agent configuration. | Linked. Settings/keymap have working-tree edits. Current configured themes are One Light/One Dark; presence of the generated Omarchy theme is not proof it is selected. |
| Cursor | User settings/keybindings shared with macOS paths through repository links. | Linked and tracked. |
| Bash | Keep Omarchy bootstrap/default rc; add shared aliases, Nix daemon environment, and direnv hook. | `.bashrc` itself not captured; shared `lg`/Laravel `artisan` aliases are linked. |
| direnv | `warn_timeout = "5m"`; loads local nix-direnv `3.2.0` source. | Linux files not captured. Nix module expresses direnv/nix-direnv for the macOS profile. |
| Git | Stock ergonomic defaults plus identity and GitHub CLI credential helpers. | Not captured. Helpers contain an absolute path to an older **x86_64** mise GH installation; recreate authentication per host rather than copy that path. |
| OpenCode | OpenRouter flex service-tier options, 900000 ms timeout, model-specific overrides; automatic updates remain disabled. | Not captured. Credentials were not collected. |
| Thunar | Details view, expandable folders, customized toolbar; last-window/sort/zoom state also present. | Not captured. Select intentional preferences instead of the entire runtime-state XML. |
| Agent skills | Newsletter research/tone and strict maintainability-review skills. | Linked and tracked. These can be shared independently of machine hardware. |

## App workarounds and services

| Item | What is installed/configured | What's missing for another machine |
| --- | --- | --- |
| Helium wrapper | Wayland flags, scale-factor cap, 110% default page zoom; hides Chromium machine-theme policy through `LD_PRELOAD` while retaining 1Password integration. | Wrapper/flags are linked, but `~/.local/lib/libhide-chromium-policies.so` and the overridden `helium.desktop` launcher are absent from the repo. Capture source and build recipe, not just this PC's compiled library. |
| 1Password scaling | Wrapper sets `GDK_SCALE=1`, memory GSettings backend, and scale-factor flag; launch override, Hyprland binding, and systemd autostart drop-in. | All outside repo. App rewrites its autostart desktop file, so the drop-in is part of the solution. Review necessity per display/host. |
| Mailspring | Electron scale-factor flag plus a local HTTP onboarding helper and enabled user service to continue without a Mailspring ID. | These files are linked but currently untracked. The helper expects Mailspring's development-config onboarding route; capture/verify the app-side prerequisite as part of any migration. |
| T3 Code | Wayland flags and desktop launcher. Another local URI-handler desktop entry also exists. | Files are linked but currently untracked. Reconcile which launcher handles the URI; do not copy an absolute icon/home path blindly. |
| rclone mounts | Four enabled instances of a custom `rclone-mount@.service`, under `~/Cloud`; full VFS cache capped at 10 GB; Unix socket for plugin control; two SharePoint-specific drop-ins. | Unit template, drop-ins, setup helpers, and enabled-instance declarations are absent from repo. Keep remote names/account mappings private where appropriate and reauthenticate. |
| Voice dictation | Enabled Voxtype service; local Whisper `base.en`, English; uses `sysdefault:CARD=Webcam`, types output with clipboard fallback. | Config outside repo. Service is installer-style integration; microphone identifier is PC-specific. Record model installation separately. |
| Monitor audio | Identical helper installed as a post-boot hook and `~/.local/bin/kuycon-dp-audio`; a watcher is also started by Hyprland. Routes the live connector to an AMD HDMI/DP audio profile. | Not captured. Hardcoded PCI device/connectors are PC-only. Prefer one source file for both entry points. |
| Dock authorization | `/etc/udev/rules.d/99-caldigit-dock-authorize.rules` authorizes one specific CalDigit dock so its keyboard works at disk unlock. | Not captured. Host/device-specific; don't share the dock identifier as a global rule. |
| Nix | Enabled `nix-daemon.service`; flakes/nix-command enabled, max jobs auto. | Capture Linux bootstrap intent separately from the existing nix-darwin configuration. |

The three `post-update.d` hooks inviting dictation, fingerprint setup, and default-agent selection are **byte-identical to Omarchy first-run hooks**. They are not personal additions.

Most enabled system services are stock Omarchy integration (printing, networking, Bluetooth, firewall, display manager, audio, etc.). Enabling a service is not enough evidence to classify it as a customization. Package backup-file differences under `/etc` likewise include normal installation/provisioning state. No wholesale `/etc` sync is proposed.

## Current repository gaps

1. `install.sh` uses Homebrew and iterates over **every** `config/*` package. Even `--dotfiles` has no OS/host selection, so macOS configs and Linux workarounds can be linked onto the wrong host.
2. `flake.nix` exposes only `darwinConfigurations.mac` for `aarch64-darwin`. Neither this PC (`x86_64-linux`) nor the M2 running Asahi (`aarch64-linux`) has a Home Manager target.
3. `nix/modules/packages.nix` overlaps native Omarchy tools (Git, lazygit, eza, bat, yt-dlp, etc.). Importing it unchanged on Linux would create multiple installations; decide ownership first.
4. Active links are not necessarily committed: Hyprland's workspace rule, Mailspring, T3 Code, and Zed's generated theme are currently untracked. Existing Helium, rclone plugin, and Zed files have edits. Preserve/review that work before restructuring.
5. The Ghostty config stored in the repo is **not** the active Linux config. The theme palette is an identical but unlinked copy. Git pull alone won't update either active file.
6. Most of the important personal additions listed above have no install/setup declaration. Stow only handles files; it doesn't install apps, build libraries, set dconf preferences, or enable services.

See [sync options and proposed layout](omarchy-sync-options.md) for how to close these gaps.

## Audit snapshot and follow-up boundary

[omarchy-inventory.json](omarchy-inventory.json) records package-list differences, current foreign packages, selected package-manager state, and the 17 differing stock-template paths. It is a dated observation, not a ready-to-run installer.

For a fully matched setup, audit the MacBook's package availability and keyboard/display defaults before applying the shared layer. Additional preferences inside logged-in apps (OBS, FreeCAD, browsers, mail accounts, extensions) were not exhaustively extracted. Historical defaults and user intent cannot be recovered reliably from current files alone.
