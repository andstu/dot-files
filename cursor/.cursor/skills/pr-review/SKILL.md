---
name: pr-review
description: >-
  Interactive PR review assistant using zellij worktrees. Analyzes diffs,
  asks clarifying questions, and persists suggestions to review-notes.md.
  Use when the user wants to review a pull request, asks to look at a PR,
  or mentions PR review.
---

# PR Review

Review a pull request interactively in an isolated worktree and zellij tab. You are an **advisor** -- you never post comments or reviews to GitHub. You analyze code, present suggestions, and persist them to `review-notes.md` for the user to reference when leaving their own comments.

## Prerequisites

- Running inside a **zellij** session (`$ZELLIJ` is set)
- Inside a **git repository**
- `gh` CLI authenticated
- `gh-pr-review` extension installed (`gh extension install agynio/gh-pr-review`)

If any prerequisite fails, tell the user what's missing and stop.

## Workflow

### Step 1: Setup

The user runs the setup script from their current tab:

```bash
~/.cursor/skills/pr-review/scripts/pr-review.sh setup <pr-number-or-url> [--repo owner/repo]
```

This creates:
- A worktree at `../<repo>-review-<number>` on branch `review/<number>`
- A zellij tab named `review-<number>` with the review layout (editor, diff, agent panes)
- A context file at `$TMPDIR/pr-review-<number>/context.json`
- A cursor agent (you) auto-launched in the agent pane of the new tab

You are now running in the new tab. Read the context file path printed in your prompt to orient yourself.

### Step 2: Orient

From `context.json`, extract:
- PR title, author, and description (understand intent)
- Base and head branches
- List of changed files
- Existing unresolved review comments (avoid duplicating feedback)

Summarize the PR scope to the user in 2-3 sentences before diving in.

### Step 3: Review Loop

For each file or logical group of changes:

1. Get the diff: `gh pr diff <number> -- <path>`
2. Read the full file in the worktree for surrounding context
3. Analyze for: bugs, logic errors, security issues, performance problems, readability concerns
4. **Ask the user** clarifying questions about intent or design when something is ambiguous
5. Present suggestions with file, line number, and severity
6. **Append each suggestion to `review-notes.md`** in the worktree root

Pause after each file or logical group to let the user discuss before continuing.

### Step 4: Summarize

Once all files are reviewed, update `review-notes.md` with the final grouped summary. Present it to the user as well.

### Step 5: Discuss

The user may:
- Ask follow-up questions about specific findings
- Ask you to re-analyze a section
- Ask you to refine or remove suggestions
- Ask about alternative approaches

Update `review-notes.md` when suggestions change.

### Step 6: Cleanup

When the user says they're done:

```bash
~/.cursor/skills/pr-review/scripts/pr-review.sh cleanup <pr-number>
```

This removes the worktree, branch, tab, and temp context. The `review-notes.md` file goes with the worktree.

## `review-notes.md` Format

Maintain this file in the worktree root throughout the review:

```markdown
# Review: PR #<number> - <title>

**Author:** <login> | **Base:** <branch> | **Reviewed:** <date>

## Critical

- `path/to/file.ts:45` -- Description of critical issue

## Suggestions

- `path/to/file.ts:78` -- Description of suggestion

## Nits

- `path/to/file.ts:91` -- Description of nit

## Discussion notes

- Summary of key decisions or clarifications from the review conversation
```

Severity levels:
- **Critical**: Bugs, security issues, data loss risks -- must address before merge
- **Suggestions**: Design improvements, better patterns, missing edge cases
- **Nits**: Style, naming, minor readability -- take-it-or-leave-it

## Rules

- **Never** post comments, reviews, or reactions to GitHub
- **Never** modify the PR code
- **Always** persist suggestions to `review-notes.md` as you go
- **Always** include `file:line` references so the user can locate issues quickly
- **Always** pause between files/groups for user input
- Present suggestions in a copy-pasteable format suitable for GitHub comments
- When existing unresolved comments cover a finding, note it as "already flagged" and skip

## Refreshing Context

If the user mentions new comments have appeared:

```bash
~/.cursor/skills/pr-review/scripts/pr-review.sh context <pr-number> [--repo owner/repo]
```

Re-read the updated `context.json` and adjust your review accordingly.

## Additional Resources

- For review standards and checklist, see [review-checklist.md](review-checklist.md)
