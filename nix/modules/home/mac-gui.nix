{ pkgs, ... }:

# GUI apps for all Macs (personal + work). Not for WSL.
{
  home.packages = with pkgs; [
    ghostty
    obsidian
  ];
}
