{ pkgs, ... }:

# GUI apps — import on personal Mac only. Not for WSL or work-mac.
{
  # Note: signal is installed via Homebrew (see hosts/personal-mac/configuration.nix)
  home.packages = with pkgs; [
    spotify
    discord
  ];

  programs.firefox = {
    enable = true;

    profiles.default = {
      isDefault = true;

      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        bitwarden
      ];

      settings = {
        "extensions.autoDisableScopes" = 0;
        "sidebar.revamp"       = true;
        "sidebar.verticalTabs" = true;
      };
    };
  };
}
