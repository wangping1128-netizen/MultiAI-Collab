#!/bin/bash
# =============================================================================
# Assign task to Codex CLI (backend engineer)
# =============================================================================

set -euo pipefail

TASK_FILE="$1"
TASK_NAME=$(basename "$TASK_FILE" .md)
RESULT_FILE="tasks/done/${TASK_NAME}-result.md"
RETRY_COUNT=0
MAX_RETRIES=2

# Read task content
TASK_CONTENT=$(cat "$TASK_FILE")

echo "  Codex executing: $TASK_NAME"

# Execute via Codex CLI
# TODO: Replace with actual Codex CLI invocation for your environment
# codex --input "$TASK_CONTENT" --output-file "$RESULT_FILE" --no-interactive
echo "  [STUB] Codex CLI not yet configured. Place result manually in: $RESULT_FILE"

# Check result
if [ -f "$RESULT_FILE" ]; then
  echo "  Codex completed: $RESULT_FILE"
else
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
    echo "  Codex failed $MAX_RETRIES times. Triggering degradation." >&2
    echo "" >> "$TASK_FILE"
    echo "## Degradation" >> "$TASK_FILE"
    echo "Codex failed. Reassigned to Claude for manual implementation." >> "$TASK_FILE"
  else
    echo "  Codex did not produce result file. Retry or manual intervention needed." >&2
  fi
fi
