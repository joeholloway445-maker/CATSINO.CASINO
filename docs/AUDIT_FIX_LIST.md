# Pinned audit fix list

Tracked from the 2026-07-15 code audit. Check items off as they land.

## Critical (runtime breaks)

- [x] **District scene paths** — pointed `DISTRICT_SCENES` at `scenes/world/*.tscn` (`paw_vegas_hub`, etc.).
- [x] **Companion APIs** — added `get_unlocked_ids()`, `equip_companion()`, `unlock_random()`, `get_unlocked_count()`.
- [x] **FactionManager / QuestSystem not autoloaded** — registered `FactionManager`, `QuestSystem`, `NPCDialogueSystem` in `project.godot`.
- [x] **Legacy PlayerProfile APIs** — compat getters + EconomyManager quest rewards.
- [x] **EntityDexData.unlock_entity** — routes to `CompanionSystem.unlock_companion`.
- [x] **Psychology ↔ Supabase schema** — `event`/`context` + `player_anomalies` (migration `034`).
- [x] **Catsino `ENV_SETUP.md`** — restored; migration `030` + service role key.

## Important gaps

- [x] **Arena modes** — `ArenaModeController`: survival shrink zone, feral waves, CTF yarn deliver, duel/2v2 staged foes; hub launches playtest arena with queued mode.
- [x] **Combat realtime loot/stats** — mod-aware stats; quantity-aware loot.
- [x] **SceneLoader / AppConfig stubs** — real scene load + `main_menu_scene_path`.
- [x] **Hub `scene_path` metadata** — arlington hub + supraliminal fallbacks.
- [x] **Smoke checks** — `python3 scripts/audit_smoke_check.py`.
- [x] **Dialogue trees** — barista / archivist / authority JSON; FileAccess loader; fixed empty-options bug in `choose_dialogue_option`.
- [x] **MetaHuman hook** — `MetahumanCharacter.resolve_tier()`; interim `player_human.glb` documented; shaders present.
- [x] **gdUnit4 audit suites** — `godot/test/audit/*.gd` (enable gdUnit4 plugin to run).

## Still open (content / infra)

- [ ] Full MOBA lane-push / tournament AI (still uses tournament lobby)
- [ ] Drop real MetaHuman GLBs into `assets/models/metahuman_*.glb`
- [ ] Nakama realtime live-tested against a real host
- [ ] Enable gdUnit4 in `project.godot` after zero-error editor open
- [ ] Remaining archetypes (lover, reflection) + full layer dialogue coverage
- [ ] Art/audio pack wiring via AssetLibrary

## Notes

- Apply `supabase/migrations/034_player_anomalies.sql` before deploying psychology.
- Enable gdUnit4 only after a clean Godot smoke open (`docs/ADDONS.md`).
