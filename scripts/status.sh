#!/bin/bash
# =============================================================================
# status.sh - Show task pipeline status at a glance
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PENDING="$SCRIPT_DIR/tasks/pending"
INPROG="$SCRIPT_DIR/tasks/in-progress"
DONE="$SCRIPT_DIR/tasks/done"

count_files() {
  local dir="$1"
  local pattern="$2"
  find "$dir" -maxdepth 1 -name "$pattern" -type f 2>/dev/null | wc -l | tr -d ' '
}

# Count tasks
PENDING_COUNT=$(count_files "$PENDING" "task-*.md")
INPROG_COUNT=$(count_files "$INPROG" "task-*.md")
DONE_TOTAL=$(count_files "$DONE" "task-*-result.md")

# Count by status
COMPLETED=0
FAILED=0
PARTIAL=0

for f in "$DONE"/task-*-result.md; do
  [ -f "$f" ] || continue
  status=$(grep -i '## Status' -A1 "$f" | tail -1 | tr -d '[:space:]')
  case "$status" in
    completed) COMPLETED=$((COMPLETED + 1)) ;;
    failed)    FAILED=$((FAILED + 1)) ;;
    partial)   PARTIAL=$((PARTIAL + 1)) ;;
  esac
done

echo "============================================"
echo " Task Pipeline Status"
echo "============================================"
echo ""
printf "  %-15s %s\n" "Pending:" "$PENDING_COUNT"
printf "  %-15s %s\n" "In-Progress:" "$INPROG_COUNT"
printf "  %-15s %s\n" "Done (total):" "$DONE_TOTAL"
echo ""
echo "  Results breakdown:"
printf "    %-13s %s\n" "Completed:" "$COMPLETED"
printf "    %-13s %s\n" "Partial:" "$PARTIAL"
printf "    %-13s %s\n" "Failed:" "$FAILED"

if [ "$DONE_TOTAL" -gt 0 ]; then
  SUCCESS_RATE=$((COMPLETED * 100 / DONE_TOTAL))
  echo ""
  echo "  Success rate: ${SUCCESS_RATE}%"
fi

echo ""
echo "============================================"

# List details
if [ "$PENDING_COUNT" -gt 0 ]; then
  echo ""
  echo "PENDING:"
  for f in "$PENDING"/task-*.md; do
    [ -f "$f" ] || continue
    title=$(head -1 "$f" | sed 's/^# //')
    assignee=$(grep -i '## Assignee' -A1 "$f" | tail -1 | tr -d '[:space:]')
    printf "  %-20s %-30s [%s]\n" "$(basename "$f")" "$title" "$assignee"
  done
fi

if [ "$INPROG_COUNT" -gt 0 ]; then
  echo ""
  echo "IN-PROGRESS:"
  for f in "$INPROG"/task-*.md; do
    [ -f "$f" ] || continue
    title=$(head -1 "$f" | sed 's/^# //')
    printf "  %-20s %s\n" "$(basename "$f")" "$title"
  done
fi

if [ "$DONE_TOTAL" -gt 0 ]; then
  echo ""
  echo "DONE:"
  for f in "$DONE"/task-*-result.md; do
    [ -f "$f" ] || continue
    task_name=$(basename "$f" | sed 's/-result\.md//')
    status=$(grep -i '## Status' -A1 "$f" | tail -1 | tr -d '[:space:]')
    printf "  %-20s [%s]\n" "$task_name" "$status"
  done
fi
