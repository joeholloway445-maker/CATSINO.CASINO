# Pinned — circle back when asked “what’s left”

**Owner trials: STARTED** (you asked). Agent kickoff shipped — see
`docs/OWNER_TRIALS.md`. Cloud cannot finish CC4/UE/DAZ exports, GPU sculpt,
or real prod secrets; those still need your machine.

Remaining agent juice (gates): Periliminal floor hazard VFX/HUD. Layer
presence + hideout siege combat + boss telegraphs + combat SFX + board_id
alias already on base.


## Owner trials — in progress

| Trial | Kickoff in repo | You still do |
|---|---|---|
| **CC4 / MetaHuman / DAZ** cinema faces | `scripts/install_cinema_face_drop.sh` + `verify_cinema_slots.sh` | Export GLBs → install |
| **Terrain3D** hero sculpt | `assets/terrain/hero/*.png` + TerrainWorld loader | Optional hand-sculpt overwrite |
| **Production Nakama** | `server_config.production.example.json` | Real host/key in gitignored `server_config.json` |
| **gdUnit4** local plugin | `enable_gdunit4_local.sh` / `disable_…` | Enable locally; never commit on |
| **Suno beds** ascension/sanctuary | Dedicated MP3s (not aliases) | Optional replace with new Suno cuts |

Cinema-face overwrite targets (same slots players already download):

| Tool | Action |
|---|---|
| **Reallusion Character Creator 4** | Export GLB → `install_cinema_face_drop.sh` |
| **Unreal MetaHuman Creator** | UE → Blender → GLB → same installer |
| **DAZ Studio + Genesis** | Private drop if redistribute forbidden |

Local proofs that already exist:

- Nakama: `scripts/build_nakama_modules.sh` +
  `docker compose -f docker-compose.dev.yml up -d` + `gate8_smoke`
- Terrain3D: plugin stays **off** in CI `project.godot`; enable in editor only

## Already finished (do not re-open)

- OSM2World DFW shells + MegaCityBuilder wiring
- MPFB2 PeriHuman studio bake
- Free path: **MPFB2** (CC0) + **OSM2World** (OSM ODbL)
- Arena HotbarUI + cast resolution (Gate 6)
- Hideout live WorldEntity siege + LayerWorld combat registration (Gate 5)
- PeriliminalGenerator real floors (Gate 6)
- StoryVote Nakama module (Gate 8)
- Gate 8 board_id↔leaderboard alias + smoke thicken
- Boss phase telegraphs — AOE ring / phase-3 column + PHASE label + signal (Gate 5/6)
- Gate 8 layer presence match + PresenceManager live join
- Combat SFX slots into SkillVFX / boss phases (Gate 5/7)
