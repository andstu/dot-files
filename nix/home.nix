{ pkgs, lib, ... }:

{
  home.username = "andstu";
  home.homeDirectory = "/Users/andstu";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # Add user packages here
  ];

  programs.firefox = {
    enable = true;
    profiles.default = {
      isDefault = true;

      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin                  # ad + tracker blocking
        bitwarden                      # password manager
        duckduckgo-privacy-essentials  # DDG search + tracker protection
      ];

      settings = {
        # Auto-enable nix-installed extensions (required for declarative management)
        "extensions.autoDisableScopes" = 0;

        # --- Vertical tabs ---
        "sidebar.revamp"       = true;
        "sidebar.verticalTabs" = true;

        # --- Telemetry & data collection ---
        "toolkit.telemetry.unified"                                  = false;
        "toolkit.telemetry.enabled"                                  = false;
        "toolkit.telemetry.server"                                   = "";
        "datareporting.healthreport.uploadEnabled"                   = false;
        "datareporting.policy.dataSubmissionEnabled"                 = false;
        "browser.ping-centre.telemetry"                              = false;
        "browser.newtabpage.activity-stream.feeds.telemetry"         = false;
        "browser.newtabpage.activity-stream.telemetry"               = false;
        "app.shield.optoutstudies.enabled"                           = false;
        "app.normandy.enabled"                                       = false;

        # --- Pocket ---
        "extensions.pocket.enabled"                                  = false;

        # --- HTTPS-only mode ---
        "dom.security.https_only_mode"                               = true;
        "dom.security.https_only_mode_ever_enabled"                  = true;

        # --- DNS over HTTPS (Quad9 — no-log, malware-blocking) ---
        "network.trr.mode"                                           = 2;
        "network.trr.uri"                                            = "https://dns.quad9.net/dns-query";

        # --- Enhanced Tracking Protection ---
        "privacy.trackingprotection.enabled"                         = true;
        "privacy.trackingprotection.socialtracking.enabled"          = true;
        "privacy.trackingprotection.fingerprinting.enabled"          = true;
        "privacy.trackingprotection.cryptomining.enabled"            = true;

        # --- Total Cookie Protection (isolates cookies per site) ---
        "network.cookie.cookieBehavior"                              = 5;

        # --- Cross-origin referrer policy ---
        "network.http.referer.XOriginPolicy"                         = 2;
        "network.http.referer.XOriginTrimmingPolicy"                 = 2;

        # --- Geolocation ---
        "geo.enabled"                                                = false;

        # --- WebRTC — prevent IP leaks, keep video calls working ---
        "media.peerconnection.ice.default_address_only"              = true;
      };
    };
  };

  # macOS: create proper Finder aliases in ~/Applications so Spotlight and
  # Launchpad can find GUI apps installed by Home Manager.
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

  # Dotfiles managed by stow live in ~/dot-files — add program configs here
  # as you migrate them, e.g.:
  #
  #   programs.git = { ... };
  #   programs.zsh = { ... };
  #   programs.neovim = { ... };

  programs.home-manager.enable = true;
}
