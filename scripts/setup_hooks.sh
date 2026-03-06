#!/bin/bash
# =============================================================================
# setup_hooks.sh - Configure git to use repository-managed hooks
# =============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p .githooks
git config core.hooksPath .githooks

echo "Git hooks activated: core.hooksPath=.githooks"
