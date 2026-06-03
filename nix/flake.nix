{
  description = "andstu's nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    {
      darwinConfigurations = {
        "Andstus-Dev-Machine" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./configuration.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.andstu = import ./home.nix;
            }
          ];
        };
      };
    };
}
