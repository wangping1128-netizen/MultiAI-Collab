# AGENTS.md - Project Context for AI Agents

> This file is automatically injected into Codex/Gemini prompts by the assign scripts.

## Project: MultiAI-Collab

A multi-AI collaboration framework where Claude (PM) delegates coding tasks to Codex (backend) and Gemini (frontend).

## Tech Stack

- **Runtime**: Node.js >= 18 (currently v24)
- **Backend**: Express.js 5.x
- **Frontend**: React (JSX, no build step for now — CJS + manual createElement)
- **Testing**: Node.js built-in test runner (`node:test` + `node:assert`)
- **Shell Scripts**: Bash (Git Bash on Windows)
- **Config**: `config.json` read via `scripts/lib/config.sh` (`cfg` function)

## Project Structure

```
MultiAI-Collab/
├── config.json              # Centralized config (models, timeouts, etc.)
├── orchestrator.sh          # Main task dispatcher (parallel, PID tracking)
├── scripts/
│   ├── lib/config.sh        # Shared cfg() config reader
│   ├── assign_codex.sh      # Codex CLI dispatch
│   ├── assign_gemini.sh     # Gemini CLI dispatch
│   ├── review.sh            # Claude CLI auto-review
│   ├── new_task.sh          # Bash task creator
│   ├── status.sh            # Task pipeline dashboard
│   └── test_e2e.sh          # E2E smoke test (dry-run)
├── tasks/
│   ├── pending/             # New tasks (Claude writes here)
│   ├── in-progress/         # Being executed
│   └── done/                # Results + reviews
├── src/
│   ├── app.js               # Express entry point (port 3000)
│   ├── routes/health.js     # GET /health endpoint
│   ├── components/          # React components (CJS)
│   └── tests/               # node:test test files
└── AGENTS.md                # This file
```

## Coding Conventions

- **Module system**: CommonJS (`require` / `module.exports`). No ESM import/export.
- **Testing**: Always use `node:test` + `node:assert/strict`. No jest, mocha, or other frameworks.
- **Run tests**: `node --test src/tests/<file>.test.js`
- **No JSX transform**: React components use manual `createElement()` (see StatusCard.jsx for pattern)
- **File naming**: Components use PascalCase.jsx, routes use lowercase.js, tests use `<name>.test.js`

## Important Rules

1. Only modify files listed in your task's "File Scope" section
2. Always create the result file at the exact path specified in "On Completion"
3. Run tests before reporting completion
4. If tests fail due to sandbox restrictions, note the workaround (e.g. `--test-isolation=none`)
