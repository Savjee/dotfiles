# Shared Omarchy configuration and machine profiles

The repository now contains the shared personal configuration and the current PC's hardware overrides. This is a **capture and review stage**: the new Omarchy command only previews Stow operations. It does not install packages, replace files, enable services, change themes, or apply preferences.

The branch was prepared in an isolated checkout because the original checkout already has live Stow links. Editing those source files directly would have changed the running desktop before review.

## Shared configuration

`profiles/omarchy-common.stow` selects the following packages for every Omarchy machine:

| Package | Source configuration |
| --- | --- |
| `hypr` | Apple AZERTY input/XKB mapping, keyboard shortcuts, workspace rules, shared opacity preference and the Omarchy-compatible loader |
| `omarchy` | Bar preferences, rclone/GitHub/Scaleway plugins, custom theme inputs, selected backgrounds and the Zed theme hook |
| `rclone` | Mount service template, interactive authentication helpers, escaped unit-name control and optional SharePoint mount settings |
| `voxtype` | User-service plumbing; each device supplies its own microphone configuration |
| `ghostty-omarchy` | Theme integration, keyboard/clipboard behavior and other terminal preferences; optional machine font-size override |
| `helium`, `1password`, `t3code` | Portable launchers/integration; display workarounds come from an optional machine file |
| `bash-omarchy`, `shell`, `mise` | Bash bootstrap, aliases, direnv/nix-direnv source and global tool selections |
| `git`, `lazygit`, `zed`, `vim`, `opencode`, `agents` | Personal tooling/editor preferences and skills |
| `omarchy-apps` | Selected MIME defaults, Ghostty terminal preference and Codex agent preference; Convey handles mail links |

The shared layer contains **no monitor configuration or audio routing**. It keeps loading Omarchy's packaged defaults. The existing shortcut overrides retain their behavior: Super+Shift+Slash launches passwords, Super+Ctrl+Left/Right uses the custom join/expel behavior, F9 controls media, and Super+C uses the terminal-aware copy fix.

## Machine profiles

`profiles/omachine.stow` adds `config/omarchy-omachine/` for this PC:

* `hypr/monitors.lua`: Kuycon 6K mode and monitor/GTK scaling.
* `hypr/machine.lua`: display-dependent single-window aspect ratio.
* `hypr/autostart.lua` and the post-boot hook: device-specific display-audio helper.
* `omarchy/machine/electron.env`: Electron scaling workaround and Helium page zoom.
* `omarchy/machine/ghostty.conf` and the other terminal configs: this PC's font-size choices.
* 1Password's autostart service drop-in.
* Voxtype's current webcam microphone configuration.

`preferences/omachine.sh` records the PC's GTK text-scaling preference. The CalDigit dock authorization rule is source-only under `system/omachine/udev/`; Stow never targets `/etc`.

`profiles/macbook-m2.stow` currently adds no hardware package. It uses the same shared layer while leaving the MacBook's existing `monitors.lua`, `autostart.lua`, audio configuration, and display scaling alone. A real Omarchy installation already provides its local monitor/autostart files. Do not copy the PC package into this profile; capture the laptop's settings in a separate package when it can be inspected.

The M2 profile is for **aarch64 Linux through Asahi**, not the existing macOS Nix target. The legacy macOS Stow packages remain available through an explicit `profiles/macos.stow`; the legacy installer refuses to apply dotfiles on Linux.

## Previewing the profiles

From this branch checkout:

```bash
scripts/preview-omarchy-stow.sh omachine
scripts/preview-omarchy-stow.sh macbook-m2
```

Both commands always use `stow --simulate --no-folding`. A collision is useful review information, not permission to overwrite or adopt a live file. There is deliberately no apply option in this stage. Existing links point into the original checkout and may conflict with the isolated branch checkout.

After review, deployment needs a separate backed-up transition: select a stable checkout, preserve existing machine files, resolve the explicit collisions, and then link the chosen profile. `--no-folding` keeps application directories real and links owned files individually. Never use `stow --adopt` across the full config tree.

## Rclone credentials and mount plumbing

No authenticated `rclone.conf`, remote list, tokens, cloud contents, or enabled-instance symlinks were copied. The shared template can mount any locally authenticated remote under `~/Cloud/<remote>` and exposes the Unix RC socket expected by the bar plugin.

Once the source files have been reviewed and deployed, authenticate with `rclone config` (or the supplied interactive setup helper) and enable the local instance explicitly:

```bash
rclone-mount-enable 'Google Drive'
rclone-mount-enable 'My SharePoint library' --sharepoint
```

The SharePoint option creates a local service drop-in for the checksum/size compatibility settings. Remote names with spaces, plus signs and hyphens are escaped through `systemd-escape`; the plugin uses the same control helper. Names containing slashes/newlines are rejected because they would also become mount/socket paths.

These commands require native `rclone`, `fuse3`, `systemd`, `ripgrep` and the bar helper's `jq`. They weren't run during capture. The authentication helpers require the mount template to be deployed first. The service is configured for the current native Linux paths and is shared across the two Linux architectures.

## Themes and browser integration

Theme palettes, light-mode/icon inputs and selected CSS overrides are in the shared `omarchy` package. The current Ristretto wallpaper and the locally created SpaceX wallpaper are included. Other downloaded wallpaper collections are left as local assets, and generated current-theme outputs are excluded.

`themes/sources.json` records the theme/background choice and upstream checkout revisions for Ristretto Light and White Air. It does not install those upstream repos. Optional additional upstream backgrounds/assets can be retrieved from those sources later; apply the shared palette overrides after installing an upstream theme. Omarchy regenerates its application theme files from the inputs. Zed's generated `omazed.json` is likewise regenerated by the theme hook instead of being versioned as personal source.

The Helium policy helper is stored as C source, not a compiled x86 library. After review, compile it on each host:

```bash
scripts/build-helium-policy-helper.sh
```

This requires a native C compiler. `helium-launch` loads the resulting `~/.local/lib/libhide-chromium-policies.so` when present. Helium and 1Password use distinctly named launchers so system executables earlier on PATH do not bypass the personal launcher. Machine scaling settings are optional; the MacBook receives no PC scale factor or zoom setting from the shared package.

## Settings that remain local

Git identity goes in the untracked `~/.config/git/identity.conf`; authenticate `gh` separately. Browser/mail account databases, OAuth/password-manager state, cloud credentials, private menu caches, Aether runtime state and unrelated application data remain local. mise tool selections are captured, but tool installation is separate; selectors currently set to `latest` don't promise identical installed versions.

Mailspring and its data were removed from the current PC at the user's request, including the local onboarding workaround. Convey remains installed through Flatpak. The earlier audit documents are historical snapshots from before that cleanup.
