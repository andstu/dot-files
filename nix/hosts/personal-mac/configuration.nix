{ ... }:

{
  imports = [ ../../modules/darwin/default.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.andstu = {
    name = "andstu";
    home = "/Users/andstu";
  };

  system.primaryUser = "andstu";
}
