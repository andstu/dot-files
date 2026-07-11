{
  config,
  lib,
  dotfilesRoot,
  ...
}:

let
  cfg = {
    server = "https://grafana.andstu.xyz";
    orgId = 1;
  };
  envExample = dotfilesRoot + "/gcx/.config/gcx/.env.example";
in
{
  home.file.".config/gcx/config.yaml".text = ''
    # Local gcx CLI — shipyards Grafana (kube-prometheus-stack).
    current-context: shipyards
    contexts:
      shipyards:
        grafana:
          server: ${cfg.server}
          org-id: ${toString cfg.orgId}
  '';

  home.activation.ensureGcxEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    envFile="$HOME/.config/gcx/.env"
    exampleFile=${lib.escapeShellArg envExample}
    mkdir -p "$HOME/.config/gcx"
    if [ ! -f "$envFile" ] && [ -f "$exampleFile" ]; then
      cp "$exampleFile" "$envFile"
      chmod 600 "$envFile"
      echo "Created ~/.config/gcx/.env from example — set GRAFANA_TOKEN from a Grafana service account"
    fi
  '';

  programs.zsh.initExtra = lib.mkAfter ''
    [ -f "$HOME/.config/gcx/.env" ] && set -a && source "$HOME/.config/gcx/.env" && set +a
  '';
}
