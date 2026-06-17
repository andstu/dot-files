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

    # GitHub
    gh

    # Kubernetes
    kubectl
    talosctl

    # Hermes Agent CLI (shipyards gateway client)
    hermes-agent

    # VPN
    wireguard-tools

    # System
    htop

    # Editor / multiplexer
    neovim
    zellij

    # Cursor editor (provides the `cursor` CLI)
    code-cursor
  ];

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

}
