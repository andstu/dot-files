{ ... }:

{
  imports = [
    ../../modules/darwin/default.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/mount-plex.nix
  ];


  # Personal-only casks (extends the shared list in homebrew.nix)
  # Photoshop and Lightroom have no Homebrew casks; install them via Creative Cloud after switch.
  homebrew.casks = [
    "signal"
    "adobe-creative-cloud"
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.andstu = {
    name = "andstu";
    home = "/Users/andstu";
  };

  system.primaryUser = "andstu";
}
