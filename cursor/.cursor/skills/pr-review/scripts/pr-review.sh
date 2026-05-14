#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: pr-review.sh <command> [args]

Commands:
  setup <pr-number-or-url> [--repo owner/repo]   Checkout PR into worktree + zellij tab, fetch context
  context <pr-number> [--repo owner/repo]         Re-fetch PR context (refresh comments/metadata)
  cleanup <pr-number>                             Remove worktree, branch, and zellij tab

Environment:
  ZELLIJ    Must be set (running inside zellij)
  GH_REPO   Default repository (fallback for --repo)
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

require_gh_pr_review() {
  if ! gh extension list 2>/dev/null | grep -q 'pr-review'; then
    die "gh-pr-review extension not installed. Run: gh extension install agynio/gh-pr-review"
  fi
}

repo_root() { git rev-parse --show-toplevel; }
repo_name() { basename "$(repo_root)"; }

parse_pr_number() {
  local input="$1"
  if [[ "$input" =~ ^[0-9]+$ ]]; then
    echo "$input"
  elif [[ "$input" =~ /pull/([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    die "cannot parse PR number from: $input"
  fi
}

resolve_repo_flag() {
  local repo=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo) repo="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  if [[ -n "$repo" ]]; then
    echo "$repo"
  elif [[ -n "${GH_REPO:-}" ]]; then
    echo "$GH_REPO"
  else
    gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || die "cannot determine repository; use --repo owner/repo"
  fi
}

worktree_dir() {
  local pr_number="$1"
  local root name
  root="$(repo_root)"
  name="$(repo_name)"
  echo "$(dirname "$root")/${name}-review-${pr_number}"
}

context_dir() {
  local pr_number="$1"
  echo "${TMPDIR:-/tmp}/pr-review-${pr_number}"
}

close_review_tab() {
  local tab_name="$1"
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
" "$tab_name" 2>/dev/null) || true

  if [[ -n "$tab_id" ]]; then
    zellij action close-tab --tab-id "$tab_id"
  fi
}

fetch_context() {
  local pr_number="$1"
  local repo="$2"
  local ctx_dir

  ctx_dir="$(context_dir "$pr_number")"
  mkdir -p "$ctx_dir"

  local metadata
  metadata=$(gh pr view "$pr_number" -R "$repo" --json title,body,author,baseRefName,headRefName,files,url,additions,deletions,changedFiles)

  local comments=""
  if gh extension list 2>/dev/null | grep -q 'pr-review'; then
    comments=$(gh pr-review review view "$pr_number" -R "$repo" --unresolved --not_outdated 2>/dev/null || echo '{}')
  fi

  local changed_files
  changed_files=$(echo "$metadata" | python3 -c "
import sys, json
data = json.load(sys.stdin)
files = data.get('files', [])
for f in files:
    print(f.get('path', ''))
" 2>/dev/null || echo "")

  python3 -c "
import sys, json

metadata = json.loads(sys.argv[1])
comments = json.loads(sys.argv[2]) if sys.argv[2] else {}

context = {
    'pr_number': int(sys.argv[3]),
    'url': metadata.get('url', ''),
    'title': metadata.get('title', ''),
    'body': metadata.get('body', ''),
    'author': metadata.get('author', {}).get('login', ''),
    'base': metadata.get('baseRefName', ''),
    'head': metadata.get('headRefName', ''),
    'additions': metadata.get('additions', 0),
    'deletions': metadata.get('deletions', 0),
    'changed_files_count': metadata.get('changedFiles', 0),
    'files': [f.get('path', '') for f in metadata.get('files', [])],
    'existing_comments': comments,
}

with open(sys.argv[4], 'w') as f:
    json.dump(context, f, indent=2)
" "$metadata" "${comments:-{}}" "$pr_number" "$ctx_dir/context.json"

  echo "$ctx_dir/context.json"
}

cmd_setup() {
  local pr_input=""
  local args=()

  for arg in "$@"; do
    if [[ -z "$pr_input" && "$arg" != --* ]]; then
      pr_input="$arg"
    else
      args+=("$arg")
    fi
  done

  [[ -n "$pr_input" ]] || die "PR number or URL required"

  require_zellij
  require_git

  local pr_number repo wt_dir root branch tab_name

  pr_number="$(parse_pr_number "$pr_input")"
  repo="$(resolve_repo_flag "${args[@]+"${args[@]}"}")"
  root="$(repo_root)"
  wt_dir="$(worktree_dir "$pr_number")"
  branch="review/${pr_number}"
  tab_name="review-${pr_number}"

  if [[ -d "$wt_dir" ]]; then
    die "worktree already exists at $wt_dir (already reviewing this PR?)"
  fi

  echo "Setting up review for PR #${pr_number} (${repo})..."

  local head_branch
  head_branch=$(gh pr view "$pr_number" -R "$repo" --json headRefName -q .headRefName)

  git fetch origin "pull/${pr_number}/head:${branch}"
  git worktree add "$wt_dir" "$branch"

  echo "Fetching PR context..."
  local context_path
  context_path="$(fetch_context "$pr_number" "$repo")"

  local ctx_dir
  ctx_dir="$(context_dir "$pr_number")"

  local prompt
  prompt="Review PR #${pr_number} in ${repo}. Read the context file at ${context_path} to orient yourself, then follow the pr-review skill workflow. The worktree is already checked out."

  printf '%s' "$prompt" > "$ctx_dir/prompt"

  cat > "$ctx_dir/run-agent.sh" <<WRAPPER
#!/usr/bin/env bash
exec cursor agent "\$(cat '${ctx_dir}/prompt')"
WRAPPER
  chmod +x "$ctx_dir/run-agent.sh"

  local layout_template="${HOME}/.config/zellij/layouts/review-tab.kdl"
  local layout_file="${ctx_dir}/review-tab.kdl"
  sed -e "s/__PR_NUMBER__/${pr_number}/g" \
      -e "s|__REPO__|${repo}|g" \
      -e "s|__AGENT_SCRIPT__|${ctx_dir}/run-agent.sh|g" \
      "$layout_template" > "$layout_file"

  zellij action new-tab --name "$tab_name" --layout "$layout_file" --cwd "$wt_dir"

  echo ""
  echo "--- PR Review Ready ---"
  echo "  PR:        #${pr_number}"
  echo "  Repo:      ${repo}"
  echo "  Worktree:  ${wt_dir}"
  echo "  Tab:       ${tab_name}"
  echo "  Context:   ${context_path}"
  echo ""
  echo "Agent launched in the review tab. Switch to it to begin the interactive review."
}

cmd_context() {
  local pr_input=""
  local args=()

  for arg in "$@"; do
    if [[ -z "$pr_input" && "$arg" != --* ]]; then
      pr_input="$arg"
    else
      args+=("$arg")
    fi
  done

  [[ -n "$pr_input" ]] || die "PR number or URL required"

  require_git

  local pr_number repo

  pr_number="$(parse_pr_number "$pr_input")"
  repo="$(resolve_repo_flag "${args[@]+"${args[@]}"}")"

  echo "Refreshing context for PR #${pr_number}..."
  local context_path
  context_path="$(fetch_context "$pr_number" "$repo")"
  echo "Context updated: ${context_path}"
}

cmd_cleanup() {
  local pr_input="${1:?PR number required}"

  require_git

  local pr_number wt_dir branch tab_name root

  pr_number="$(parse_pr_number "$pr_input")"
  root="$(repo_root)"
  wt_dir="$(worktree_dir "$pr_number")"
  branch="review/${pr_number}"
  tab_name="review-${pr_number}"

  echo "Cleaning up review for PR #${pr_number}..."

  if [[ -d "$wt_dir" ]]; then
    cd "$root"
    git worktree remove "$wt_dir" --force
    echo "  Removed worktree: $wt_dir"
  else
    echo "  Worktree not found: $wt_dir (skipping)"
  fi

  if git show-ref --verify --quiet "refs/heads/${branch}" 2>/dev/null; then
    git branch -D "$branch"
    echo "  Deleted branch: $branch"
  else
    echo "  Branch not found: $branch (skipping)"
  fi

  close_review_tab "$tab_name"
  echo "  Closed tab: $tab_name"

  local ctx_dir
  ctx_dir="$(context_dir "$pr_number")"
  if [[ -d "$ctx_dir" ]]; then
    rm -rf "$ctx_dir"
    echo "  Removed context: $ctx_dir"
  fi

  echo "Done."
}

[[ $# -gt 0 ]] || usage

case "$1" in
  setup)   shift; cmd_setup "$@" ;;
  context) shift; cmd_context "$@" ;;
  cleanup) shift; cmd_cleanup "$@" ;;
  *)       usage ;;
esac
