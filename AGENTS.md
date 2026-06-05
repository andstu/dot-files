# AGENTS.md

Personal dot-files for macOS and WSL, managed with a **Nix flake** (`nix-darwin` + Home Manager). Config trees (`cursor/`, `nvim/`, etc.) live in the repo root and are deployed via Home Manager.

## Repository layout

```
dot-files/
├── AGENTS.md          # This file — read before making changes
├── bootstrap.sh       # One-time Mac setup (Homebrew + first darwin-rebuild)
├── README.md          # Install quick start
├── nix/               # Flake: darwinConfigurations + homeConfigurations
│   ├── flake.nix
│   ├── hosts/         # Per-machine entrypoints
│   └── modules/       # Shared darwin + home-manager modules
├── cursor/            # Stow → ~/.cursor
├── zellij/            # Stow → ~/.config/zellij, ~/.local/bin
├── zsh/               # HM only (zsh.nix) — not stowed
├── nvim/              # Stow → ~/.config/nvim
├── tmux/              # Stow → ~/.tmux.conf, ~/.local/bin
└── fonts/             # Stow → fontconfig (WSL/Linux)
```

**Stow** (via `dotfiles.nix` activation): `cursor`, `nvim`, `zellij`, `tmux`, `fonts`. **Home Manager:** packages, `programs.git`, `programs.zsh`, host identity modules.

## Deployment

### macOS (Nix — preferred on new machines)

1. Clone to `~/dot-files`.
2. Run once: `./bootstrap.sh` (uses `scutil --get LocalHostName`) or `./bootstrap.sh Andstus-Dev-Machine`  
   Installs Homebrew if missing, then `darwin-rebuild switch --flake ~/dot-files/nix#<flake-output-name>`.
   On a fresh Mac without nix-darwin, bootstrap uses `nix run nix-darwin#darwin-rebuild`.
3. Later updates:

```bash
darwin-rebuild switch --flake ~/dot-files/nix#$(scutil --get LocalHostName)
```

Flake output names must match `scutil --get LocalHostName` (see `nix/flake.nix` → `darwinConfigurations`).

### WSL (Home Manager only)

```bash
home-manager switch --flake ~/dot-files/nix#andstu
```

### Nix evaluation (dry run)

```bash
cd ~/dot-files/nix
nix flake check
darwin-rebuild build --flake .#Andstus-Dev-Machine   # example output name
```

## Nix architecture

| Layer | Path | Role |
|-------|------|------|
| Flake | `nix/flake.nix` | Inputs: nixpkgs-unstable, nix-darwin, home-manager, NUR |
| Host | `nix/hosts/<name>/` | `configuration.nix` (system) + `home.nix` (user) |
| Darwin modules | `nix/modules/darwin/` | Nix settings, Homebrew casks |
| Home modules | `nix/modules/home/` | Packages, programs, identity (`cli.nix`, `zsh.nix`); Stow activation (`dotfiles.nix`) |

**Hosts**

| Host dir | Flake `darwinConfigurations` key | User modules |
|----------|----------------------------------|--------------|
| `personal-mac` | `Andstus-Dev-Machine` | cli, mac-gui, gui, personal, macos |
| `work-mac` | `WORK-HOSTNAME` (TODO) | cli, mac-gui, work, macos — **no** `gui.nix` / `personal.nix` |
| `wsl` | `homeConfigurations.andstu` | cli, personal |

**Identity split (important)**

- `modules/home/personal.nix` — personal git email; **only** on personal Mac + WSL.
- `modules/home/work.nix` — work git email + work packages; **only** on `work-mac`.
- `modules/home/gui.nix` — Spotify, Discord, Firefox; **personal Mac only** (not work, not WSL).
- `modules/darwin/homebrew.nix` — shared casks; per-host extras in `hosts/*/configuration.nix`.

**Homebrew:** Casks are declarative via nix-darwin. Homebrew must exist before the first `darwin-rebuild` (bootstrap handles this). Do not enable aggressive `cleanup` in nix-darwin — newer Homebrew requires flags nix-darwin does not pass; run `brew bundle cleanup --force` manually when needed.

**Work Mac setup (required before first switch):**

1. On the work machine: `scutil --get LocalHostName` → flake `darwinConfigurations` key; `whoami` → `users.users` and `home.username`.
2. Edit [`nix/flake.nix`](nix/flake.nix): replace `WORK-HOSTNAME` key and `WORK-USERNAME` in the `mkDarwin` call.
3. Edit [`nix/hosts/work-mac/configuration.nix`](nix/hosts/work-mac/configuration.nix) and [`home.nix`](nix/hosts/work-mac/home.nix): replace `WORK-USERNAME`.
4. `./bootstrap.sh <LocalHostName>` on the work Mac.

Placeholders remain until you complete these steps.

## Editing conventions

- **Minimize scope** — small, focused diffs; match existing module style.
- **Nix:** Add shared tools to `modules/home/cli.nix`; GUI to `gui.nix` or `mac-gui.nix`; Mac-only casks to `homebrew.nix` or host `configuration.nix`.
- **Stow packages:** Paths mirror `$HOME` (e.g. `cursor/.cursor/skills/...`). New package → add name to `stowPackages` in `dotfiles.nix`.
- **Comments:** Only for non-obvious bootstrap or compatibility notes (see `homebrew.nix`).
- **Lock file:** After flake input changes, run `nix flake lock` in `nix/` and commit `flake.lock`.
- **Secrets:** Never commit API keys, tokens, or machine-specific binary symlinks listed in `.gitignore`.

## Cursor and parallel agents

Stowed under `cursor/.cursor/`:

| Path | Purpose |
|------|---------|
| `skills/spawn-agents/` | Fan out BacklogMD tasks to worktrees + zellij tabs |
| `skills/pr-review/` | PR review in isolated worktree (uses `gh`) |
| `hooks.json` + `hooks/zellij-notify.sh` | Notify zellij tab on agent stop |

Related (stowed elsewhere):

- `zellij/.local/bin/spawn-agents.sh` — worktree + tab + `cursor agent` launcher; **reads this `AGENTS.md`** when spawning.
- `zsh/.zellij-agents.zsh` — `agent-task`, `agent-done`, sessionizer bindings.

Spawn workflow expects: zellij session, clean git tree, `spawn-agents.sh` on `PATH`. Skills live in the repo; after editing them, run `darwin-rebuild switch` (or `home-manager switch` on WSL).

## Verification

| Change type | Check |
|-------------|--------|
| Nix modules | `nix flake check` in `nix/` |
| Darwin config | `darwin-rebuild build --flake .#<output>` (no switch required for CI-style check) |
| Dotfile paths | Confirm `~/.cursor/skills`, `~/.config/nvim`, etc. after switch |
| Shell scripts | `shellcheck bootstrap.sh` (if available) |

There is no automated test suite for editor/tmux/zellij configs — validate manually after switch.

## Boundaries

- **Never** commit unless the user explicitly asks.
- **Never** put work-only identity (`work.nix`) on personal hosts or vice versa.
- **Never** add `gui.nix` to `work-mac` without an explicit request.
- **Do not** force-push `master` / `main` or rewrite published history without explicit approval.
- **Do not** enable Homebrew `cleanup = "zap"` in nix-darwin without verifying current nix-darwin/Homebrew behavior.
- **Do not** commit `.backlogmd/` (local agent task state) or generated zellij plugin `.wasm` binaries.
- Prefer **Home Manager** for packages and program config; **Stow** (via HM activation) for config trees listed in `dotfiles.nix`.

## Branch context

Active development may be on the `nix` branch (flake + bootstrap). `master` may still reflect Stow-only layout until merged.
