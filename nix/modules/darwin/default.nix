{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    keep-outputs = true;
    keep-derivations = true;
  };

  environment.systemPackages = [ ];
  programs.zsh.enable = true;

  # Do not change — tracks activation script compatibility
  system.stateVersion = 5;
}
