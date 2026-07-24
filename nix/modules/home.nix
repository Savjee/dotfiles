{ pkgs, ... }:
{
  home.stateVersion = "25.11";

  # Shared CLI tools — Stow still manages dotfiles under ~/.config.
  home.packages = import ./packages.nix pkgs;

  programs.home-manager.enable = true;
}
