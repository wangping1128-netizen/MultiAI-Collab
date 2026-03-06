# task-001: Create Express.js hello world endpoint

## Objective
Create a minimal Express.js server with a /health endpoint for pipeline validation.

## Technical Requirements
- Create `src/routes/health.js` exporting an Express Router with GET /health
- Response: `{ "status": "ok", "timestamp": "<ISO string>" }`
- Create `src/app.js` as the Express app entry point (import health route, listen on port 3000)
- Create `src/tests/health.test.js` using Node.js built-in test runner (`node:test` + `node:assert`)
- Do NOT use any test framework other than Node.js built-in (no jest, no mocha)
- Run tests with: `node --test src/tests/health.test.js`

## File Scope (only these files may be modified)
- src/routes/health.js
- src/app.js
- src/tests/health.test.js
DO NOT modify: package.json, .env, orchestrator.sh, scripts/

## Acceptance Criteria
- [ ] GET /health returns 200 with JSON `{ "status": "ok", "timestamp": "..." }`
- [ ] Test file passes with `node --test`
- [ ] No external test dependencies required

## Assignee
backend (Codex)

## On Completion
Write result to tasks/done/task-001-result.md
