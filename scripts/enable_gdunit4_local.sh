#!/usr/bin/env bash
# Local-only: enable gdUnit4 in godot/project.godot for editor test runs.
# NEVER commit the result — CI hangs if editor plugins throw modals headless.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJ="$ROOT/godot/project.godot"
MARKER="; OWNER_TRIAL gdUnit4 local enable"

if grep -q 'res://addons/gdUnit4/plugin.cfg' "$PROJ"; then
  echo "gdUnit4 already listed in [editor_plugins] enabled="
  exit 0
fi

python3 - <<'PY'
from pathlib import Path
p = Path("godot/project.godot")
text = p.read_text(encoding="utf-8")
old = "enabled=PackedStringArray()"
new = (
    "; OWNER_TRIAL gdUnit4 local enable — run scripts/disable_gdunit4_local.sh before commit\n"
    'enabled=PackedStringArray("res://addons/gdUnit4/plugin.cfg")'
)
if old not in text:
    raise SystemExit("could not find enabled=PackedStringArray() in project.godot")
p.write_text(text.replace(old, new, 1), encoding="utf-8")
print("enabled gdUnit4 in project.godot (local only)")
PY

echo "Open Godot editor → Project → Project Settings → Plugins → confirm gdUnit4 On."
echo "Before any commit/push: bash scripts/disable_gdunit4_local.sh"
