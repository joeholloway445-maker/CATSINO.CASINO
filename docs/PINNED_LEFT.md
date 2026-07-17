# Pinned — only owner-required leftovers

Agent-finishable Gates 5–8 + in-repo polish are **done**. Do not reopen
them for “more juice” unless something is broken. Circle back here only
when the owner asks “what’s left.”

## Owner-only (AI cannot finish these)

Cinema-face upgrades beyond shipped MPFB2. Owner signs up / exports; drop
GLBs onto the same PeriHuman slots.

| Tool | Why | Action |
|---|---|---|
| **Reallusion Character Creator 4** (30-day trial) | Photoreal clothes/hair/skin beyond MPFB2 | Export GLB → overwrite `peri_human_*.glb` |
| **Unreal MetaHuman Creator** (free w/ Epic) | Cinema faces for same slots | UE → Blender → GLB into ship slots |
| **DAZ Studio + Genesis** (free + Interactive License) | Hyper-real humans | Private drop if redistribute forbidden |

Also owner-local (needs your machine / credentials):

- **Terrain3D hand-sculpt** of hero regions (local GPU; plugin stays off in CI)
- **Production Nakama host** + real `server_config.json` secrets  
  Local path already exists: `scripts/build_nakama_modules.sh` +
  `docker compose -f docker-compose.dev.yml up -d` + `gate8_smoke`
- **gdUnit4 editor plugin** — enable locally only after a clean project
  open; keep `project.godot` `[editor_plugins] enabled=` empty for CI
- Optional: generate dedicated Suno beds for `ascension` / `sanctuary`
  (currently aliased to `noclip` / `taillights_fade`)

## Already finished (do not re-open)

- OSM2World DFW shells (Draco-free) + MegaCityBuilder fallback
- MPFB2 PeriHuman studio bake
- Gates 5–7 play-pass (chips casino, bosses, dungeons, dialogue, HUD)
- Gate 8 local docker path + headless smokes in CI
- Free path: **MPFB2** (CC0) + **OSM2World** (OSM ODbL)
