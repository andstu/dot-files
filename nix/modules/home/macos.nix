{ pkgs, lib, ... }:

# macOS-only: create Finder aliases in ~/Applications so Spotlight and
# Launchpad can find GUI apps installed by Home Manager.
{
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
