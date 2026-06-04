{ ... }:

# Homebrew casks for all Macs — apps not packaged for Darwin in nixpkgs.
# Requires Homebrew to be installed: https://brew.sh
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };
    casks = [
      "ghostty"
    ];
  };
}
