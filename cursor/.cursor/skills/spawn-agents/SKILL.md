---
name: spawn-agents
description: >-
  Spawn multiple Cursor agents in parallel using zellij tabs and git worktrees.
  Use when the user has a list of todos or tasks to fan out to separate agents,
  mentions spawning agents, or wants to parallelize work across worktrees.
---

# Spawn Agents

Fan out a list of todos into parallel Cursor agents, each on its own git worktree and zellij tab, using BacklogMD for task tracking.

## Prerequisites

Verify before proceeding:
1. Running inside a **zellij** session (`$ZELLIJ` is set)
2. Inside a **git repository**
3. `spawn-agents.sh` is on `$PATH` (should be at `~/.local/bin/spawn-agents.sh`)
4. Working tree is clean (`git status --porcelain` is empty)

If any prerequisite fails, tell the user what's missing and stop.

## Workflow

### Step 1: Collect todos

Accept todos from the user in one of these forms:
- A **numbered list in chat** (e.g. "1. Add auth 2. Write tests 3. Fix bug")
- A **markdown file path** containing `- [ ]` checkboxes
- An **existing `.backlogmd/`** directory in the repo

Parse each todo into a slug and description:
- Slug: lowercase kebab-case derived from the todo text, max 40 chars (e.g. `add-input-validation`)
- Description: the full todo text

### Step 2: Scaffold BacklogMD

If `.backlogmd/` does not already exist, create it following the BacklogMD spec.

Create one work item for this batch:

```
.backlogmd/
└── work/
    └── 001-<batch-slug>/
        ├── index.md
        ├── 001-<task-slug>.md
        ├── 002-<task-slug>.md
        └── ...
```

**index.md format:**

```markdown
<!-- METADATA -->

\`\`\`yaml
work: <batch title from user or inferred>
status: open
assignee: ""
\`\`\`

<!-- DESCRIPTION -->

Batch of tasks spawned for parallel agent work.

<!-- CONTEXT -->

<Include a brief summary of the project context. Reference CLAUDE.md or AGENTS.md if present in the repo root.>
```

**Task file format** (`NNN-<slug>.md`):

```markdown
<!-- METADATA -->

\`\`\`yaml
task: <full todo description>
status: open
priority: <sequence number>
dep: []
assignee: ""
requiresHumanReview: false
expiresAt: null
\`\`\`

<!-- DESCRIPTION -->

## Description

<full todo description>

<!-- ACCEPTANCE -->

## Acceptance criteria

- [ ] Implementation complete
- [ ] Tests pass (if applicable)
```

Add `.backlogmd/` to the repo's `.gitignore` if it isn't already listed. Do **not** commit the backlog directory—it stays local to the root worktree.

### Step 3: Spawn agents (max 5 at a time)

For each task with `status: open`, up to a **maximum of 5 concurrent agents**:

Run the spawn script:

```bash
spawn-agents.sh spawn <task-file-path> [base-command]
```

- `base-command` defaults to `cursor`. The script appends `agent` and passes the prompt as a CLI argument.
- Example: `spawn-agents.sh spawn .backlogmd/work/001-batch/001-fix-bug.md`

The script will:
1. Derive the branch name `agent/<task-slug>` from the task filename
2. Create a git worktree at `../<repo-name>-agent-<task-slug>`
3. Open a zellij tab named after the task slug
4. Build a prompt from: the task description, project context from `index.md`, and a reference to `CLAUDE.md`/`AGENTS.md`
5. Start `cursor agent "<prompt>"` in the new tab, passing the prompt as a CLI argument so it goes directly to the agent chat

After spawning a batch, update each spawned task's status to `in-progress` and set `assignee: "cursor-agent"` in the task file. Commit these status changes.

### Step 4: Wait and spawn next batch

Tell the user:

> **Spawned N agents.** Switch between tabs to monitor progress.
> When agents finish (✅ in tab bar), come back here and say **"next"** to:
> - Mark completed tasks as done
> - Spawn the next batch of up to 5

When the user says "next" (or similar):

1. For each agent tab that has completed:
   - Check if the worktree branch has new commits
   - Update the task file in the root repo's `.backlogmd/`: `status: done`, clear `assignee`, check acceptance criteria
2. Run `spawn-agents.sh spawn` for the next batch of `open` tasks (up to 5)
3. Report progress: how many done, how many remaining

### Step 5: Cleanup

When the user asks to clean up (or all tasks are done), run cleanup from this chat:

**Single branch:**

```bash
spawn-agents.sh cleanup agent/<task-slug>
```

**All agent branches at once:**

```bash
spawn-agents.sh cleanup-all
```

These commands will for each branch:
1. Rebase the agent's commits onto the current branch (linear history)
2. Remove the git worktree
3. Close the zellij tab
4. Delete the branch

The shell aliases `agent-done <branch>` and `agent-done-all` do the same thing.

## Error handling

- If a worktree already exists for a branch, skip it and warn the user
- If zellij tab creation fails, report the error and continue with remaining tasks
- If an agent fails (non-zero exit), mark the task `status: block` and create a feedback file

## Additional resources

- For the full BacklogMD spec, see [SPEC.md](https://github.com/backlogmd/backlogmd)
- For zellij agent helpers, source `~/.zellij-agents.zsh`
