# Pinned audit fix list

Tracked from the 2026-07-15 code audit. Check items off as they land.

## Critical (runtime breaks)

- [x] **District scene paths** — pointed `DISTRICT_SCENES` at `scenes/world/*.tscn` (`paw_vegas_hub`, etc.).
- [x] **Companion APIs** — added `get_unlocked_ids()`, `equip_companion()`, `unlock_random()`, `get_unlocked_count()`.
- [x] **FactionManager / QuestSystem not autoloaded** — registered `FactionManager`, `QuestSystem`, `NPCDialogueSystem` in `project.godot`.
- [x] **Legacy PlayerProfile APIs** — compat `selected_companion` / `selected_companion_race`, `set_active_companions`, `add_stat_modifier`, `unlock_ability`; quest currency → `EconomyManager`.
- [x] **EntityDexData.unlock_entity** — routes to `CompanionSystem.unlock_companion`.
- [x] **Psychology ↔ Supabase schema** — reads `event`/`context`; writes `player_anomalies` (migration `034`).
- [x] **Catsino `ENV_SETUP.md`** — restored from base64; points at migration `030` + service role key.

## Important gaps

- [x] **Arena modes** — each mode has a `scene`; hub launches real scenes (trial/playtest/combat/tournament/race) instead of luck-roll when present; added `duel` + `duel_2v2`. Simulate remains only as fallback.
- [x] **Combat realtime loot/stats** — player stats include mod; loot table + quantity-aware inventory grant.
- [x] **SceneLoader / AppConfig stubs** — SceneLoader actually `change_scene_to_file`; AppConfig exposes `main_menu_scene_path` + defaults.
- [x] **Hub `scene_path` metadata** — arlington → `hdv_lore/.../arlington.tscn`; other hubs → `supraliminal.tscn` until dedicated hubs exist.
- [x] **Smoke checks** — `python3 scripts/audit_smoke_check.py` (no Godot binary required).
- [x] **District visit achievement** — unlocks `district_explore` after 5 unique visits.

## Still open (content / infra)

- [ ] Arena *bespoke* gameplay (MOBA lanes, CTF yarn rules, zombie waves) — scenes are shared pits for now
- [ ] MetaHuman GLB assets (`character_rig.gd` still procedural until packs land)
- [ ] Nakama realtime live-tested against a real host
- [ ] Full gdUnit4 game suite (enable plugin + author tests)
- [ ] Content: dialogue trees, entity lore, art/audio packs

## Notes

- `InventorySystem` / `crafting_system.gd` / legacy `systems/combat_system.gd` were already gone after rebase onto latest base.
- Quest JSON loader fixed to use `FileAccess` instead of invalid `ResourceLoader.load(...).get_text()`.
- Apply `supabase/migrations/034_player_anomalies.sql` before deploying psychology.
