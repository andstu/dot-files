#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: spawn-agents.sh <command> [args]

Commands:
  spawn <task-file> [agent-cmd]   Spawn an agent for a BacklogMD task file
  status                          Show status of all agent worktrees/tabs
  cleanup <branch>                Rebase branch, remove worktree/tab, delete branch
  cleanup-all                     Cleanup all agent/* branches

Environment:
  ZELLIJ          Must be set (running inside zellij)
  SPAWN_AGENT_CMD Default agent command (default: "cursor agent")
EOF
  exit 1
}

die() { echo "error: $*" >&2; exit 1; }

require_zellij() {
  [[ -n "${ZELLIJ:-}" ]] || die "not running inside a zellij session"
}

require_git() {
  git rev-parse --show-toplevel &>/dev/null || die "not inside a git repository"
}

repo_root() { git rev-parse --show-toplevel; }
repo_name() { basename "$(repo_root)"; }

slug_from_task_file() {
  local filename
  filename="$(basename "$1" .md)"
  # strip leading task ID (e.g. 001-fix-bug -> fix-bug)
  echo "$filename" | sed 's/^[0-9]*-//'
}

build_prompt() {
  local task_file="$1"
  local index_file
  index_file="$(dirname "$task_file")/index.md"

  local task_desc=""
  local context=""

  # extract task description (between <!-- DESCRIPTION --> and <!-- ACCEPTANCE -->)
  if [[ -f "$task_file" ]]; then
    task_desc=$(sed -n '/<!-- DESCRIPTION -->/,/<!-- ACCEPTANCE -->/{ /<!-- DESCRIPTION -->/d; /<!-- ACCEPTANCE -->/d; p; }' "$task_file")
  fi

  # extract context from index.md (after <!-- CONTEXT -->)
  if [[ -f "$index_file" ]]; then
    context=$(sed -n '/<!-- CONTEXT -->/,$ { /<!-- CONTEXT -->/d; p; }' "$index_file")
  fi

  local prompt="Task: ${task_desc}"

  if [[ -n "$context" ]]; then
    prompt="${prompt}

Context: ${context}"
  fi

  # reference AGENTS.md or CLAUDE.md if they exist in the repo
  local root
  root="$(repo_root)"
  for f in AGENTS.md CLAUDE.md; do
    if [[ -f "${root}/${f}" ]]; then
      prompt="${prompt}

Read ${f} for project conventions before starting."
      break
    fi
  done

  echo "$prompt"
}

cmd_spawn() {
  local task_file="${1:?task file path required}"
  local agent_cmd="${2:-${SPAWN_AGENT_CMD:-cursor}}"

  require_zellij
  require_git

  [[ -f "$task_file" ]] || die "task file not found: $task_file"

  local slug branch worktree_dir root name

  slug="$(slug_from_task_file "$task_file")"
  branch="agent/${slug}"
  root="$(repo_root)"
  name="$(repo_name)"
  worktree_dir="$(dirname "$root")/${name}-${branch//\//-}"

  if [[ -d "$worktree_dir" ]]; then
    echo "warn: worktree already exists at $worktree_dir, skipping" >&2
    return 1
  fi

  git worktree add "$worktree_dir" -b "$branch"

  local prompt
  prompt="$(build_prompt "$task_file")"

  # Write prompt to file and create a wrapper script that launches the agent
  local spawn_dir
  spawn_dir="$(mktemp -d "${TMPDIR:-/tmp}/spawn-agent-XXXXXX")"

  printf '%s' "$prompt" > "$spawn_dir/prompt"

  cat > "$spawn_dir/run.sh" <<'WRAPPER'
#!/usr/bin/env bash
exec AGENT_CMD agent "$(cat PROMPT_FILE)"
WRAPPER
  sed -i '' "s|AGENT_CMD|$agent_cmd|;s|PROMPT_FILE|$spawn_dir/prompt|" "$spawn_dir/run.sh"
  chmod +x "$spawn_dir/run.sh"

  # Generate a layout that runs the wrapper directly in the agent pane
  cat > "$spawn_dir/layout.kdl" <<LAYOUT
layout {
    pane size=1 borderless=true {
        plugin location="zellij:tab-bar"
    }
    pane split_direction="vertical" {
        pane stacked=true size="60%" {
            pane name="editor" expanded=true {
                command "nvim"
                args "."
            }
            pane name="terminal"
        }
        pane name="agent" size="40%" {
            command "$spawn_dir/run.sh"
        }
    }
    pane size=2 borderless=true {
        plugin location="zellij:status-bar"
    }
}
LAYOUT

  zellij action new-tab --name "$slug" --layout "$spawn_dir/layout.kdl" --cwd "$worktree_dir"

  echo "spawned: $slug (branch: $branch, worktree: $worktree_dir)"
}

cmd_status() {
  require_git
  echo "=== Agent worktrees ==="
  git worktree list | grep -E 'agent/' || echo "(none)"
  echo ""
  echo "=== Zellij tabs ==="
  zellij action query-tab-names 2>/dev/null || echo "(could not query tabs)"
}

close_agent_tab() {
  local slug="$1"
  [[ -n "$slug" ]] || return 0
  [[ -n "${ZELLIJ:-}" ]] || return 0

  local tab_id
  tab_id=$(zellij action list-tabs --json 2>/dev/null | \
    python3 -c "
import sys, json
tabs = json.load(sys.stdin)
for t in tabs:
    if t.get('name','') == sys.argv[1]:
        print(t['tab_id'])
        break
" "$slug" 2>/dev/null)

  if [[ -n "$tab_id" ]]; then
    zellij action close-tab --tab-id "$tab_id"
  fi
}

cmd_cleanup() {
  local branch="${1:?branch name required}"
  require_git

  local root
  root="$(repo_root)"

  local slug="${branch#agent/}"

  # Find the worktree path from git
  local worktree_path
  worktree_path=$(git worktree list --porcelain | awk -v b="$branch" '
    /^worktree / { wt = substr($0, 10) }
    /^branch / { if (substr($0, 8) == "refs/heads/" b) print wt }
  ')

  cd "$root"
  git rebase "$branch"

  if [[ -n "$worktree_path" ]]; then
    git worktree remove "$worktree_path"
  fi
  git branch -d "$branch"
  close_agent_tab "$slug"
  echo "cleaned up: $branch"
}

cmd_cleanup_all() {
  require_git

  local root
  root="$(repo_root)"
  cd "$root"

  local branches
  mapfile -t branches < <(git branch --list 'agent/*' --format='%(refname:short)')

  if [[ ${#branches[@]} -eq 0 ]]; then
    echo "no agent/* branches found"
    return 0
  fi

  echo "cleaning up ${#branches[@]} agent branches..."
  for branch in "${branches[@]}"; do
    echo "--- $branch ---"
    cmd_cleanup "$branch"
  done
}

[[ $# -gt 0 ]] || usage

case "$1" in
  spawn)       shift; cmd_spawn "$@" ;;
  status)      shift; cmd_status "$@" ;;
  cleanup)     shift; cmd_cleanup "$@" ;;
  cleanup-all) shift; cmd_cleanup_all "$@" ;;
  *)           usage ;;
esac
