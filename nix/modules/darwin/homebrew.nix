{ ... }:

# Declarative Homebrew cask management via nix-darwin's built-in homebrew module.
#
# BOOTSTRAP: Homebrew must be installed once before darwin-rebuild can manage
# casks. On a fresh machine, run this first:
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#
# After that, darwin-rebuild will keep casks in sync on every switch.
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # "zap" / "uninstall" now require --force in newer Homebrew versions,
      # which nix-darwin doesn't pass. Leave cleanup off here and run
      # `brew bundle cleanup --force` manually when you want to remove old casks.
      cleanup = "none";
    };
    casks = [
      "ghostty"
    ];
  };
}
