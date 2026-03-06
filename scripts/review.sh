#!/bin/bash
# =============================================================================
# review.sh - Auto-review completed tasks using Claude CLI
#
# Scans tasks/done/ for result files without a corresponding review file.
# Calls Claude CLI (-p mode) to evaluate each result, then writes a review.
# On failure, auto-generates a fix task in tasks/pending/.
#
# Usage:
#   bash scripts/review.sh           # one-shot: review all pending results
#   bash scripts/review.sh --watch   # continuous: poll for new results
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PENDING="$SCRIPT_DIR/tasks/pending"
INPROG="$SCRIPT_DIR/tasks/in-progress"
DONE="$SCRIPT_DIR/tasks/done"
LOG_DIR="$SCRIPT_DIR/logs"
WATCH_MODE=false

mkdir -p "$LOG_DIR"

if [[ "${1:-}" == "--watch" ]]; then
  WATCH_MODE=true
fi

log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [review] $*"
  echo "$msg"
  echo "$msg" >> "$LOG_DIR/review.log"
}

# --- Find the original task file (in-progress or done dir) ---
find_task_file() {
  local task_id="$1"  # e.g. task-001
  for dir in "$INPROG" "$DONE" "$PENDING"; do
    if [ -f "$dir/$task_id.md" ]; then
      echo "$dir/$task_id.md"
      return 0
    fi
  done
  return 1
}

# --- Auto-generate fix task on review failure ---
generate_fix_task() {
  local task_id="$1"
  local review_file="$2"
  local original_task="$3"

  # Determine next task number
  local max=0
  for dir in "$PENDING" "$INPROG" "$DONE"; do
    for f in "$dir"/task-*.md; do
      [ -f "$f" ] || continue
      num=$(basename "$f" | grep -oP 'task-\K[0-9]+' | head -1)
      num=$((10#$num))
      [ "$num" -gt "$max" ] && max=$num
    done
  done
  local next_num
  next_num=$(printf "%03d" $((max + 1)))
  local fix_file="$PENDING/task-$next_num.md"

  # Extract assignee from original task
  local assignee="backend (Codex)"
  if [ -f "$original_task" ]; then
    local found
    found=$(grep -i '## Assignee' -A1 "$original_task" | tail -1) || true
    [ -n "$found" ] && assignee="$found"
  fi

  # Extract review feedback
  local feedback
  feedback=$(sed -n '/## Feedback/,/^## /p' "$review_file" | head -20) || true

  cat > "$fix_file" <<EOF
# task-$next_num: Fix issues from $task_id review

## Objective
Fix the issues identified in the review of $task_id.

## Technical Requirements
The previous implementation ($task_id) was reviewed and rejected. Address the following feedback:

$feedback

Refer to the original task requirements in $task_id and the review in $(basename "$review_file").

## File Scope (only these files may be modified)
(same as $task_id - check original task file)
DO NOT modify: package.json, .env, database schemas (unless explicitly stated)

## Acceptance Criteria
- [ ] All review feedback items addressed
- [ ] Original task acceptance criteria met
- [ ] Unit test coverage > 80%

## Assignee
$assignee

## On Completion
Write result to tasks/done/task-$next_num-result.md
EOF

  log "Generated fix task: task-$next_num (for $task_id)"
  echo "$fix_file"
}

# --- Review a single result file ---
review_one() {
  local result_file="$1"
  local result_name
  result_name=$(basename "$result_file")
  local task_id
  task_id=$(echo "$result_name" | sed 's/-result\.md//')
  local review_file="$DONE/${task_id}-review.md"

  # Skip if already reviewed
  if [ -f "$review_file" ]; then
    return 0
  fi

  log "Reviewing: $task_id"

  # Find original task
  local task_file=""
  task_file=$(find_task_file "$task_id") || true

  # Build review prompt
  local prompt_file
  prompt_file=$(mktemp)
  trap 'rm -f "$prompt_file"' RETURN

  {
    echo "You are a senior code reviewer. Review the following task result."
    echo ""
    echo "## Result File"
    echo ""
    cat "$result_file"
    echo ""
    if [ -n "$task_file" ] && [ -f "$task_file" ]; then
      echo "## Original Task"
      echo ""
      cat "$task_file"
      echo ""
    fi
    echo "## Review Instructions"
    echo ""
    echo "1. Check if the result status is 'completed'."
    echo "2. Verify all acceptance criteria from the original task are met."
    echo "3. Check that only files in 'File Scope' were modified."
    echo "4. Evaluate code quality (if you can see the files mentioned)."
    echo "5. Check test results."
    echo ""
    echo "Output your review in EXACTLY this format (no other text):"
    echo ""
    echo "# ${task_id} Review"
    echo ""
    echo "## Verdict"
    echo "pass | fail"
    echo ""
    echo "## Score"
    echo "X/10"
    echo ""
    echo "## Feedback"
    echo "- Point 1"
    echo "- Point 2"
    echo ""
    echo "## Action"
    echo "accept | revise"
  } > "$prompt_file"

  # Call Claude CLI in non-interactive mode
  local claude_output
  claude_output=$(cat "$prompt_file" | claude -p --allowedTools "Read" --no-session-persistence 2>/dev/null) || {
    log "ERROR: Claude CLI failed for $task_id"
    return 1
  }

  # Write review file
  echo "$claude_output" > "$review_file"
  log "Review written: $review_file"

  # Check verdict
  local verdict
  verdict=$(grep -i '## Verdict' -A1 "$review_file" | tail -1 | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]') || true

  local action
  action=$(grep -i '## Action' -A1 "$review_file" | tail -1 | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]') || true

  if [[ "$verdict" == "fail" ]] || [[ "$action" == "revise" ]]; then
    log "FAILED: $task_id -> generating fix task"
    generate_fix_task "$task_id" "$review_file" "${task_file:-}"
  else
    log "PASSED: $task_id -> ready for git commit"
  fi
}

# --- Main ---
run_reviews() {
  local reviewed=0
  for result in "$DONE"/task-*-result.md; do
    [ -f "$result" ] || continue
    # Skip review files themselves
    [[ "$result" == *-review.md ]] && continue

    local task_id
    task_id=$(basename "$result" | sed 's/-result\.md//')
    local review_file="$DONE/${task_id}-review.md"

    if [ ! -f "$review_file" ]; then
      review_one "$result"
      reviewed=$((reviewed + 1))
    fi
  done

  if [ "$reviewed" -eq 0 ] && [ "$WATCH_MODE" = false ]; then
    log "No unreviewed results found."
  fi
}

if [ "$WATCH_MODE" = true ]; then
  log "Watch mode enabled. Polling for new results..."
  while true; do
    run_reviews
    sleep 10
  done
else
  run_reviews
fi
