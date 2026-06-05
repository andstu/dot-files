{
  config,
  lib,
  pkgs,
  dotfilesRoot,
  ...
}:

let
  # Stow packages: each top-level dir mirrors paths under $HOME (e.g. nvim/.config/nvim).
  # Not stowed: git/ (HM programs.git), zsh/ (HM programs.zsh + home.file helpers in zsh.nix).
  stowPackages = [
    "cursor"
    "nvim"
    "zellij"
    "tmux"
    "fonts"
  ];
  stowPackageArgs = lib.concatStringsSep " " stowPackages;
  # Paths previously deployed by HM home.file; remove non-symlinks so stow can link.
  migratePaths = [
    ".cursor"
    ".config/zellij"
    ".config/nvim"
    ".config/fontconfig"
    ".tmux.conf"
  ];
in
{
  imports = [ ./zsh.nix ];

  home.packages = [ pkgs.stow ];

  home.activation.stowDotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    repo=${lib.escapeShellArg (toString dotfilesRoot)}
    if [ -d "$HOME/dot-files" ]; then
      repo="$HOME/dot-files"
    fi

    ${pkgs.stow}/bin/stow -D -t "$HOME" -d "$repo" ${stowPackageArgs} 2>/dev/null || true

    for rel in ${lib.concatStringsSep " " migratePaths}; do
      target="$HOME/$rel"
      if [ -e "$target" ] && [ ! -L "$target" ]; then
        rm -rf "$target"
      fi
    done

    stow_flags=-R
    if [ "$repo" = "$HOME/dot-files" ]; then
      stow_flags="--adopt -R"
    fi

    ${pkgs.stow}/bin/stow $stow_flags -t "$HOME" -d "$repo" ${stowPackageArgs} || {
      echo "stow failed; from ~/dot-files run: stow -D ${stowPackageArgs}"
      exit 1
    }
  '';
}
