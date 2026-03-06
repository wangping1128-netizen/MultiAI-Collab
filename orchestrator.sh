#!/bin/bash
# =============================================================================
# Multi-AI Orchestrator - File-based task dispatcher
# Works on: Linux, macOS, Windows (Git Bash / WSL)
#
# Flow: tasks/pending/ -> in-progress/ -> done/
# Dispatches to Codex (backend) or Gemini (frontend) based on Assignee field.
# Supports parallel task execution with PID tracking.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PENDING="$SCRIPT_DIR/tasks/pending"
INPROG="$SCRIPT_DIR/tasks/in-progress"
DONE="$SCRIPT_DIR/tasks/done"
LOG_DIR="$SCRIPT_DIR/logs"
POLL_INTERVAL=5
TASK_TIMEOUT=600  # 10 minutes per task
MAX_PARALLEL=3    # max concurrent tasks

# Ensure directories exist
mkdir -p "$PENDING" "$INPROG" "$DONE" "$LOG_DIR"

LOG_FILE="$LOG_DIR/orchestrator.log"

# Structured logging
log() {
  local level="$1"; shift
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
  echo "$msg"
  echo "$msg" >> "$LOG_FILE"
}

echo "============================================"
echo " Multi-AI Orchestrator"
echo " Poll interval: ${POLL_INTERVAL}s"
echo " Task timeout:  ${TASK_TIMEOUT}s"
echo " Max parallel:  ${MAX_PARALLEL}"
echo " Log file:      $LOG_FILE"
echo "============================================"
echo ""
log INFO "Orchestrator started. Waiting for tasks..."

# --- PID tracking for parallel execution ---
declare -A TASK_PIDS  # task_name -> PID
declare -A TASK_LOGS  # task_name -> log file

# Clean up background processes on exit
cleanup() {
  log INFO "Shutting down orchestrator..."
  for name in "${!TASK_PIDS[@]}"; do
    local pid="${TASK_PIDS[$name]}"
    if kill -0 "$pid" 2>/dev/null; then
      log WARN "Killing running task: $name (PID $pid)"
      kill "$pid" 2>/dev/null || true
    fi
  done
  exit 0
}
trap cleanup SIGINT SIGTERM

# Dispatch a single task in background
dispatch_task() {
  local task_file="$1"
  local task_name="$2"
  local task_log="$LOG_DIR/${task_name}.log"

  {
    if grep -qi 'backend\|codex' "$task_file"; then
      log INFO "  -> Dispatching $task_name to Codex (backend)..."
      timeout "$TASK_TIMEOUT" bash "$SCRIPT_DIR/scripts/assign_codex.sh" "$task_file"
    elif grep -qi 'frontend\|gemini' "$task_file"; then
      log INFO "  -> Dispatching $task_name to Gemini (frontend)..."
      timeout "$TASK_TIMEOUT" bash "$SCRIPT_DIR/scripts/assign_gemini.sh" "$task_file"
    else
      log INFO "  -> No assignee for $task_name, defaulting to Codex..."
      timeout "$TASK_TIMEOUT" bash "$SCRIPT_DIR/scripts/assign_codex.sh" "$task_file"
    fi
  } > "$task_log" 2>&1

  return $?
}

# Check completed background tasks
check_completed() {
  for name in "${!TASK_PIDS[@]}"; do
    local pid="${TASK_PIDS[$name]}"
    if ! kill -0 "$pid" 2>/dev/null; then
      # Process finished, get exit code
      wait "$pid" 2>/dev/null
      local exit_code=$?
      local result_name="${name%.md}-result.md"

      if [ "$exit_code" -eq 0 ]; then
        log INFO "COMPLETED: $name -> awaiting Claude review"
      elif [ "$exit_code" -eq 124 ]; then
        log ERROR "TIMEOUT: $name exceeded ${TASK_TIMEOUT}s"
        cat >> "$INPROG/$name" <<EOF

## Degradation
Task timed out after ${TASK_TIMEOUT}s. Requires manual intervention.
EOF
      else
        log ERROR "FAILED: $name (exit code: $exit_code)"
      fi

      # Generate failed result if none exists
      if [ "$exit_code" -ne 0 ] && [ ! -f "$DONE/$result_name" ]; then
        cat > "$DONE/$result_name" <<EOF
# ${name%.md} Result

## Status
failed

## Files Modified
(none)

## Test Results
N/A

## Notes
Task dispatch failed. Exit code: $exit_code. See logs/$name.log
EOF
      fi

      # Show task log
      if [ -f "$LOG_DIR/$name.log" ]; then
        log INFO "--- Output from $name ---"
        cat "$LOG_DIR/$name.log" | while IFS= read -r line; do echo "  $line"; done
        log INFO "--- End $name ---"
      fi

      unset "TASK_PIDS[$name]"
      unset "TASK_LOGS[$name]"
    fi
  done
}

# Count running tasks
running_count() {
  local count=0
  for name in "${!TASK_PIDS[@]}"; do
    if kill -0 "${TASK_PIDS[$name]}" 2>/dev/null; then
      count=$((count + 1))
    fi
  done
  echo "$count"
}

# --- Main loop ---
while true; do
  # Check for completed tasks
  check_completed

  # Dispatch new tasks if under parallel limit
  for task in "$PENDING"/task-*.md; do
    [ -f "$task" ] || continue

    local_running=$(running_count)
    if [ "$local_running" -ge "$MAX_PARALLEL" ]; then
      log WARN "Parallel limit reached ($MAX_PARALLEL). Waiting..."
      break
    fi

    name=$(basename "$task")
    log INFO "Found task: $name"

    # Move to in-progress
    mv "$task" "$INPROG/$name"

    # Dispatch in background
    dispatch_task "$INPROG/$name" "$name" &
    TASK_PIDS["$name"]=$!
    TASK_LOGS["$name"]="$LOG_DIR/$name.log"
    log INFO "Started: $name (PID ${TASK_PIDS[$name]})"
  done

  sleep "$POLL_INTERVAL"
done
