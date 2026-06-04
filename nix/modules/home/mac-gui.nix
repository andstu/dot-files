{ pkgs, ... }:

# GUI apps for all Macs (personal + work). Not for WSL.
# Note: ghostty is installed via Homebrew (see modules/darwin/homebrew.nix)
{
  home.packages = with pkgs; [
    obsidian
  ];
}
