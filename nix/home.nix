{ pkgs, ... }:

{
  home.username = "andstu";
  home.homeDirectory = "/Users/andstu";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # Add user packages here, e.g.:
    # ripgrep
    # fd
    # jq
  ];

  # Dotfiles managed by stow live in ~/dot-files — add program configs here
  # as you migrate them, e.g.:
  #
  #   programs.git = { ... };
  #   programs.zsh = { ... };
  #   programs.neovim = { ... };

  programs.home-manager.enable = true;
}
