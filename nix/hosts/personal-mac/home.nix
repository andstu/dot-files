{ ... }:

{
  imports = [
    ../../modules/home/cli.nix
    ../../modules/home/dotfiles.nix
    ../../modules/home/mac-gui.nix
    ../../modules/home/gui.nix
    ../../modules/home/personal.nix
    ../../modules/home/hermes.nix
    ../../modules/home/macos.nix
  ];

  home.username = "andstu";
  home.homeDirectory = "/Users/andstu";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
