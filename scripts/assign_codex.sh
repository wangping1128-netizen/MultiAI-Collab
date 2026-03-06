#!/bin/bash
# =============================================================================
# Assign task to Codex CLI (backend engineer)
# Uses: codex exec (non-interactive mode)
# =============================================================================

set -euo pipefail

TASK_FILE="$1"
TASK_NAME=$(basename "$TASK_FILE" .md)
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DONE_DIR="$SCRIPT_DIR/tasks/done"
RESULT_FILE="$DONE_DIR/${TASK_NAME}-result.md"

TASK_CONTENT=$(cat "$TASK_FILE")

PROMPT="You are a backend engineer working in the project at: $SCRIPT_DIR

Here is your task:

$TASK_CONTENT

INSTRUCTIONS:
1. Read the task carefully, implement ALL requirements.
2. Only modify files listed in 'File Scope'. Do NOT touch other files.
3. Write clean, tested code.
4. When done, create a result file at: $RESULT_FILE

The result file MUST follow this exact format:

# ${TASK_NAME} Result

## Status
<completed | partial | failed>

## Files Modified
- path/to/file.js (description, N lines)

## Test Results
Passed: X / Y
Coverage: Z%

## Notes
Any caveats or follow-ups.
"

echo "  Codex executing: $TASK_NAME"

RETRY_COUNT=0
MAX_RETRIES=2

while [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; do
  codex exec \
    -s workspace-write \
    --ephemeral \
    "$PROMPT" 2>&1 | while IFS= read -r line; do echo "  [codex] $line"; done

  if [ -f "$RESULT_FILE" ]; then
    echo "  Codex completed: $RESULT_FILE"
    exit 0
  fi

  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "  Codex attempt $RETRY_COUNT/$MAX_RETRIES did not produce result file."
done

echo "  Codex failed $MAX_RETRIES times. Triggering degradation." >&2
cat >> "$TASK_FILE" <<EOF

## Degradation
Codex failed $MAX_RETRIES times. Reassigned to Claude for manual implementation.
EOF
exit 1
