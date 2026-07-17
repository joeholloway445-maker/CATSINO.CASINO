# Pinned — circle back when asked “what’s left”

<<<<<<< HEAD
**Agent-finishable Gates 5–8 thicken (latest):** hideout sieges register
defenders into LayerWorld combat (hotbar + bites). Remaining agent juice:
combat SFX slots + boss phase telegraphs (in flight on PR #56 — do not
duplicate), Gate 8 RPC field-alias (`board_id` ↔ `leaderboard`) + smoke
thicken, Periliminal floor hazard VFX.
=======
**Agent-finishable Gates 5–8 thicken (latest):** Gate 8 `board_id`↔`leaderboard`
alias + thicker `gate8_smoke` (offline always; live find_match /
get_leaderboard / submit_score when docker is up).

Remaining agent juice: combat SFX slots + boss phase telegraphs (PR #56 —
do not duplicate), Periliminal floor hazard VFX/HUD, hideout siege combat
registration if PR #61 not yet merged.
>>>>>>> origin/claude/intelligent-fermi-yyigzo

Do **not** start the pinned owner trials below until the owner asks
what’s left.

## Pinned — owner trials only

Cinema-face upgrades beyond shipped MPFB2. Owner signs up / exports; drop
GLBs onto the same PeriHuman slots. Agents do not start these.

| Tool | Why | Action |
|---|---|---|
| **Reallusion Character Creator 4** (30-day trial) | Photoreal clothes/hair/skin beyond MPFB2 | Export GLB → overwrite `peri_human_*.glb` |
| **Unreal MetaHuman Creator** (free w/ Epic) | Cinema faces for same slots | UE → Blender → GLB into ship slots |
| **DAZ Studio + Genesis** (free + Interactive License) | Hyper-real humans | Private drop if redistribute forbidden |

Also owner-local (needs your machine / credentials — not cloud-agent work):

- **Terrain3D hand-sculpt** of hero regions (local GPU; plugin stays off in CI)
- **Production Nakama host** + real `server_config.json` secrets  
  Local path already exists: `scripts/build_nakama_modules.sh` +
  `docker compose -f docker-compose.dev.yml up -d` + `gate8_smoke`
- **gdUnit4 editor plugin** — enable locally only after a clean project
  open; keep `project.godot` `[editor_plugins] enabled=` empty for CI
- Optional: generate dedicated Suno beds for `ascension` / `sanctuary`
  (currently aliased to `noclip` / `taillights_fade`)

## Already finished (do not re-open)

- OSM2World DFW shells + MegaCityBuilder wiring
- MPFB2 PeriHuman studio bake
- Free path: **MPFB2** (CC0) + **OSM2World** (OSM ODbL)
- Arena HotbarUI + cast resolution (Gate 6)
<<<<<<< HEAD
- Hideout live WorldEntity siege + LayerWorld combat registration (Gate 5)
- PeriliminalGenerator real floors (Gate 6)
- StoryVote Nakama module + gate8 smoke thicken (Gate 8)
=======
- Hideout live WorldEntity siege (Gate 5)
- PeriliminalGenerator real floors (Gate 6)
- StoryVote Nakama module (Gate 8)
- Gate 8 board_id↔leaderboard alias + smoke thicken
>>>>>>> origin/claude/intelligent-fermi-yyigzo
