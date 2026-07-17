# Pinned audit fix list

Tracked from the 2026-07-15 code audit. Check items off as they land.

## Critical (runtime breaks)

- [x] District scenes, companion APIs, autoloads, PlayerProfile, EntityDex unlock
- [x] Psychology schema + player_anomalies (034)
- [x] Catsino ENV_SETUP restored
- [x] Autoload/`class_name` collisions fixed for FactionManager/QuestSystem/NPCDialogueSystem

## Important gaps

- [x] Arena modes + ArenaModeController (survival/zombies/CTF/duel) + **MOBA lane prototype**
- [x] Combat loot/stats, stubs, hub paths, smoke checks
- [x] Dialogue: barista / archivist / authority / **lover / reflection**
- [x] MetaHuman `resolve_tier` + interim human GLB
- [x] gdUnit audit suites + CI headless path
- [x] Achievement trigger aliases + XP via XPManager.award_amount
- [x] EconomyManager init on offline boot
- [x] District music → MusicManager contexts
- [x] NotificationUI plays AssetLibrary UI SFX
- [x] MainMenu `class_name` collision with maaacks removed
- [x] profiles.frame default → skirmisher (migration **035**)
- [x] Offline casino resolvers (slots / blackjack / poker via OfflineCasino)
- [x] Hyperliminal exit → Paws Vegas hub; DistrictTransition path unified
- [x] Character creator / Continue Expedition persistence + spaced names
- [x] AssetLibrary one-shot SFX (ambience opt-in loop) + Hope telemetry soft-fail

## Still open (content / infra)

- [x] Full MOBA lane AI / item shop (`godot/src/world/moba/*` — towers/inhibs/nexus, wave types, bots, companion, fountain shop+sell, recall/respawn, XP/CS/KDA/HUD)
- [x] Online MOBA (Nakama `find_moba_match` / `moba_match` + `MobaOnlineClient`; Shift+click = practice)
- [x] All game modes playable offline path: arena modes (survival/zombies/CTF/duel/conflict), Paws Vegas lobby→catalog scenes, OfflineCasino (fortune/scratch/sports/puzzle/race), wired arcade UIs, slots UI, Arcade Galaxy stations, district Start CTAs (Neon Alley / Coliseum / Forest)
- [x] Online/offline parity: unified `coins` wallet, RPC success + card dicts + held_indices, fortune/scratch/race/puzzle/holdem/combat OfflineCasino mirrors, NetworkManager RPC aliases, arena find_match queue + score sync, no double-spend race/scratch
- [x] Everything-works pass: main-menu scene wiring, offline starter coins, shop/combat/tournament entry, OfflineCasino soft paths (wallet/matchmaking/quests), Nakama RPC dedupe, UI back navigation
- [x] MetaHuman/PeriHuman ship slots filled (MPFB2 CC0 → `peri_human_*.glb` / `metahuman_*.glb`); cinema Epic/CC4/DAZ upgrades = owner-only (see `PINNED_LEFT.md`)
- [x] Per-layer dialogue JSON variants (5×6 under `godot/src/dialogue/<arch>_<layer>.json`; `NPCDialogueSystem` resolves by `LayerManager.current_layer_id`; regenerate via `scripts/export_layer_dialogue.py`)
- [x] Broader art/audio pack drop-ins (city meshes + ambience via AssetLibrary; optional Suno beds = owner)
- [ ] Nakama realtime live-tested against a **production** host (local path ready: `scripts/build_nakama_modules.sh` + `docker-compose.dev.yml` + `gate8_smoke`)
- [ ] Enable gdUnit4 plugin in **local** editor after zero-error smoke open (`project.godot` keeps `[editor_plugins] enabled=` empty on purpose — CI hang risk)

## Notes

- Apply `034_player_anomalies.sql` and `035_profiles_frame_default.sql` on shared Supabase.
- `python3 scripts/audit_smoke_check.py` guards wiring without Godot.
- Offline casino mirrors Nakama payout tables in `godot/src/games/offline_casino.gd`.
- Owner-only leftovers live in `docs/PINNED_LEFT.md`.
- Headless CI: `scripts/ci_rebuild_godot_class_cache.sh` + `dialogue_layer_smoke`;
  `class_name` scripts must use `AutoloadGate` (not bare Autoload ids).
