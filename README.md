# dot-files

Personal configs for macOS and WSL, managed with **Nix**, **nix-darwin**, and **Home Manager**.

See [AGENTS.md](AGENTS.md) for repository layout, editing conventions, and agent workflows.

## Quick start

### Prerequisites

1. Clone this repo to `~/dot-files`.
2. On the `nix` branch (or after it is merged to your default branch).

### Personal Mac

```bash
# One-time on a new Mac (installs Homebrew + nix-darwin + Home Manager)
./bootstrap.sh

# Or explicitly pass the flake output name (from `scutil --get LocalHostName`)
./bootstrap.sh Andstus-Dev-Machine

# Later updates
darwin-rebuild switch --flake ~/dot-files/nix#$(scutil --get LocalHostName)
```

Flake output names live in [`nix/flake.nix`](nix/flake.nix) under `darwinConfigurations`. They must match `scutil --get LocalHostName`, not the `nix/hosts/` directory name.

**Fresh Mac without nix-darwin yet:** `bootstrap.sh` runs `nix run nix-darwin#darwin-rebuild` automatically when `darwin-rebuild` is not on PATH.

### WSL / Linux

Install [Nix](https://nixos.org/download/) with flakes enabled, then [Home Manager](https://github.com/nix-community/home-manager), then:

```bash
home-manager switch --flake ~/dot-files/nix#andstu
```

Confirm architecture matches [`nix/flake.nix`](nix/flake.nix) (`x86_64-linux` by default).

### Work Mac (first-time setup)

Before bootstrapping, replace placeholders:

1. On the work machine: `scutil --get LocalHostName` and `whoami`.
2. In [`nix/flake.nix`](nix/flake.nix): rename the `WORK-HOSTNAME` key to the LocalHostName; set `user`.
3. In [`nix/hosts/work-mac/`](nix/hosts/work-mac/): replace `WORK-USERNAME` in `configuration.nix` and `home.nix`.
4. Run `./bootstrap.sh <LocalHostName>`.

Work hosts use work git identity only (no personal GUI or `gui.nix`).

## Validate without switching

```bash
cd ~/dot-files/nix
nix flake check
darwin-rebuild build --flake .#Andstus-Dev-Machine
```

## Config management

- **Packages, git, zsh:** Home Manager (`nix/modules/home/cli.nix`, `zsh.nix`, `personal.nix` / `work.nix`).
- **Config trees** (`cursor/`, `nvim/`, `zellij/`, `tmux/`, `fonts/`): GNU Stow, run automatically on every switch via [`nix/modules/home/dotfiles.nix`](nix/modules/home/dotfiles.nix).

Add a new config package: create a top-level directory in Stow layout (e.g. `foo/.config/foo/…`), add `"foo"` to `stowPackages` in `dotfiles.nix`, then `darwin-rebuild switch` or `home-manager switch`.

**Do not** add `git/` or `zsh/` to Stow — those are managed by Home Manager.

If activation fails due to existing files, unstow the conflicting package from `~/dot-files`: `stow -D <package>`.
