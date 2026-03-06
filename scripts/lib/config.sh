#!/bin/bash
# =============================================================================
# config.sh - Shared config reader for all scripts
#
# Usage: source this file, then call cfg "path.to.key" [default]
#
#   source "$(dirname "$0")/lib/config.sh"
#   timeout=$(cfg "orchestrator.task_timeout" 600)
# =============================================================================

# Resolve project root (works from any script in scripts/ or scripts/lib/)
_CONFIG_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
_CONFIG_FILE="$_CONFIG_PROJECT_ROOT/config.json"

# Read a value from config.json using Node.js
# $1: dot-separated key path (e.g. "orchestrator.poll_interval")
# $2: default value if key not found or config missing
cfg() {
  local key_path="$1"
  local default="${2:-}"

  if [ ! -f "$_CONFIG_FILE" ]; then
    echo "$default"
    return 0
  fi

  local result
  result=$(CONFIG_PATH="$_CONFIG_FILE" KEY_PATH="$key_path" DEFAULT_VAL="$default" node -e "
    const fs = require('fs');
    try {
      const c = JSON.parse(fs.readFileSync(process.env.CONFIG_PATH, 'utf8'));
      const keys = process.env.KEY_PATH.split('.');
      let v = c;
      for (const k of keys) {
        if (v == null || typeof v !== 'object') { v = undefined; break; }
        v = v[k];
      }
      if (v === undefined || v === null || v === '') {
        process.stdout.write(process.env.DEFAULT_VAL);
      } else if (Array.isArray(v)) {
        process.stdout.write(v.join(' '));
      } else {
        process.stdout.write(String(v));
      }
    } catch(e) {
      process.stdout.write(process.env.DEFAULT_VAL);
    }
  " 2>/dev/null) || result="$default"

  echo "$result"
}
