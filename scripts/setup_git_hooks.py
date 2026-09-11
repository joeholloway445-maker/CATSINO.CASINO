#!/usr/bin/env python3
"""Install repository git hooks (pre-push static quality gates).

Usage:
    python scripts/setup_git_hooks.py
"""
import os
import stat
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GIT_DIR = ROOT / ".git"
HOOKS_DIR = GIT_DIR / "hooks"


def install_pre_push():
    if not GIT_DIR.exists():
        print(f"Error: {GIT_DIR} does not exist. Not a git root?")
        return 1

    HOOKS_DIR.mkdir(parents=True, exist_ok=True)
    pre_push_file = HOOKS_DIR / "pre-push"

    content = """#!/usr/bin/env bash
# Pre-push static smoke check gate for Periliminal.Space
set -e
echo "[pre-push] Running audit_smoke_check.py static quality gate..."
if command -v python3 >/dev/null 2>&1; then
    python3 scripts/audit_smoke_check.py
elif command -v python >/dev/null 2>&1; then
    python scripts/audit_smoke_check.py
else
    echo "Warning: Python not found on PATH, skipping smoke check."
fi
"""
    pre_push_file.write_text(content, encoding="utf-8")
    
    # Make executable on POSIX systems
    try:
        current_perms = os.stat(pre_push_file).st_mode
        os.chmod(pre_push_file, current_perms | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    except Exception:
        pass

    print(f"Successfully installed pre-push hook at: {pre_push_file}")
    return 0


if __name__ == "__main__":
    sys.exit(install_pre_push())
