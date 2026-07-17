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
    for mode_id in ("duel", "duel_2v2", "moba"):
        if f'id="{mode_id}"' in am or f'id=\\"{mode_id}\\"' in am:
            ok(f"mode registered: {mode_id}")
        else:
            fail(f"mode missing: {mode_id}")
    if 'id="moba"' in am and "playtest_arena.tscn" in am:
        # Ensure moba isn't still hard-wired only to tournament.tscn as its scene.
        moba_line = [ln for ln in am.splitlines() if 'id="moba"' in ln]
        if moba_line and "playtest_arena" in moba_line[0]:
            ok("moba launches playtest_arena")
        else:
            fail("moba scene still not playtest_arena")

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

    print("== dialogue trees ==")
    archetypes = ("barista", "archivist", "authority", "lover", "reflection")
    layers = (
        "subliminal",
        "liminal",
        "supraliminal",
        "hyperliminal",
        "extraliminal",
        "periliminal",
    )
    for npc in archetypes:
        check_exists(f"src/dialogue/{npc}.json", "dialogue")
    print("== per-layer dialogue variants ==")
    for arch in archetypes:
        for layer in layers:
            check_exists(f"src/dialogue/{arch}_{layer}.json", "dialogue_layer")
    lib = (GODOT / "src/world/npc_dialogue_library.gd").read_text()
    social = (GODOT / "src/social/npc_dialogue_system.gd").read_text()
    if "_resolve_npc_key" in social and (
        "LayerManager.current_layer_id" in social or 'get("current_layer_id")' in social
    ):
        ok("NPCDialogueSystem resolves by current layer")
    else:
        fail("NPCDialogueSystem missing layer-aware resolve")
    if "src/dialogue/%s_%s.json" in lib or 'src/dialogue/%s_%s.json' in lib:
        ok("NpcDialogueLibrary prefers layer JSON")
    else:
        fail("NpcDialogueLibrary missing layer JSON preference")
    if (ROOT / "scripts/export_layer_dialogue.py").exists():
        ok("export_layer_dialogue.py present")
    else:
        fail("export_layer_dialogue.py missing")
    check_exists("src/core/autoload_gate.gd", "autoload_gate")
    check_exists("src/dev/dialogue_layer_smoke.gd", "dialogue_smoke")
    oc = (GODOT / "src/games/offline_casino.gd").read_text()
    if re.search(r"\bEconomyManager\.(get_|spend_|earn_|claim_)", oc) or re.search(
        r"\bif\s+not\s+EconomyManager\b|\bif\s+EconomyManager\b", oc
    ):
        fail("OfflineCasino still bare-refs EconomyManager autoload")
    else:
        ok("OfflineCasino uses _autoload for EconomyManager")
    mm = (GODOT / "src/audio/music_manager.gd").read_text()
    if "_import_binary_ready" in mm or "import_binary_ready" in mm:
        ok("MusicManager guards unimported audio")
    else:
        fail("MusicManager missing import-ready guard")
    for rel, needle, label in (
        ("src/data/entity_dex_data.gd", "AutoloadGate.get_node(\"CompanionSystem\")", "EntityDexData"),
        ("src/skills/skill_vfx.gd", "AutoloadGate.get_node(\"IdentityLens\")", "SkillVFX"),
        ("src/blueprints/blueprint_data.gd", "AutoloadGate.get_node(\"PlayerProfile\")", "BlueprintData"),
        ("src/layers/perception_system.gd", "AutoloadGate.get_node(\"PlayerProfile\")", "PerceptionSystem"),
        ("src/world/zone_boss_spawner.gd", "AutoloadGate.get_node(\"PlayerProfile\")", "ZoneBossSpawner"),
    ):
        txt = (GODOT / rel).read_text()
        if needle in txt:
            ok(f"{label} uses AutoloadGate")
        else:
            fail(f"{label} still bare-refs autoload")

    print("== arena mode controller ==")
    check_exists("src/world/arena_mode_controller.gd", "arena_ctrl")
    pa = (GODOT / "src/world/playtest_arena.gd").read_text()
    if "ArenaModeController" in pa:
        ok("playtest_arena attaches ArenaModeController")
    else:
        fail("playtest_arena missing ArenaModeController")

    print("== moba lane AI + shop ==")
    for rel in (
        "src/world/moba/moba_match.gd",
        "src/world/moba/moba_tower.gd",
        "src/world/moba/moba_minion.gd",
        "src/world/moba/moba_hero_bot.gd",
        "src/world/moba/moba_shop.gd",
        "src/world/moba/moba_shop_ui.gd",
        "src/world/moba/moba_hud.gd",
        "src/world/moba/moba_fx.gd",
    ):
        check_exists(rel, "moba")
    amc = (GODOT / "src/world/arena_mode_controller.gd").read_text()
    if "MobaMatch" in amc and "_setup_moba" in amc:
        ok("ArenaModeController wires MobaMatch")
    else:
        fail("ArenaModeController missing MobaMatch wiring")
    shop = (GODOT / "src/world/moba/moba_shop.gd").read_text()
    if "claw_edge" in shop and "func buy" in shop and "func sell" in shop:
        ok("MobaShop has catalog + buy/sell")
    else:
        fail("MobaShop catalog/buy/sell incomplete")
    match_src = (GODOT / "src/world/moba/moba_match.gd").read_text()
    for needle, label in (
        ("_begin_recall", "recall"),
        ("at_fountain", "fountain shop gate"),
        ("Kind.INHIBITOR", "inhibitors"),
        ("_do_respawn", "respawn"),
        ("_spawn_companion", "companion summon"),
        ("grant_xp_near", "XP radius"),
    ):
        if needle in match_src:
            ok(f"moba detail: {label}")
        else:
            fail(f"moba missing detail: {label}")

    print("== online moba ==")
    check_exists("src/world/moba/moba_online_client.gd", "moba_online")
    check_exists("src/networking/nakama_modules/moba_match.ts", "moba_match_ts")
    idx = (GODOT / "src/networking/nakama_modules/index.ts").read_text()
    if "register_moba_match" in idx:
        ok("Nakama index registers moba_match")
    else:
        fail("Nakama index missing register_moba_match")
    hub = (GODOT / "src/ui/arena_hub_ui.gd").read_text()
    if "find_moba_match" in hub and "_launch_moba" in hub:
        ok("Arena hub queues find_moba_match")
    else:
        fail("Arena hub missing online moba queue")
    amc2 = (GODOT / "src/world/arena_mode_controller.gd").read_text()
    if "MobaOnlineClient" in amc2 and "moba_online_match_id" in amc2:
        ok("ArenaModeController starts MobaOnlineClient")
    else:
        fail("ArenaModeController missing online moba path")

    print("== metahuman / PeriHuman slots ==")
    if (GODOT / "assets/models/player_human.glb").exists():
        ok("player_human.glb present (interim identity mesh)")
    else:
        fail("player_human.glb missing")
    for slot in (
        "peri_human_player.glb",
        "peri_human_npc.glb",
        "metahuman_player.glb",
        "metahuman_npc.glb",
    ):
        check_exists(f"assets/models/{slot}", "metahuman_slot")
    mh = (GODOT / "src/character/metahuman_character.gd").read_text()
    if "func resolve_tier" in mh:
        ok("MetahumanCharacter.resolve_tier")
    else:
        fail("resolve_tier missing")

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
    if (ROOT / "supabase/migrations/035_profiles_frame_default.sql").exists():
        ok("migration 035 present")
    else:
        fail("migration 035 missing")
    env = (ROOT / "apps/catsino-casino/ENV_SETUP.md").read_text()
    if "SUPABASE_SERVICE_ROLE_KEY" in env and "030_catsino" in env:
        ok("catsino ENV_SETUP restored")
    else:
        fail("catsino ENV_SETUP still broken")

    print("== offline casino + hyperliminal hub ==")
    check_exists("src/games/offline_casino.gd", "offline_casino")
    nm = (GODOT / "src/networking/network_manager.gd").read_text()
    if "OfflineCasino" in nm:
        ok("NetworkManager routes offline casino RPCs")
    else:
        fail("NetworkManager missing OfflineCasino fallback")
    rl = (GODOT / "src/layers/reality_layers.gd").read_text()
    if 'id="hyperliminal"' in rl and "paw_vegas_hub.tscn" in rl:
        ok("hyperliminal exits to paw_vegas_hub")
    else:
        fail("hyperliminal still not paw_vegas_hub")
    if "main_menu.tscn" in rl.split("hyperliminal")[1].split("liminal")[0] if "hyperliminal" in rl else "":
        fail("hyperliminal still points at main_menu")
    dt = (GODOT / "src/world/district_transition.gd").read_text()
    if '"paw_vegas":' in dt and "paw_vegas_hub.tscn" in dt:
        ok("DistrictTransition paw_vegas → hub")
    else:
        fail("DistrictTransition paw_vegas still not hub")
    al = (GODOT / "src/core/asset_library.gd").read_text()
    if "looped: bool = false" in al or "looped := false" in al:
        ok("AssetLibrary.sound defaults to one-shot")
    else:
        fail("AssetLibrary.sound still force-loops all SFX")

    print("== all modes playable ==")
    oc = (GODOT / "src/games/offline_casino.gd").read_text()
    for rpc in (
        "draw_fortune",
        "buy_scratch_card",
        "predict_match",
        "submit_puzzle_score",
        "start_race",
        "play_holdem",
        "combat_action",
    ):
        if f'"{rpc}"' in oc:
            ok(f"OfflineCasino supports {rpc}")
        else:
            fail(f"OfflineCasino missing {rpc}")
    nm2 = (GODOT / "src/networking/network_manager.gd").read_text()
    if "RPC_ALIASES" in nm2 and "get_wallet" in nm2:
        ok("NetworkManager RPC aliases for economy/tournaments")
    else:
        fail("NetworkManager missing RPC aliases")
    poker_ts = (GODOT / "src/networking/nakama_modules/poker_rpc.ts").read_text()
    if "cardDicts" in poker_ts and "normalizeHeld" in poker_ts and "coins" not in poker_ts.replace("cat_coins", ""):
        # wallet_util uses coins — poker should import spendCoins not cat_coins
        pass
    if "cat_coins" in poker_ts:
        fail("poker_rpc still uses cat_coins")
    else:
        ok("poker_rpc uses shared coins wallet")
    if "wallet_util" in poker_ts or "spendCoins" in poker_ts:
        ok("poker_rpc uses wallet_util")
    else:
        fail("poker_rpc missing wallet_util")
    hub2 = (GODOT / "src/ui/arena_hub_ui.gd").read_text()
    if "find_match" in hub2 and "_launch_arena_mode" in hub2:
        ok("Arena hub queues non-MOBA modes online via find_match")
    else:
        fail("Arena hub missing online queue for non-MOBA modes")
    check_exists("scenes/games/arcade/holdem.tscn", "holdem_scene")
    check_exists("src/networking/nakama_modules/wallet_util.ts", "wallet_util")
    check_exists("src/ui/ui_nav.gd", "ui_nav")
    check_exists("src/ui/shop_scene_controller.gd", "shop_controller")
    mm = (GODOT / "src/ui/main_menu.gd").read_text()
    for scene in (
        "inventory.tscn",
        "combat_ui.tscn",
        "tournament.tscn",
        "shop.tscn",
        "settings.tscn",
        "quest.tscn",
    ):
        if scene in mm:
            ok(f"main menu links {scene}")
        else:
            fail(f"main menu missing {scene}")
    eco = (GODOT / "src/core/economy_manager.gd").read_text()
    if "OFFLINE_STARTER_COINS" in eco and "can_spend_coins" in eco:
        ok("EconomyManager seeds offline coins + spend helpers")
    else:
        fail("EconomyManager missing offline starter / spend helpers")
    if '"get_wallet"' in oc and '"find_match"' in oc:
        ok("OfflineCasino soft-paths wallet + matchmaking")
    else:
        fail("OfflineCasino missing soft-path RPCs")
    score_ts = (GODOT / "src/networking/nakama_modules/score_rpc.ts").read_text()
    if "registerRpc(\"submit_score\"" in score_ts or "registerRpc('submit_score'" in score_ts:
        fail("score_rpc still overwrites submit_score")
    else:
        ok("score_rpc no longer overwrites leaderboard RPCs")
    gf = (GODOT / "src/games/game_factory.gd").read_text()
    if "func get_game_catalog" in gf and "slot_machine.tscn" in gf:
        ok("GameFactory catalog exposes real scenes")
    else:
        fail("GameFactory catalog incomplete")
    gm = (GODOT / "src/core/game_manager.gd").read_text()
    if "scene_path" in gm and "change_scene_to_file" in gm:
        ok("GameManager.enter_game accepts scene paths")
    else:
        fail("GameManager.enter_game missing scene launch")
    lobby = (GODOT / "src/ui/game_lobby_ui.gd").read_text()
    if "entry.get(\"scene\"" in lobby or 'entry.get("scene"' in lobby:
        ok("GameLobbyUI launches catalog scenes")
    else:
        fail("GameLobbyUI drops catalog scene paths")
    pv = (GODOT / "src/world/paw_vegas_scene.gd").read_text()
    if "_ensure_scene_tree" in pv and "GameLobbyUI" in pv:
        ok("Paws Vegas builds lobby when hub tree is sparse")
    else:
        fail("Paws Vegas hub still requires missing nodes")
    bj = (GODOT / "scenes/games/arcade/blackjack.tscn").read_text()
    if "blackjack.gd" in bj and "DealBtn" in bj:
        ok("blackjack scene uses wired blackjack.gd")
    else:
        fail("blackjack scene still unwired")
    slots = (GODOT / "scenes/games/slots/slot_machine.tscn").read_text()
    if "slot_machine_ui.gd" in slots and "ResultLabel" in slots:
        ok("slot_machine uses OfflineCasino UI script")
    else:
        fail("slot_machine still mismatched paths")
    ag = (GODOT / "src/world/arcade_galaxy_scene.gd").read_text()
    if "_build_station_ui" in ag and "fortune_wheel.tscn" in ag:
        ok("Arcade Galaxy stations launch real games")
    else:
        fail("Arcade Galaxy stations still unwired")
    if "launch_district" in ag:
        fail("Arcade Galaxy still calls missing launch_district")
    else:
        ok("Arcade Galaxy play_cat_wheel fixed")
    amc_modes = (GODOT / "src/world/arena_mode_controller.gd").read_text()
    for mode in ("survival", "zombies", "ctf", "conflict", "duel"):
        if f'"{mode}"' in amc_modes or f"_{mode}" in amc_modes or f"_setup_{mode}" in amc_modes or f"_tick_{mode}" in amc_modes:
            ok(f"arena controller handles {mode}")
        else:
            # conflict uses _setup_conflict; survival uses _setup_survival
            if f"_setup_{mode}" in amc_modes or f"_tick_{mode}" in amc_modes or (mode == "duel" and "_setup_duel" in amc_modes):
                ok(f"arena controller handles {mode}")
            else:
                fail(f"arena controller missing {mode}")
    if "_setup_conflict" in amc_modes and "_hero_hp" in amc_modes:
        ok("arena modes share hero HP combat")
    else:
        fail("arena shared hero combat missing")
    cs = (GODOT / "src/combat/combat_system.gd").read_text()
    if "func quick_resolve" in cs:
        ok("CombatSystem.quick_resolve for tournaments")
    else:
        fail("CombatSystem.quick_resolve missing")
    for rel in (
        "scenes/games/arcade/fortune_wheel.tscn",
        "scenes/games/arcade/scratch_card.tscn",
        "scenes/games/arcade/coin_pusher.tscn",
        "scenes/games/arcade/cat_puzzle.tscn",
        "scenes/games/sports/paw_ball.tscn",
        "scenes/games/racing/race_track.tscn",
    ):
        check_exists(rel, "playable_scene")

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
