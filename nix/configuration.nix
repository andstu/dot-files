{ pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Keep build outputs to avoid re-downloading on every gc
    keep-outputs = true;
    keep-derivations = true;
  };

  # Packages available system-wide (prefer home.packages for user tools)
  environment.systemPackages = [ ];

  programs.zsh.enable = true;

  system.primaryUser = "andstu";

  # Do not change — tracks activation script compatibility
  system.stateVersion = 5;
}
