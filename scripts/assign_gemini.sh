#!/bin/bash
# =============================================================================
# Assign task to Gemini CLI (frontend engineer / code reviewer)
# Uses: gemini -p (non-interactive headless mode) with prompt file
# =============================================================================

set -euo pipefail

TASK_FILE="$1"
TASK_NAME=$(basename "$TASK_FILE" .md)
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/scripts/lib/config.sh"

DONE_DIR="$SCRIPT_DIR/tasks/done"
RESULT_FILE="$DONE_DIR/${TASK_NAME}-result.md"
AGENTS_FILE="$SCRIPT_DIR/AGENTS.md"

GEMINI_MODEL=$(cfg "gemini.model" "")
GEMINI_APPROVAL=$(cfg "gemini.approval_mode" "yolo")
GEMINI_OUTPUT=$(cfg "gemini.output_format" "text")

TASK_CONTENT=$(cat "$TASK_FILE")

# Build prompt into temp file (avoids argument length limits)
PROMPT_FILE=$(mktemp)
trap 'rm -f "$PROMPT_FILE"' EXIT

{
  echo "You are a frontend engineer working in the project at: $SCRIPT_DIR"
  echo ""
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

echo "  Gemini executing: $TASK_NAME"

RETRY_COUNT=0
MAX_RETRIES=2

# Read prompt from file, pass via -p flag (Gemini reads stdin + -p together)
PROMPT_CONTENT=$(cat "$PROMPT_FILE")

while [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; do
  # Build gemini command with config
  GEMINI_CMD=(gemini -p - --approval-mode "$GEMINI_APPROVAL" -o "$GEMINI_OUTPUT")
  [[ -n "$GEMINI_MODEL" ]] && GEMINI_CMD+=(-m "$GEMINI_MODEL")

  echo "$PROMPT_CONTENT" | "${GEMINI_CMD[@]}" 2>&1 | while IFS= read -r line; do echo "  [gemini] $line"; done

  if [ -f "$RESULT_FILE" ]; then
    echo "  Gemini completed: $RESULT_FILE"
    exit 0
  fi

  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "  Gemini attempt $RETRY_COUNT/$MAX_RETRIES did not produce result file."
done

echo "  Gemini failed $MAX_RETRIES times. Falling back to Codex." >&2
cat >> "$TASK_FILE" <<EOF

## Degradation
Gemini failed $MAX_RETRIES times. Reassigned to Codex (backend-fallback).
EOF

# Re-dispatch to Codex as fallback
bash "$(dirname "$0")/assign_codex.sh" "$TASK_FILE"
