{ ... }:

# TODO: replace WORK-HOSTNAME in flake.nix and fill in WORK-USERNAME below
{
  imports = [
    ../../modules/darwin/default.nix
    ../../modules/darwin/homebrew.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin"; # change to x86_64-darwin if Intel

  users.users.WORK-USERNAME = {
    name = "WORK-USERNAME";
    home = "/Users/WORK-USERNAME";
  };

  system.primaryUser = "WORK-USERNAME";
}
