#!/bin/bash
# =============================================================================
# Assign task to Codex CLI (backend engineer)
# Uses: codex exec (non-interactive mode) with stdin prompt
# =============================================================================

set -euo pipefail

TASK_FILE="$1"
TASK_NAME=$(basename "$TASK_FILE" .md)
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DONE_DIR="$SCRIPT_DIR/tasks/done"
RESULT_FILE="$DONE_DIR/${TASK_NAME}-result.md"
AGENTS_FILE="$SCRIPT_DIR/AGENTS.md"

TASK_CONTENT=$(cat "$TASK_FILE")

# Build prompt into temp file (avoids argument length limits)
PROMPT_FILE=$(mktemp)
trap 'rm -f "$PROMPT_FILE"' EXIT

{
  echo "You are a backend engineer working in the project at: $SCRIPT_DIR"
  echo ""
  # Inject project context if AGENTS.md exists
  if [ -f "$AGENTS_FILE" ]; then
    echo "## Project Context"
    cat "$AGENTS_FILE"
    echo ""
  fi
  echo "## Your Task"
  echo ""
  echo "$TASK_CONTENT"
  echo ""
  echo "## Instructions"
  echo "1. Read the task carefully, implement ALL requirements."
  echo "2. Only modify files listed in 'File Scope'. Do NOT touch other files."
  echo "3. Write clean, tested code."
  echo "4. When done, create a result file at: $RESULT_FILE"
  echo ""
  echo "The result file MUST follow this exact format:"
  echo ""
  echo "# ${TASK_NAME} Result"
  echo ""
  echo "## Status"
  echo "<completed | partial | failed>"
  echo ""
  echo "## Files Modified"
  echo "- path/to/file.js (description, N lines)"
  echo ""
  echo "## Test Results"
  echo "Passed: X / Y"
  echo "Coverage: Z%"
  echo ""
  echo "## Notes"
  echo "Any caveats or follow-ups."
} > "$PROMPT_FILE"

echo "  Codex executing: $TASK_NAME"

RETRY_COUNT=0
MAX_RETRIES=2

while [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; do
  # Pass prompt via stdin (use "-" to read from stdin)
  codex exec \
    -s workspace-write \
    --ephemeral \
    - < "$PROMPT_FILE" 2>&1 | while IFS= read -r line; do echo "  [codex] $line"; done

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
