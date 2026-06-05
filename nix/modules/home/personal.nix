{ config, lib, pkgs, ... }:

# Personal identity — import on personal machines only (not work-mac).
let
  sshKeyPath = "${config.home.homeDirectory}/.ssh/github";
  sshKeyComment = config.programs.git.settings.user.email;
in
{
  home.activation.ensureGithubSshKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    key=${lib.escapeShellArg sshKeyPath}
    if [ ! -f "$key" ]; then
      mkdir -p "$(dirname "$key")"
      chmod 700 "$(dirname "$key")"
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$key" -C ${lib.escapeShellArg sshKeyComment} -N ""
    fi
  '';

  programs.git = {
    settings = {
      user = {
        name = "Andrew Teeter";
        email = "andstu.dev@gmail.com";
      };
      gpg.format = "ssh";
    };
    signing = {
      key = "${config.home.homeDirectory}/.ssh/github.pub";
      signByDefault = true;
    };
  };
}
