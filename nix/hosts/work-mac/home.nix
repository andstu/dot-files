{ ... }:

# TODO: replace WORK-USERNAME below once known
{
  imports = [
    ../../modules/home/cli.nix
    ../../modules/home/work.nix
    ../../modules/home/macos.nix
  ];

  home.username = "WORK-USERNAME";
  home.homeDirectory = "/Users/WORK-USERNAME";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
