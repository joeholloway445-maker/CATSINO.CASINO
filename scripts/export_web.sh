#!/usr/bin/env bash
# Export the Godot Web (HTML5) client to builds/html5/.
# Requires Godot 4.3+ with export templates installed
# (~/.local/share/godot/export_templates/4.3.stable/web_release.zip).
#
# Usage (from repo root):
#   bash scripts/export_web.sh
# Then serve:
#   bash scripts/serve_web.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
OUT="$ROOT/builds/html5"

if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "Godot binary not found (set GODOT=... or install godot on PATH)." >&2
  exit 1
fi

TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates/4.3.stable"
if [ ! -f "$TEMPLATE_DIR/web_release.zip" ]; then
  echo "Missing Web export templates at $TEMPLATE_DIR/web_release.zip" >&2
  echo "Download: https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz" >&2
  exit 1
fi

mkdir -p "$OUT"
cd "$ROOT/godot"
"$GODOT" --headless --import || true
set +e
"$GODOT" --headless --export-release "Web" "$OUT/index.html"
EXPORT_EXIT=$?
set -e

if [ ! -f "$OUT/index.html" ]; then
  echo "Web export failed — no $OUT/index.html (godot exit=${EXPORT_EXIT})" >&2
  exit 1
fi

echo "Web export OK → $OUT/"
ls -lah "$OUT" | head -30
echo "Serve with: bash scripts/serve_web.sh"
