{ pkgs, lib, ... }:

# macOS-only: Homebrew PATH, Finder aliases in ~/Applications so Spotlight and
# Launchpad can find GUI apps installed by Home Manager.
{
  # nix-darwin writes /etc/paths.d/homebrew but path_helper never runs in HM zsh.
  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/usr/local/bin"
    "/usr/local/sbin"
  ];

  home.activation.aliasHomeManagerApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    srcDir="$HOME/Applications/Home Manager Apps"
    dstDir="$HOME/Applications"
    if [ -d "$srcDir" ]; then
      for app in "$srcDir"/*.app; do
        [ -e "$app" ] || continue
        name=$(basename "$app")
        target="$dstDir/$name"
        rm -rf "$target" 2>/dev/null || true
        ${pkgs.mkalias}/bin/mkalias "$app" "$target"
      done
    fi
  '';
}
