{ ... }:

{
  imports = [
    ../../modules/darwin/default.nix
    ../../modules/darwin/homebrew.nix
  ];

  # Personal-only casks (extends the shared list in homebrew.nix)
  homebrew.casks = [ "signal" ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.andstu = {
    name = "andstu";
    home = "/Users/andstu";
  };

  system.primaryUser = "andstu";
}
