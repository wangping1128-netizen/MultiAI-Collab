#!/bin/bash
# =============================================================================
# Multi-AI Orchestrator - File-based task dispatcher
# Works on: Linux, macOS, Windows (Git Bash / WSL)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PENDING="$SCRIPT_DIR/tasks/pending"
INPROG="$SCRIPT_DIR/tasks/in-progress"
DONE="$SCRIPT_DIR/tasks/done"
POLL_INTERVAL=5

# Ensure directories exist
mkdir -p "$PENDING" "$INPROG" "$DONE"

echo "============================================"
echo " Multi-AI Orchestrator"
echo " Poll interval: ${POLL_INTERVAL}s"
echo " Pending:     $PENDING"
echo " In-progress: $INPROG"
echo " Done:        $DONE"
echo "============================================"
echo ""
echo "Orchestrator started. Waiting for tasks..."

while true; do
  for task in "$PENDING"/task-*.md; do
    [ -f "$task" ] || continue

    name=$(basename "$task")
    echo ""
    echo "[$(date '+%H:%M:%S')] Found task: $name"

    # Move to in-progress
    mv "$task" "$INPROG/$name"

    # Dispatch by assignee
    if grep -qi 'backend' "$INPROG/$name"; then
      echo "  -> Dispatching to Codex (backend)..."
      bash "$SCRIPT_DIR/scripts/assign_codex.sh" "$INPROG/$name"
    elif grep -qi 'frontend' "$INPROG/$name"; then
      echo "  -> Dispatching to Gemini (frontend)..."
      bash "$SCRIPT_DIR/scripts/assign_gemini.sh" "$INPROG/$name"
    else
      echo "  -> No assignee found, defaulting to Codex..."
      bash "$SCRIPT_DIR/scripts/assign_codex.sh" "$INPROG/$name"
    fi

    echo "[$(date '+%H:%M:%S')] Done: $name -> awaiting Claude review"
  done

  sleep "$POLL_INTERVAL"
done
