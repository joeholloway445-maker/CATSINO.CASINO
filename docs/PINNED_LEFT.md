# Pinned — what’s left (circle back when asked)

**Studio-quality visual focus for this pass — DONE:**

- OSM2World futuristic DFW downtown shells (`osm2world_<hub>.glb`) wired into
  `MegaCityBuilder` for dallas / fort_worth / arlington / denton
- MPFB2 PeriHuman bake (skin, eyes, teeth, brows, lashes, hair, clothes,
  shoes) into `peri_human_*` / `metahuman_*` / `player_human` / `npc_human`

Rebuild recipes: `scripts/bake_osm2world_cities.py`,
`scripts/bake_mpfb_characters.py`.

Everything below is **pinned**. Do not start these until the owner asks
“what’s left.”

## Pinned GOTY gates (from `docs/V01_GOTY.md`)

| # | Gate | Why pinned |
|---|---|---|
| 5 | Combat / economy / hideout / casino / StoryVote in-engine pass | After visuals |
| 6 | Game modes: 2v2 → zone bosses → world bosses → dungeons → PvP campaigns | After Gate 5 |
| 7 | Content + art/audio packs (ambience loops, music, dialogue depth) | Parallelizable later |
| 8 | Real multiplayer beyond presence bots (Nakama) | Last |

## Pinned visual polish (after studio bake lands)

- Hand-sculpt Terrain3D hero regions on a local GPU (plugin stays off in CI)
- Tile Kenney `road_segment` / `sidewalk` GLBs onto OSM street graph (optional)
- Replace stylized Quaternius creatures with photoreal private drops if desired
- MetaHuman / CC4 wardrobe pass if owner completes trial exports

## Owner trial sign-ups (only if you want cinema faces beyond MPFB2)

| Tool | Why | Action |
|---|---|---|
| **Reallusion Character Creator 4** (30-day trial) | Photoreal clothes/hair/skin beyond MPFB2 | Export GLB → overwrite `peri_human_*.glb` |
| **Unreal MetaHuman Creator** (free w/ Epic) | Cinema faces for same slots | UE → Blender → GLB into ship slots |
| **DAZ Studio + Genesis** (free + Interactive License) | Hyper-real humans | Private drop if redistribute forbidden |

Free path already shipped: **MPFB2** (CC0) + **OSM2World** (OSM ODbL geometry).
