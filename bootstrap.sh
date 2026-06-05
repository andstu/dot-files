#!/usr/bin/env bash
# bootstrap.sh — run once on a new Mac to set up nix-darwin + Homebrew.
#
# Usage:
#   ./bootstrap.sh                  # auto-detects hostname
#   ./bootstrap.sh personal-mac     # or pass a flake target explicitly
#
# After the first run, use darwin-rebuild switch for all future updates.

set -euo pipefail

FLAKE="$HOME/dot-files/nix"
HOSTNAME="${1:-$(scutil --get LocalHostName)}"

# ── 1. Homebrew ────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for the rest of this script (Apple Silicon default location)
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
else
  echo "==> Homebrew already installed, skipping."
fi

# ── 2. nix-darwin ──────────────────────────────────────────────────────────────
echo "==> Running darwin-rebuild switch for host: $HOSTNAME"
sudo darwin-rebuild switch --flake "$FLAKE#$HOSTNAME"

echo ""
echo "✓ Bootstrap complete. Use 'darwin-rebuild switch --flake ~/dot-files/nix#$HOSTNAME' for future updates."
