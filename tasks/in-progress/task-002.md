# task-002: Create a simple React StatusCard component

## Objective
Create a React component that displays system health status for pipeline validation.

## Technical Requirements
- Create `src/components/StatusCard.jsx` as a functional React component
- Props: `{ title: string, status: "ok" | "error", timestamp: string }`
- Render: a card div with title, a colored status indicator (green for ok, red for error), and formatted timestamp
- Use inline styles or CSS classes (no CSS-in-JS libraries)
- Create `src/tests/StatusCard.test.js` that tests the component renders with given props
- Use Node.js built-in test runner (`node:test` + `node:assert`) - test that the component function returns expected JSX structure
- Do NOT use jest, mocha, or React Testing Library

## File Scope (only these files may be modified)
- src/components/StatusCard.jsx
- src/tests/StatusCard.test.js
DO NOT modify: package.json, .env, orchestrator.sh, scripts/

## Acceptance Criteria
- [ ] StatusCard.jsx exports a valid React functional component
- [ ] Component accepts title, status, timestamp props
- [ ] Test file verifies component output with `node --test`

## Assignee
frontend (Gemini)

## On Completion
Write result to tasks/done/task-002-result.md

## Degradation
Gemini failed 2 times. Reassigned to Codex (backend-fallback).
