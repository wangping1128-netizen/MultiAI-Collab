# MultiAI-Collab

Multi-AI collaboration framework using file-based communication and Git-based acceptance.

## Architecture

| Role | Agent | Responsibility |
|------|-------|----------------|
| Architect / PM | Claude Code | Requirement analysis, task splitting, code review, git commit |
| Backend Engineer | Codex CLI | Backend coding, unit tests |
| Frontend Engineer | Gemini CLI | Frontend dev, security review |

## Communication Model

```
tasks/pending/     Claude writes task files here
tasks/in-progress/ orchestrator.sh moves tasks here during execution
tasks/done/        Codex/Gemini write result files here
```

No IPC middleware needed. All communication through Markdown files + Git.

## Quick Start

```bash
# 1. Start the orchestrator (Tab 1)
bash orchestrator.sh

# 2. Start Claude Code (Tab 2)
claude

# 3. Tell Claude your requirement. It will:
#    - Analyze and split into tasks
#    - Write task files to tasks/pending/
#    - Review results from tasks/done/
#    - git commit on acceptance
```

## Project Structure

```
MultiAI-Collab/
├── CLAUDE.md                  # Claude behavior rules (auto-loaded)
├── orchestrator.sh            # Main task dispatcher (poll loop)
├── scripts/
│   ├── assign_codex.sh        # Codex CLI invocation
│   └── assign_gemini.sh       # Gemini CLI invocation
├── tasks/
│   ├── pending/               # New tasks from Claude
│   ├── in-progress/           # Currently executing
│   └── done/                  # Completed results
├── src/                       # Business code
│   ├── routes/                # Backend routes
│   ├── components/            # Frontend components
│   └── tests/                 # Test files
└── README.md
```

## Degradation Rules

- Gemini fails 2x -> Codex takes over frontend tasks
- Codex fails 2x -> Claude takes over implementation
- Any agent unresponsive > 10 min -> trigger degradation

## Setup for Different Platforms

**Windows (Git Bash):** Works out of the box with Git Bash.

**macOS / Linux:** Works natively with bash.

**Prerequisites:**
- Node.js >= 18
- Git
- Claude Code CLI
- Codex CLI (optional, can run manually)
- Gemini CLI (optional, can run manually)
