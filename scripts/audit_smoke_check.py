#!/usr/bin/env python3
"""Path/API smoke checks for audit fixes — no Godot binary required.

Run from repo root:  python3 scripts/audit_smoke_check.py
Exit 0 = all critical paths resolve.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "godot"
failures: list[str] = []


def ok(msg: str) -> None:
    print(f"  OK  {msg}")


def fail(msg: str) -> None:
    failures.append(msg)
    print(f" FAIL {msg}")


def check_exists(rel: str, label: str) -> None:
    path = GODOT / rel.removeprefix("res://")
    if path.exists():
        ok(f"{label}: {rel}")
    else:
        fail(f"{label} missing: {rel} → {path}")


def extract_string_consts(gd_text: str, dict_name: str) -> list[str]:
    """Pull quoted res:// paths from a named Dictionary/const block."""
    # crude but good enough for DISTRICT_SCENES / scene= fields
    paths = re.findall(r'"(res://[^"]+\.tscn)"', gd_text)
    return paths


def main() -> int:
    print("== district scenes ==")
    dm = (GODOT / "src/world/district_manager.gd").read_text()
    for path in extract_string_consts(dm, "DISTRICT_SCENES"):
        if "districts/" in path and path.endswith(".tscn"):
            fail(f"stale districts/ path still present: {path}")
        elif "/music/" in path or path.endswith(".ogg") or path.endswith(".mp3"):
            continue
        else:
            check_exists(path, "district")

    print("== arena mode scenes ==")
    am = (GODOT / "src/data/arena_modes.gd").read_text()
    for path in extract_string_consts(am, "MODES"):
        check_exists(path, "arena")
    for mode_id in ("duel", "duel_2v2"):
        if f'id="{mode_id}"' in am or f"id=\"{mode_id}\"" in am:
            ok(f"mode registered: {mode_id}")
        else:
            fail(f"mode missing: {mode_id}")

    print("== hub scene_paths ==")
    hubs = (GODOT / "src/data/hub_region_data.gd").read_text()
    for path in extract_string_consts(hubs, "HUBS"):
        check_exists(path, "hub")
    if "scenes/worlds/hubs/dallas" in hubs:
        fail("hub still points at missing scenes/worlds/hubs/dallas")
    else:
        ok("no stale worlds/hubs/dallas path")

    print("== companion API surface ==")
    cs = (GODOT / "src/companion/companion_system.gd").read_text()
    for fn in ("get_unlocked_ids", "equip_companion", "unlock_random"):
        if f"func {fn}" in cs:
            ok(f"companion_system.{fn}")
        else:
            fail(f"companion_system missing {fn}")

    print("== autoloads ==")
    pg = (GODOT / "project.godot").read_text()
    for name in ("FactionManager=", "QuestSystem=", "NPCDialogueSystem="):
        if name in pg:
            ok(f"autoload {name.rstrip('=')}")
        else:
            fail(f"autoload missing {name.rstrip('=')}")

    print("== stubs ==")
    sl = (GODOT / "src/stubs/scene_loader_stub.gd").read_text()
    if "change_scene_to_file" in sl:
        ok("SceneLoader stub loads scenes")
    else:
        fail("SceneLoader stub still no-ops")
    ac = (GODOT / "src/stubs/app_config_stub.gd").read_text()
    if "main_menu_scene_path" in ac:
        ok("AppConfig has main_menu_scene_path")
    else:
        fail("AppConfig missing main_menu_scene_path")

    print("== psychology / env ==")
    psych = (ROOT / "services/psychology/main.py").read_text()
    if 'r.get("event")' in psych and "player_anomalies" in psych:
        ok("psychology reads event + writes player_anomalies")
    else:
        fail("psychology schema alignment incomplete")
    if (ROOT / "supabase/migrations/034_player_anomalies.sql").exists():
        ok("migration 034 present")
    else:
        fail("migration 034 missing")
    env = (ROOT / "apps/catsino-casino/ENV_SETUP.md").read_text()
    if "SUPABASE_SERVICE_ROLE_KEY" in env and "030_catsino" in env:
        ok("catsino ENV_SETUP restored")
    else:
        fail("catsino ENV_SETUP still broken")

    print()
    if failures:
        print(f"{len(failures)} failure(s)")
        for f in failures:
            print(f"  - {f}")
        return 1
    print("all smoke checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
