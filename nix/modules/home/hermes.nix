{
  config,
  lib,
  dotfilesRoot,
  ...
}:

let
  cfg = {
    dashboardUrl = "https://hermes.andstu.xyz";
    apiUrl = "https://hermes-api.andstu.xyz";
  };
  envExample = dotfilesRoot + "/hermes/.hermes/.env.example";
in
{
  home.file.".hermes/config.yaml".text = ''
    # Local Hermes CLI — thin client for the shipyards k8s gateway.
    gateway:
      proxy_url: ${cfg.apiUrl}
  '';

  home.activation.ensureHermesEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    envFile="$HOME/.hermes/.env"
    exampleFile=${lib.escapeShellArg envExample}
    mkdir -p "$HOME/.hermes"
    if [ ! -f "$envFile" ] && [ -f "$exampleFile" ]; then
      cp "$exampleFile" "$envFile"
      chmod 600 "$envFile"
      echo "Created ~/.hermes/.env from example — set GATEWAY_PROXY_KEY to match API_SERVER_KEY on shipyards"
    fi
  '';

  programs.zsh.initExtra = lib.mkAfter ''
    export HERMES_DESKTOP_REMOTE_URL="${cfg.dashboardUrl}"
    [ -f "$HOME/.hermes/.env" ] && set -a && source "$HOME/.hermes/.env" && set +a
  '';
}
