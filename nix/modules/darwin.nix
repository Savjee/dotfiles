{ username, ... }:
{
  # Who owns interactive nix-darwin activation
  system.primaryUser = username;

  users.users.${username} = {
    home = "/Users/${username}";
  };

  # Flakes / nix-command (safe even if already set in /etc/nix/nix.conf)
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Keep build-time closures so nix-direnv's cached shells survive GC.
  nix.settings.keep-outputs = true;
  nix.settings.keep-derivations = true;

  # AppCleaner, …
  nixpkgs.config.allowUnfree = true;

  # Stow still manages most dotfiles under config/; packages/defaults are host-owned.
  programs.zsh.enable = true;

  system.stateVersion = 5;
}
