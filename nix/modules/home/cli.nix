{ pkgs, ... }:

# Installed on every machine (Mac, work Mac, WSL). No GUI, no identity.
{
  home.packages = with pkgs; [
    # Search & navigation
    ripgrep
    fd
    fzf

    # File inspection
    bat
    jq

    # System
    htop
  ];

  programs.git = {
    enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
