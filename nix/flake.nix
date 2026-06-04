{
  description = "andstu's nix configuration";

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
    nur.url = "github:nix-community/NUR";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nur,
      ...
    }:
    let
      mkDarwin =
        {
          hostname,
          system,
          user,
        }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          modules = [
            ./hosts/${hostname}/configuration.nix
            home-manager.darwinModules.home-manager
            {
              nixpkgs.overlays = [ nur.overlays.default ];
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${user} = import ./hosts/${hostname}/home.nix;
            }
          ];
        };
    in
    {
      # Apply with: darwin-rebuild switch --flake .#<hostname>
      darwinConfigurations = {
        "Andstus-Dev-Machine" = mkDarwin {
          hostname = "personal-mac";
          system = "aarch64-darwin";
          user = "andstu";
        };

        # TODO: replace WORK-HOSTNAME with output of `scutil --get LocalHostName`
        # and update hosts/work-mac/{configuration,home}.nix with the real username
        "WORK-HOSTNAME" = mkDarwin {
          hostname = "work-mac";
          system = "aarch64-darwin"; # change to x86_64-darwin if Intel
          user = "WORK-USERNAME";
        };
      };

      # Apply with: home-manager switch --flake .#andstu
      homeConfigurations = {
        "andstu" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
          modules = [ ./hosts/wsl/home.nix ];
        };
      };
    };
}
