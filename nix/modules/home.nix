{ pkgs, ... }:
{
  home.stateVersion = "25.11";

  # Shared CLI tools — Stow still manages dotfiles under ~/.config.
  home.packages = import ./packages.nix pkgs;

  # Machine-wide nix-direnv: caches `use flake` so cd does not re-evaluate.
  # The zsh hook stays in Stow-managed ~/.zshrc (do not enable programs.zsh).
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.home-manager.enable = true;
}
