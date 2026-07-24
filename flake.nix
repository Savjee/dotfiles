{
  description = "Xavier's system configs (nix-darwin + Home Manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nix-darwin,
      home-manager,
      ...
    }:
    let
      username = "xavier";
    in
    {
      # Apply with: sudo darwin-rebuild switch --flake .#mac
      darwinConfigurations.mac = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit username; };
        modules = [
          ./nix/modules/darwin.nix
          ./nix/hosts/macbook-pro.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./nix/modules/home.nix;
          }
        ];
      };

      # Later (Linux):
      # nixosConfigurations.box = …;  # full NixOS
      # — or —
      # homeConfigurations.${username} = …;  # Home Manager on an existing distro
      # Both can import ./nix/modules/home.nix (and thus packages.nix).
    };
}
