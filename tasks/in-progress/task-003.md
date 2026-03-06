# task-003: Git workflow scripts (push_all + pre-commit hook)

## Objective
Create a dual-repo push script and a pre-commit hook that prevents direct src/ modifications.

## Technical Requirements

### 1. scripts/push_all.sh
- Read remote names and branch from config.json using `source scripts/lib/config.sh` and `cfg` function
- `cfg "git.remotes" ""` returns space-separated remote names (e.g. "github gitee")
- `cfg "git.branch" "master"` returns the branch name
- Push to each remote in sequence, showing status for each
- Exit with error if any push fails
- Support optional `--force` flag (with user confirmation prompt before force-pushing)

### 2. .githooks/pre-commit
- Check if any staged files are under `src/` directory
- If yes, check that a corresponding task file exists in `tasks/in-progress/` or `tasks/done/`
- If no task file found, print a warning but DO NOT block the commit (some commits are made by Claude after review)
- Make it a standard git hook (#!/bin/bash, executable)
- Print clear message explaining the warning

### 3. scripts/setup_hooks.sh
- Run `git config core.hooksPath .githooks` to activate the hooks directory
- Print confirmation message

## File Scope (only these files may be modified)
- scripts/push_all.sh
- .githooks/pre-commit
- scripts/setup_hooks.sh
DO NOT modify: package.json, orchestrator.sh, config.json, any existing scripts

## Acceptance Criteria
- [ ] `bash scripts/push_all.sh` reads remotes from config.json and pushes to all
- [ ] `bash scripts/push_all.sh --force` asks for confirmation before force-pushing
- [ ] `.githooks/pre-commit` warns when src/ files are staged without a task
- [ ] `bash scripts/setup_hooks.sh` activates the hooks directory
- [ ] All scripts pass `bash -n` syntax check

## Assignee
backend (Codex)

## On Completion
Write result to tasks/done/task-003-result.md
