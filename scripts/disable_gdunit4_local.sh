#!/usr/bin/env bash
# Restore CI-safe empty [editor_plugins] enabled= list.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
python3 - <<'PY'
from pathlib import Path
import re
p = Path("godot/project.godot")
text = p.read_text(encoding="utf-8")
text2, n = re.subn(
    r"; OWNER_TRIAL gdUnit4 local enable[^\n]*\nenabled=PackedStringArray\([^\)]*\)",
    "enabled=PackedStringArray()",
    text,
    count=1,
)
if n == 0:
    text2, n = re.subn(
        r'enabled=PackedStringArray\("res://addons/gdUnit4/plugin\.cfg"\)',
        "enabled=PackedStringArray()",
        text,
        count=1,
    )
if n == 0 and "enabled=PackedStringArray()" in text:
    print("already CI-safe (empty enabled=)")
else:
    p.write_text(text2, encoding="utf-8")
    print("disabled gdUnit4 — project.godot is CI-safe again")
PY
