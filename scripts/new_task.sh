#!/bin/bash
# =============================================================================
# new_task.sh - Auto-numbered task creator with interactive prompts
#
# Usage:
#   bash scripts/new_task.sh                    # interactive mode
#   bash scripts/new_task.sh -t "title" -a backend -f "src/a.js,src/b.js"  # CLI mode
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PENDING="$SCRIPT_DIR/tasks/pending"
DONE="$SCRIPT_DIR/tasks/done"
INPROG="$SCRIPT_DIR/tasks/in-progress"

# --- Auto-increment task number ---
next_task_number() {
  local max=0
  for dir in "$PENDING" "$INPROG" "$DONE"; do
    for f in "$dir"/task-*.md; do
      [ -f "$f" ] || continue
      # Extract number from task-001.md or task-001-result.md
      num=$(basename "$f" | grep -oP 'task-\K[0-9]+' | head -1)
      num=$((10#$num))  # remove leading zeros
      [ "$num" -gt "$max" ] && max=$num
    done
  done
  printf "%03d" $((max + 1))
}

# --- Parse CLI arguments ---
TITLE=""
ASSIGNEE=""
FILES=""
OBJECTIVE=""
REQUIREMENTS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--title)       TITLE="$2"; shift 2 ;;
    -a|--assignee)    ASSIGNEE="$2"; shift 2 ;;
    -f|--files)       FILES="$2"; shift 2 ;;
    -o|--objective)   OBJECTIVE="$2"; shift 2 ;;
    -r|--requirements) REQUIREMENTS="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: new_task.sh [-t title] [-a backend|frontend] [-f file1,file2] [-o objective] [-r requirements]"
      exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Interactive prompts for missing fields ---
if [ -z "$TITLE" ]; then
  read -rp "Task title: " TITLE
  [ -z "$TITLE" ] && { echo "Title is required."; exit 1; }
fi

if [ -z "$ASSIGNEE" ]; then
  echo "Assignee:"
  echo "  1) backend (Codex)"
  echo "  2) frontend (Gemini)"
  read -rp "Choose [1/2]: " choice
  case "$choice" in
    1) ASSIGNEE="backend (Codex)" ;;
    2) ASSIGNEE="frontend (Gemini)" ;;
    *) echo "Invalid choice."; exit 1 ;;
  esac
fi

if [ -z "$OBJECTIVE" ]; then
  read -rp "Objective (one sentence): " OBJECTIVE
  [ -z "$OBJECTIVE" ] && OBJECTIVE="$TITLE"
fi

if [ -z "$REQUIREMENTS" ]; then
  echo "Technical requirements (enter multi-line, end with empty line):"
  REQUIREMENTS=""
  while IFS= read -r line; do
    [ -z "$line" ] && break
    REQUIREMENTS="$REQUIREMENTS$line"$'\n'
  done
fi

if [ -z "$FILES" ]; then
  read -rp "File scope (comma-separated, e.g. src/a.js,src/b.js): " FILES
fi

# --- Generate task file ---
NUM=$(next_task_number)
TASK_ID="task-$NUM"
TASK_FILE="$PENDING/$TASK_ID.md"

mkdir -p "$PENDING"

# Build file scope list
FILE_SCOPE=""
IFS=',' read -ra FILE_ARR <<< "$FILES"
for f in "${FILE_ARR[@]}"; do
  f=$(echo "$f" | xargs)  # trim whitespace
  [ -n "$f" ] && FILE_SCOPE="$FILE_SCOPE- $f"$'\n'
done

cat > "$TASK_FILE" <<EOF
# $TASK_ID: $TITLE

## Objective
$OBJECTIVE

## Technical Requirements
$REQUIREMENTS
## File Scope (only these files may be modified)
${FILE_SCOPE}DO NOT modify: package.json, .env, database schemas (unless explicitly stated)

## Acceptance Criteria
- [ ] All technical requirements implemented
- [ ] Code is clean and follows project conventions
- [ ] Unit test coverage > 80%

## Assignee
$ASSIGNEE

## On Completion
Write result to tasks/done/$TASK_ID-result.md
EOF

echo ""
echo "Created: $TASK_FILE"
echo "Task ID: $TASK_ID"
echo "Assignee: $ASSIGNEE"
echo ""
echo "The orchestrator will pick it up automatically."
