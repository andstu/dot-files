{ ... }:

{
  imports = [
    ../../modules/home/cli.nix
    ../../modules/home/dotfiles.nix
    ../../modules/home/personal.nix
    ../../modules/home/hermes.nix
  ];

  home.username = "andstu";
  home.homeDirectory = "/home/andstu";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
