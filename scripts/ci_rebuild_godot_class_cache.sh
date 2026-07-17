#!/usr/bin/env bash
# Rebuild godot/.godot/global_script_class_cache.cfg without a full asset import.
#
# Godot 4.3 headless `--editor --quit-after 20` aborts first_scan_filesystem
# before global class_name registrations are written ("Scan thread aborted"),
# which then cascades into "Identifier X not declared" for every class_name
# during -s smokes / gdUnit. Need enough frames for the scan to finish.
#
# Usage (from repo root or any cwd):
#   bash scripts/ci_rebuild_godot_class_cache.sh [godot_dir]
# Exit 0 if cache exists afterwards; 1 otherwise.
set -euo pipefail

GODOT_DIR="${1:-godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/$GODOT_DIR"

mkdir -p .godot/editor .godot/imported

rebuild() {
  local frames="$1"
  local budget="$2"
  echo "Rebuilding class cache (quit-after=${frames}, timeout=${budget}s)..."
  # --path . keeps the project root explicit inside the container.
  timeout "$budget" godot --headless --path . --editor --quit-after "$frames" || true
  if [[ -f .godot/global_script_class_cache.cfg ]]; then
    local n
    n="$(grep -c '"class":' .godot/global_script_class_cache.cfg || true)"
    echo "Class cache ready (${n:-0} classes)."
    return 0
  fi
  return 1
}

if rebuild 200 180; then
  exit 0
fi
echo "First pass missed cache — retrying with more frames..."
if rebuild 1000 240; then
  exit 0
fi

echo "ERROR: .godot/global_script_class_cache.cfg still missing after editor warm-up." >&2
ls -la .godot 2>/dev/null || true
exit 1
