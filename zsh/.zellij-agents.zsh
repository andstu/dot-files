# zellij multi-agent helpers (only loaded when zellij is installed)
if (( $+commands[zellij] )); then
  # Ctrl-f: fuzzy session switcher (works inside and outside zellij)
  _zellij_sessionizer_widget() {
    zellij-sessionizer </dev/tty
    local ret=$?
    zle reset-prompt
    return $ret
  }
  zle -N _zellij_sessionizer_widget
  bindkey '^f' _zellij_sessionizer_widget

  # Close a zellij tab by name (slug). Matches tab names containing the slug.
  _close_agent_tab() {
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

  agent-task() {
    local repo_root=$(git rev-parse --show-toplevel)
    local repo_name=$(basename "$repo_root")
    local branch="$1"
    local agent="${2:-cursor agent}"

    if [[ -z "$branch" ]]; then
      echo "usage: agent-task <branch-name> [agent-command]"
      return 1
    fi

    git worktree add "../${repo_name}-${branch}" -b "$branch"

    local worktree_path
    worktree_path=$(cd "../${repo_name}-${branch}" && pwd)

    zellij action new-tab --name "$branch" --cwd "$worktree_path"
    sleep 0.3
    zellij action write-chars "$agent"
    zellij action write 13
  }

  agent-done() {
    local branch="$1"
    local repo_root=$(git rev-parse --show-toplevel)

    if [[ -z "$branch" ]]; then
      echo "usage: agent-done <branch-name>"
      return 1
    fi

    # Derive the tab slug (strip agent/ prefix, same as spawn-agents.sh)
    local slug="${branch#agent/}"

    # Find the worktree path from git
    local worktree_path
    worktree_path=$(git worktree list --porcelain | awk -v b="$branch" '
      /^worktree / { wt = substr($0, 10) }
      /^branch / { if (substr($0, 8) == "refs/heads/" b) print wt }
    ')

    cd "$repo_root"
    git rebase "$branch"

    if [[ -n "$worktree_path" ]]; then
      git worktree remove "$worktree_path"
    fi
    git branch -d "$branch"

    _close_agent_tab "$slug"
    echo "done: $branch"
  }

  agent-done-all() {
    local repo_root=$(git rev-parse --show-toplevel)
    cd "$repo_root"

    local branches
    branches=($(git branch --list 'agent/*' --format='%(refname:short)'))

    if [[ ${#branches[@]} -eq 0 ]]; then
      echo "no agent/* branches found"
      return 0
    fi

    echo "cleaning up ${#branches[@]} agent branches..."
    for branch in "${branches[@]}"; do
      echo "--- $branch ---"
      agent-done "$branch"
    done
  }

  agent-send() {
    local pane_id="$1"
    shift
    local text="$*"

    if [[ -z "$pane_id" || -z "$text" ]]; then
      echo "usage: agent-send <pane-id> <message>"
      return 1
    fi

    zellij action write-chars --pane-id "$pane_id" "$text"
    zellij action write 13 --pane-id "$pane_id"
  }

  pr-review() {
    ~/.cursor/skills/pr-review/scripts/pr-review.sh "$@"
  }
fi
