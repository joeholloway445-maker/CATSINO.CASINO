# Pinned — circle back when asked “what’s left”

**Active work:** finish GOTY gates 5–8 + remaining in-repo polish
(OSM road tiling, ambience/music/dialogue depth, game modes). Do **not**
start the pinned owner trials below until that pass is done and the owner
asks what’s left.

## Pinned — owner trials only

Cinema-face upgrades beyond shipped MPFB2. Owner signs up / exports; drop
GLBs onto the same PeriHuman slots. Agents do not start these.

| Tool | Why | Action |
|---|---|---|
| **Reallusion Character Creator 4** (30-day trial) | Photoreal clothes/hair/skin beyond MPFB2 | Export GLB → overwrite `peri_human_*.glb` |
| **Unreal MetaHuman Creator** (free w/ Epic) | Cinema faces for same slots | UE → Blender → GLB into ship slots |
| **DAZ Studio + Genesis** (free + Interactive License) | Hyper-real humans | Private drop if redistribute forbidden |

Also owner-local (needs your machine / credentials — not cloud-agent work):

- Terrain3D hand-sculpt of hero regions (local GPU; plugin stays off in CI)
- Production Nakama host + real `server_config.json` secrets (local docker
  defaults can be wired for smoke; live multiplayer needs your deploy)

## Already finished (do not re-open)

- OSM2World DFW shells + MegaCityBuilder wiring
- MPFB2 PeriHuman studio bake
- Free path: **MPFB2** (CC0) + **OSM2World** (OSM ODbL)
