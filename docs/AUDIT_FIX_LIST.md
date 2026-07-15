# Pinned audit fix list

Tracked from the 2026-07-15 code audit. Check items off as they land.

## Critical (runtime breaks)

- [x] **District scene paths** — pointed `DISTRICT_SCENES` at `scenes/world/*.tscn` (`paw_vegas_hub`, etc.).
- [x] **Companion APIs** — added `get_unlocked_ids()`, `equip_companion()`, `unlock_random()` on `companion_system.gd`.
- [x] **FactionManager / QuestSystem not autoloaded** — registered `FactionManager`, `QuestSystem`, `NPCDialogueSystem` in `project.godot`.
- [x] **Legacy PlayerProfile APIs** — compat `selected_companion` / `selected_companion_race`, `set_active_companions`, `add_stat_modifier`, `unlock_ability`; quest currency → `EconomyManager`.
- [x] **EntityDexData.unlock_entity** — routes to `CompanionSystem.unlock_companion`.
- [x] **Psychology ↔ Supabase schema** — reads `event`/`context`; writes `player_anomalies` (migration `034`).
- [x] **Catsino `ENV_SETUP.md`** — restored from base64; points at migration `030` + service role key.

## Important (gaps, not hard crashes — still open)

- [ ] Arena modes mostly simulated (`arena_hub_ui.gd`)
- [ ] Combat realtime placeholder stats / loot TODO
- [ ] MetaHuman assets still procedural (`character_rig.gd`)
- [ ] `src/stubs/` no-ops (latent until maaacks enabled)
- [ ] Nakama realtime not live-tested
- [ ] No game test suite under `godot/test/`
- [ ] Content: dialogue trees, entity lore, art packs

## Notes

- `InventorySystem` / `crafting_system.gd` / legacy `systems/combat_system.gd` were already gone after rebase onto latest base — no rewire needed there.
- Quest JSON loader fixed to use `FileAccess` instead of invalid `ResourceLoader.load(...).get_text()`.
