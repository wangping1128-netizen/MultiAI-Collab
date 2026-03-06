# task-005: Interactive task creator (Node.js CLI)

## Objective
Create a Node.js interactive task creator using Inquirer.js to replace the bash-only new_task.sh for a better UX.

## Technical Requirements

### scripts/create_task.js
- Use `inquirer` (npm package) for interactive prompts
- Prompts (in order):
  1. Task title (text input, required)
  2. Assignee (list: "backend (Codex)" / "frontend (Gemini)")
  3. Objective (text input, defaults to title)
  4. Technical requirements (editor prompt or multi-line input)
  5. File scope (text input, comma-separated paths)
  6. Additional acceptance criteria (text input, optional)
- Auto-number: scan tasks/pending/, tasks/in-progress/, tasks/done/ for highest task-XXX number, increment by 1
- Generate task file to tasks/pending/task-XXX.md following the exact template format from CLAUDE.md
- After creation, print the file path and a summary
- Handle Ctrl+C gracefully (no ugly stack trace)

### Dependencies
- Add `inquirer` to package.json devDependencies
- The script should be runnable via: `node scripts/create_task.js`

### Template format (must match exactly):
```
# task-XXX: <title>

## Objective
<objective>

## Technical Requirements
<requirements>

## File Scope (only these files may be modified)
- <file1>
- <file2>
DO NOT modify: package.json, .env, database schemas (unless explicitly stated)

## Acceptance Criteria
- [ ] All technical requirements implemented
- [ ] Code is clean and follows project conventions
- [ ] Unit test coverage > 80%
<additional criteria>

## Assignee
<assignee>

## On Completion
Write result to tasks/done/task-XXX-result.md
```

## File Scope (only these files may be modified)
- scripts/create_task.js
- package.json (only add inquirer to devDependencies)
DO NOT modify: scripts/new_task.sh, orchestrator.sh, config.json

## Acceptance Criteria
- [ ] Interactive prompts work correctly
- [ ] Auto-numbering scans all 3 task directories
- [ ] Generated task file matches the template format exactly
- [ ] Script handles Ctrl+C without stack trace
- [ ] `node scripts/create_task.js` runs without errors

## Assignee
backend (Codex)

## On Completion
Write result to tasks/done/task-005-result.md
