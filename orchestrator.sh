#!/bin/bash
# =============================================================================
# Multi-AI Orchestrator - File-based task dispatcher
# Works on: Linux, macOS, Windows (Git Bash / WSL)
#
# Flow: tasks/pending/ -> in-progress/ -> done/
# Dispatches to Codex (backend) or Gemini (frontend) based on Assignee field.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PENDING="$SCRIPT_DIR/tasks/pending"
INPROG="$SCRIPT_DIR/tasks/in-progress"
DONE="$SCRIPT_DIR/tasks/done"
POLL_INTERVAL=5
TASK_TIMEOUT=600  # 10 minutes per task

# Ensure directories exist
mkdir -p "$PENDING" "$INPROG" "$DONE"

echo "============================================"
echo " Multi-AI Orchestrator"
echo " Poll interval: ${POLL_INTERVAL}s"
echo " Task timeout:  ${TASK_TIMEOUT}s"
echo " Pending:       $PENDING"
echo " In-progress:   $INPROG"
echo " Done:          $DONE"
echo "============================================"
echo ""
echo "Orchestrator started. Waiting for tasks..."

dispatch_task() {
  local task_file="$1"
  local task_name="$2"

  if grep -qi 'backend\|codex' "$task_file"; then
    echo "  -> Dispatching to Codex (backend)..."
    timeout "$TASK_TIMEOUT" bash "$SCRIPT_DIR/scripts/assign_codex.sh" "$task_file"
  elif grep -qi 'frontend\|gemini' "$task_file"; then
    echo "  -> Dispatching to Gemini (frontend)..."
    timeout "$TASK_TIMEOUT" bash "$SCRIPT_DIR/scripts/assign_gemini.sh" "$task_file"
  else
    echo "  -> No assignee detected, defaulting to Codex..."
    timeout "$TASK_TIMEOUT" bash "$SCRIPT_DIR/scripts/assign_codex.sh" "$task_file"
  fi
}

while true; do
  for task in "$PENDING"/task-*.md; do
    [ -f "$task" ] || continue

    name=$(basename "$task")
    echo ""
    echo "[$(date '+%H:%M:%S')] Found task: $name"

    # Move to in-progress
    mv "$task" "$INPROG/$name"

    # Dispatch with timeout
    if dispatch_task "$INPROG/$name" "$name"; then
      echo "[$(date '+%H:%M:%S')] Done: $name -> awaiting Claude review"
    else
      exit_code=$?
      if [ "$exit_code" -eq 124 ]; then
        echo "[$(date '+%H:%M:%S')] TIMEOUT: $name exceeded ${TASK_TIMEOUT}s" >&2
        cat >> "$INPROG/$name" <<EOF

## Degradation
Task timed out after ${TASK_TIMEOUT}s. Requires manual intervention.
EOF
      else
        echo "[$(date '+%H:%M:%S')] FAILED: $name (exit code: $exit_code)" >&2
      fi
      # Move failed task to done so Claude can review
      result_name="${name%.md}-result.md"
      if [ ! -f "$DONE/$result_name" ]; then
        cat > "$DONE/$result_name" <<EOF
# ${name%.md} Result

## Status
failed

## Files Modified
(none)

## Test Results
N/A

## Notes
Task dispatch failed. Exit code: $exit_code. Check orchestrator logs.
EOF
      fi
    fi
  done

  sleep "$POLL_INTERVAL"
done
