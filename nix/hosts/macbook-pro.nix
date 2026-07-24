{ pkgs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  environment.systemPackages = with pkgs; [
    aerospace # Tiling window manager
    jankyborders # Add colored border to active windows
  ];
}
