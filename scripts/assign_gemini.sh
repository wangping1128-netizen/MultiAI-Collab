#!/bin/bash
# =============================================================================
# Assign task to Gemini CLI (frontend engineer / code reviewer)
# =============================================================================

set -euo pipefail

TASK_FILE="$1"
TASK_NAME=$(basename "$TASK_FILE" .md)
RESULT_FILE="tasks/done/${TASK_NAME}-result.md"
RETRY_COUNT=0
MAX_RETRIES=2

# Read task content
TASK_CONTENT=$(cat "$TASK_FILE")

echo "  Gemini executing: $TASK_NAME"

# Execute via Gemini CLI
# TODO: Replace with actual Gemini CLI invocation for your environment
# gemini --input "$TASK_CONTENT" --output-file "$RESULT_FILE"
echo "  [STUB] Gemini CLI not yet configured. Place result manually in: $RESULT_FILE"

# Check result
if [ -f "$RESULT_FILE" ]; then
  echo "  Gemini completed: $RESULT_FILE"
else
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
    echo "  Gemini failed $MAX_RETRIES times. Falling back to Codex." >&2
    echo "" >> "$TASK_FILE"
    echo "## Degradation" >> "$TASK_FILE"
    echo "Gemini failed. Reassigned to Codex (backend-fallback)." >> "$TASK_FILE"
    # Re-dispatch to Codex
    bash "$(dirname "$0")/assign_codex.sh" "$TASK_FILE"
  else
    echo "  Gemini did not produce result file. Retry or manual intervention needed." >&2
  fi
fi
