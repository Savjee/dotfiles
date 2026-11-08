# Reproducing this setup across Omarchy machines

Stow has now been selected. The first source-capture implementation is described in [shared configuration and machine profiles](omarchy-stow.md). This document preserves the earlier options comparison; its layout and migration commands are proposals rather than the current file inventory.

## Recommendation

**Keep Stow, add explicit host profiles and native package/setup manifests, and retain Nix for development environments or selected CLI tools.** This builds on the repo's existing structure and keeps Omarchy's desktop, themes, updates, and Asahi hardware support under their native managers.

Nix does not inherently clash with Omarchy. Standalone Home Manager works on existing Linux distributions. The friction is overlapping ownership: immutable Home Manager files where Omarchy/apps expect to write, duplicate tools on PATH, and GPU/desktop integration for Nix-provided GUI apps. The existing nix-darwin target applies to macOS, not the M2's Linux installation. [Home Manager installation modes](https://nix-community.github.io/home-manager/installation.html)

This is a proposed architecture. No installer, active configuration, package ownership, or flake output was changed during the audit.

## Options and tradeoffs

| Approach | Pros | Cons | Fit here |
| --- | --- | --- | --- |
| **Stow + native package manifests + small setup scripts** | Existing repo already uses it; config files stay editable; transparent Git changes; native GUI integration. | No built-in templates, package installation, or service management; scripts must handle backups, host selection, and repeat runs. | **Recommended starting point.** Two Linux hosts plus existing macOS files don't require a complete migration. |
| **chezmoi + native packages** | Built-in templates and machine-specific data; diff/apply workflow; password-manager integration; target files remain ordinary writable files. | Migration from current Stow layout; edits in live files need importing into source; setup scripts still handle packages/services. | Best alternative if host differences start spreading through many individual files. [Machine differences](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/), [source/target design](https://www.chezmoi.io/user-guide/frequently-asked-questions/design/). |
| **Home Manager on Omarchy** | Declarative CLI packages, user services, preferences and files; pinned flake inputs; reusable Linux/macOS modules and generations. | Normally links managed configs into the read-only Nix store; conflicts with app/theme writes; more Nix maintenance; Linux GUI packages need extra GPU integration. Does not make Arch/Asahi system packages declarative. | Good optional layer for CLI tools/services, after defining who owns each file/tool. [Managed-file collisions](https://nix-community.github.io/home-manager/usage/dotfiles.html), [non-NixOS GPU support](https://nix-community.github.io/home-manager/usage/gpu-non-nixos.html). |
| **Ansible + native packages + configs** | Good for repeatable package/service/root-file setup; host variables, check mode, useful once managing several machines. | More structure/dependencies than a two-machine personal setup needs; AUR management needs separate care; doesn't pin Arch versions like a Nix closure. | Consider when privileged setup becomes substantial. [Native pacman module](https://docs.ansible.com/projects/ansible/latest/collections/community/general/pacman_module.html). |
| **Replace the OS with NixOS** | Declarative system plus user configuration, coherent system generations. | Replaces the Arch foundation; reproducing Omarchy behavior and Apple hardware support becomes your responsibility. | A different OS project; unnecessary to solve the current repetition. |

Stow links files; Git transports changes; package manifests describe what to install; setup scripts apply preferences and enable services. None of these by itself keeps all machines automatically synchronized. [GNU Stow manual](https://www.gnu.org/software/stow/manual/stow.html)

## Ownership rules

| Layer | Owner |
| --- | --- |
| Kernel, boot, firmware, GPU/audio stack, compositor and desktop integration | Omarchy / native distro / Asahi |
| Stock default files under `/usr/share/omarchy` | Omarchy package; read them, don't commit copies as personal configs |
| Personal editable overrides, plugin source, wrappers, selected app settings | This repository, deployed with Stow |
| Additional GUI apps | Native repositories/AUR/Flatpak, selected per host and architecture |
| Node, agent CLIs, existing mise runtime workflow | mise initially; move an individual tool to Nix only deliberately |
| Project development dependencies | Project flakes/dev shells where useful |
| Selected extra shared CLI tools | Native packages initially, or a scoped Home Manager module |
| Secrets, OAuth tokens, app accounts, SSH/Git authentication | Password manager/private storage plus per-machine login |
| Theme output, menu caches, browser profiles, databases, temporary/session state | Generated locally; don't deploy wholesale |

Don't let Stow and Home Manager manage the same path. Don't install the same command through native packages, mise, and Nix without an intentional reason and clear PATH precedence.

Omarchy's public customization model is user overrides in `~/.config`, retaining the packaged defaults. [Omarchy dotfiles](https://omarchy.org/manual/dotfiles/)

## Proposed repository layout

Keep the existing `config/<package>/` Stow convention and add named packages where platform/host differences exist. Names below are illustrative future directories; they haven't been created.

```text
config/
  shell/                  # current shared aliases
  lazygit/                # current preferences
  zed/                    # portable source settings, exclude generated theme if regenerated
  agents/                 # current skills
  bash-omarchy/           # .bashrc with stock Omarchy bootstrap + personal additions
  hypr-shared/            # workflow/window rules; small loader for personal modules
  keyboard-apple-azerty/  # XKB definitions + keyboard-specific bindings
  omarchy/                # personal shell/plugin source + palette overrides
  rclone/                 # unit template + generic helpers, no authenticated config
  helium/                 # wrapper, flags, launcher, policy helper source
  mailspring/             # existing workaround files
  t3code/                 # existing flags/launcher
  ghostty-linux/          # Linux theme include + keyboard behavior
  ghostty-macos/          # current macOS preferences
  host-desktop/           # monitor/audio overrides, per-display scaling adjustments
  host-macbook-m2/        # built-in display/input/audio choices verified on that machine
  aerospace/             # macOS only
  zsh/                   # macOS profile initially
hosts/
  desktop.conf            # selected Stow packages, apps, services, preference profile
  macbook-m2.conf          # aarch64-linux; no desktop monitor/AMD audio assumptions
  macos.conf              # aarch64-darwin, if macOS is still maintained
packages/
  omarchy-common.txt       # selected additions available for both hosts
  omarchy-x86_64.txt       # x86-only native additions
  omarchy-aarch64.txt      # ARM alternatives / supported additions
  aur-x86_64.txt           # distinguish AUR from repository packages
  aur-aarch64.txt
  flatpak-common.txt       # only apps with verified builds for both architectures
  mise.toml               # portable global tools and custom recipe
preferences/
  omarchy-common.sh       # selected gsettings/default-app preferences
  desktop.sh              # display-dependent text scaling, if still needed
system/
  desktop/udev/           # explicitly selected device rule, separately installed
nix/
  modules/                # retain existing macOS modules; separate Linux package subset
  hosts/                  # optional Linux Home Manager profiles
scripts/
  apply.sh                # future explicit --host + --dry-run workflow
  check.sh                # future drift/link/dependency checks
private/                  # existing private submodule; optional credential-free private metadata
docs/
  omarchy-audit.md
  omarchy-sync-options.md
  omarchy-inventory.json
```

A host profile is a composition of shared files plus host-specific modules. Keep both hosts on the same Git branch. Each target path must have **one** selected owner: two Stow packages cannot both provide `~/.config/hypr/monitors.lua` or `~/.config/ghostty/config`.

For Hyprland, keep the stock loader structure and add a small personal loader that includes shared workflow modules and the selected host overrides. Alternatively, select one complete override file per host. Preserve dependency order: the XKB mapping and keyboard config travel together; `windows.lua` needs its require line. Avoid a permanent fork of all stock Hyprland defaults.

## What the apply workflow should do

1. **Validate the selected host and platform.** PC is `x86_64-linux`; M2 is `aarch64-linux`. `aarch64-darwin` only means macOS. Don't infer a keyboard or monitor purely from CPU architecture.
2. **Install only declared additions**, without pruning stock packages. Resolve native repository packages, AUR packages and Flatpaks separately; verify availability on ARM and record alternatives or intentional skips. Keep Omarchy responsible for system upgrades. A desired native package list reproduces selection, not exact versions on rolling Arch.
3. **Preview file changes and collisions.** Back up selected existing files before replacing them with links. Keep app-state directories real and link individual owned files with Stow's `--no-folding`. Never adopt the entire `~/.config` tree. `stow --adopt` moves existing content into the repo and can overwrite the intended source, so it isn't a routine bootstrap command.
4. **Apply selected preferences and dependencies.** Set chosen default apps and GTK text scaling; install theme/plugin sources at recorded revisions; build the Helium policy helper for the host architecture; enable the selected user-service instances. Preserve executable bits for wrappers/hooks.
5. **Handle account setup separately.** Log in to 1Password/GitHub/email, authorize each rclone remote, and keep resulting tokens out of Git. A private submodule is useful for private metadata but doesn't itself encrypt secrets.
6. **Verify the resulting state.** Run `hyprctl reload` and `hyprctl configerrors` after Hyprland changes; reload systemd units and inspect selected service status; test default launchers and custom bar/menu plugins. Confirm active files still point to the intended source after commands that rewrite preferences.

For current, already-captured shared packages, this is a **read-only Stow preview**, run from the repository root:

```bash
stow --simulate --verbose --no-folding --dir=config --target="$HOME" shell lazygit agents
```

A real install should use an explicit profile package list, not the current `for dir in config/*/` loop. Existing whole-directory links need a planned transition; adding `--no-folding` isn't a blanket repair for links already deployed.

Apply functions should compare before changing, preserve unrelated files/preferences, stop on failures, and report skipped architecture-specific apps. Root-owned setup should be a small explicit stage; do not Stow `/etc` wholesale.

## Where Nix helps without taking over Omarchy

Keep the existing Darwin output if macOS is still a target. If using Home Manager on Linux, add separate standalone outputs such as `homeConfigurations."xavier@desktop"` (`x86_64-linux`) and `homeConfigurations."xavier@macbook-m2"` (`aarch64-linux`), with Linux home paths. That work is independent of nix-darwin.

Don't import the current shared package module unchanged: several packages duplicate stock Omarchy commands. First split the package intent into native-owned desktop/shell tools, mise-owned runtimes, and a small optional Nix CLI subset. Platform-filter macOS-only tools.

Use Home Manager for selected packages, user services or declarative preferences if that reduces scripts. Keep theme-writable Omarchy/app configs in ordinary files or Stow-owned links. Out-of-store links can be an escape hatch for Home Manager, but then those files are mutable and no longer fully pinned by the Nix generation. Using both tools just to link files adds little value.

Native GUI apps are the practical default here. Nix GUI apps on non-NixOS may require GPU-library setup or wrapping, and inherited libraries can interfere with launching native apps. Apple GPU support needs host-specific validation too; merely selecting `aarch64-linux` doesn't solve it. [Home Manager GPU guidance](https://nix-community.github.io/home-manager/usage/gpu-non-nixos.html)

Nix pins its own inputs/packages and can restore its own generations. It does not roll back Arch packages, mutable browser profiles, authenticated accounts, or host firmware as part of a Home Manager rollback.

## Sync and update workflow

On the machine where you make a change, edit the repository-owned config (a Stow-linked live file normally edits the repo source), review `git diff`, commit and push. On another machine, pull the same branch and apply its own profile. Adding/removing files or packages requires reapplying; linked file edits generally appear immediately after pull, and some apps need reloads.

Avoid unattended pulls into a live desktop: tracked links can make incoming edits take effect before validation. A deliberate pull/apply/check command is easier to recover and review. On an Omarchy update, let its migrations run, inspect affected overrides, check for replaced links, and validate compatibility. Do not blindly reapply an old config schema through a post-update hook.

Theme selection should be declared as intent and applied through Omarchy. Capture palette inputs and personal hook/plugin source. Let Omarchy regenerate current-theme artifacts, and let the GitHub/Scaleway plugins regenerate their menu rows. The clock/bar source settings are personal preferences; private GitHub search cache content is generated data.

## Suggested migration order

1. Preserve existing working-tree edits/untracked files; collect the missing source files identified by the audit. Keep Linux/macOS Ghostty configs separate immediately.
2. Add explicit host selection and dry-run behavior before extending `install.sh` or introducing `apply.sh`.
3. Add personal package manifests, mise config, generic service templates, and chosen preferences. Capture Helium's policy-library source/build recipe; resolve old absolute Git credential-helper paths by per-host authentication.
4. Add the desktop hardware profile, then inspect and define the M2 profile. Validate app availability and workarounds on the real ARM host.
5. Prove a repeated apply is safe and leaves no unexplained drift. Add scoped Home Manager CLI/service support only if desired.

This preserves the parts already working while turning the missing setup steps into reviewable declarations. The [audit](omarchy-audit.md) identifies which files are already linked, which differ, and which are still outside the repository.
