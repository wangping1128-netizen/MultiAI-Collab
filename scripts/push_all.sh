#!/bin/bash
# =============================================================================
# push_all.sh - Push configured branch to all configured remotes
#
# Usage:
#   bash scripts/push_all.sh
#   bash scripts/push_all.sh --force
# =============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/config.sh"

FORCE_PUSH=false

usage() {
  echo "Usage: bash scripts/push_all.sh [--force]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE_PUSH=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

REMOTES="$(cfg "git.remotes" "")"
BRANCH="$(cfg "git.branch" "master")"

if [[ -z "$REMOTES" ]]; then
  echo "ERROR: No remotes configured. Set git.remotes in config.json." >&2
  exit 1
fi

if [[ "$FORCE_PUSH" == "true" ]]; then
  echo "Force push requested for branch '$BRANCH' to remotes: $REMOTES"
  read -rp "Type 'yes' to continue: " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo "Aborted. Force push cancelled."
    exit 1
  fi
fi

FAILED=0

for remote in $REMOTES; do
  echo "----------------------------------------"
  echo "Pushing branch '$BRANCH' to remote '$remote'..."

  if [[ "$FORCE_PUSH" == "true" ]]; then
    if git push --force "$remote" "$BRANCH"; then
      echo "Status: OK ($remote)"
    else
      echo "Status: FAILED ($remote)" >&2
      FAILED=$((FAILED + 1))
    fi
  else
    if git push "$remote" "$BRANCH"; then
      echo "Status: OK ($remote)"
    else
      echo "Status: FAILED ($remote)" >&2
      FAILED=$((FAILED + 1))
    fi
  fi
done

echo "----------------------------------------"
if [[ "$FAILED" -gt 0 ]]; then
  echo "Push completed with $FAILED failure(s)." >&2
  exit 1
fi

echo "Push completed successfully for all remotes."
