#!/bin/bash
# =============================================================================
# test_e2e.sh - End-to-end smoke test for the MultiAI-Collab pipeline
#
# Temporarily enables dry_run mode, creates test tasks, runs the dispatcher
# once, and verifies the full pending -> done -> review cycle.
#
# Usage: bash scripts/test_e2e.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/scripts/lib/config.sh"

PENDING="$SCRIPT_DIR/tasks/pending"
INPROG="$SCRIPT_DIR/tasks/in-progress"
DONE="$SCRIPT_DIR/tasks/done"
CONFIG_FILE="$SCRIPT_DIR/config.json"
BACKUP_CONFIG=""
PASS=0
FAIL=0
TOTAL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_test() { echo -e "${YELLOW}[TEST]${NC} $*"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $*"; PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $*"; FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); }

# --- Setup: enable dry_run, backup config ---
setup() {
  log_test "Setting up E2E test environment..."

  # Backup original config
  BACKUP_CONFIG=$(mktemp)
  cp "$CONFIG_FILE" "$BACKUP_CONFIG"

  # Enable dry_run
  node -e "
    const fs = require('fs');
    const c = JSON.parse(fs.readFileSync(process.env.CF, 'utf8'));
    c.dry_run = true;
    fs.writeFileSync(process.env.CF, JSON.stringify(c, null, 2));
  " 2>/dev/null || { echo "Failed to set dry_run"; exit 1; }

  # Clean test artifacts
  rm -f "$PENDING"/task-9*.md
  rm -f "$INPROG"/task-9*.md
  rm -f "$DONE"/task-9*.md

  log_test "dry_run enabled, test artifacts cleaned."
}
export CF="$CONFIG_FILE"

# --- Teardown: restore config, clean test artifacts ---
teardown() {
  log_test "Cleaning up..."
  if [ -n "$BACKUP_CONFIG" ] && [ -f "$BACKUP_CONFIG" ]; then
    cp "$BACKUP_CONFIG" "$CONFIG_FILE"
    rm -f "$BACKUP_CONFIG"
  fi
  # Clean test tasks (900-series)
  rm -f "$PENDING"/task-9*.md
  rm -f "$INPROG"/task-9*.md
  rm -f "$DONE"/task-9*.md
  log_test "Teardown complete."
}
trap teardown EXIT

# --- Test 1: new_task.sh auto-numbering ---
test_new_task() {
  log_test "Test 1: Task auto-numbering (new_task.sh CLI mode)"

  # Create via CLI mode
  bash "$SCRIPT_DIR/scripts/new_task.sh" \
    -t "E2E Test Backend" \
    -a "backend (Codex)" \
    -f "src/test.js" \
    -o "E2E smoke test for backend dispatch" \
    -r "Create a test file"

  # Find the created task
  local latest
  latest=$(ls -t "$PENDING"/task-*.md 2>/dev/null | head -1)
  if [ -n "$latest" ] && grep -q "E2E Test Backend" "$latest"; then
    log_pass "Task file created: $(basename "$latest")"
  else
    log_fail "Task file not created or missing title"
    return 1
  fi

  # Rename to 900-series for isolation
  local task_name
  task_name=$(basename "$latest")
  mv "$latest" "$PENDING/task-901.md"
  sed -i 's/task-[0-9]*/task-901/g' "$PENDING/task-901.md"
}

# --- Test 2: Codex dry-run dispatch ---
test_codex_dispatch() {
  log_test "Test 2: Codex dry-run dispatch"

  if [ ! -f "$PENDING/task-901.md" ]; then
    log_fail "task-901.md not found in pending"
    return 1
  fi

  # Move to in-progress and dispatch
  mv "$PENDING/task-901.md" "$INPROG/task-901.md"
  bash "$SCRIPT_DIR/scripts/assign_codex.sh" "$INPROG/task-901.md"

  if [ -f "$DONE/task-901-result.md" ]; then
    log_pass "Codex dry-run produced result file"
  else
    log_fail "Codex dry-run did NOT produce result file"
    return 1
  fi

  if grep -q "dry-run mock" "$DONE/task-901-result.md"; then
    log_pass "Result file contains dry-run marker"
  else
    log_fail "Result file missing dry-run marker"
  fi
}

# --- Test 3: Gemini dry-run dispatch ---
test_gemini_dispatch() {
  log_test "Test 3: Gemini dry-run dispatch"

  # Create a frontend test task
  cat > "$INPROG/task-902.md" <<'EOF'
# task-902: E2E Test Frontend

## Objective
E2E smoke test for frontend dispatch.

## Technical Requirements
Create a test component.

## File Scope (only these files may be modified)
- src/components/Test.jsx
DO NOT modify: package.json, .env

## Acceptance Criteria
- [ ] Component renders correctly

## Assignee
frontend (Gemini)

## On Completion
Write result to tasks/done/task-902-result.md
EOF

  bash "$SCRIPT_DIR/scripts/assign_gemini.sh" "$INPROG/task-902.md"

  if [ -f "$DONE/task-902-result.md" ] && grep -q "dry-run mock" "$DONE/task-902-result.md"; then
    log_pass "Gemini dry-run produced mock result"
  else
    log_fail "Gemini dry-run failed"
  fi
}

# --- Test 4: status.sh ---
test_status() {
  log_test "Test 4: Status script"

  local output
  output=$(bash "$SCRIPT_DIR/scripts/status.sh" 2>&1)

  if echo "$output" | grep -q "Done (total):"; then
    log_pass "status.sh runs and shows pipeline info"
  else
    log_fail "status.sh output unexpected"
  fi
}

# --- Test 5: Config reader ---
test_config() {
  log_test "Test 5: Config reader (cfg function)"

  local val
  val=$(cfg "dry_run" "false")
  if [[ "$val" == "true" ]]; then
    log_pass "cfg reads dry_run=true correctly"
  else
    log_fail "cfg returned '$val' instead of 'true'"
  fi

  val=$(cfg "orchestrator.max_parallel" "1")
  if [[ "$val" == "3" ]]; then
    log_pass "cfg reads nested key correctly"
  else
    log_fail "cfg returned '$val' instead of '3'"
  fi

  val=$(cfg "nonexistent.key" "default_val")
  if [[ "$val" == "default_val" ]]; then
    log_pass "cfg returns default for missing key"
  else
    log_fail "cfg returned '$val' instead of 'default_val'"
  fi
}

# --- Run all tests ---
echo ""
echo "============================================"
echo " MultiAI-Collab E2E Smoke Test"
echo "============================================"
echo ""

setup
test_config
test_new_task
test_codex_dispatch
test_gemini_dispatch
test_status

echo ""
echo "============================================"
echo -e " Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, $TOTAL total"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
