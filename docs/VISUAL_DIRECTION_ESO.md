# Visual direction: realistic ESO bar + shipped PeriHumans

**Why early screenshots looked ugly:** zero character/environment GLBs —
orange capsules, box cities, flat ground.

**Locked direction for AAA GOTY v0.1:** Elder Scrolls Online–class realism
on desktop where possible; **players never install Unreal, MakeHuman, or
any third-party character tool**. PeriHumans ship as GLBs in the build.

## Characters = PeriHumans (shipped)

`MetahumanCharacter` resolves:

`peri_human_*` / `metahuman_*` → `player_human` / `npc_human` →
`CharacterRig` last resort. Catsino cat mode uses `player_cat` / `npc_cat`.

### What ships today (no player setup)

Blender Studio **Human Base Meshes** (**CC0**), rebaked with hair + clothes:

| Slot | Role |
|---|---|
| `peri_human_player.glb` / `metahuman_player.glb` | Local player (realistic male + hair/shirt/pants/shoes) |
| `peri_human_npc.glb` / `metahuman_npc.glb` | Default NPC (realistic female + hair/clothes) |
| `variants/metahuman_npc/*.glb` | Skin/hair/cloth color variants for crowds |
| `player_cat.glb` / `npc_cat.glb` | Catsino house skins |

Rebake: `blender -b -P scripts/bake_visual_gaps.py` (see script header paths).

Runtime look-dev tunes Skin/Eye/Hair/Cloth (soft SSS/rim on Forward+;
MetaHumanGodot skin shader when surface names match).

### Studio-only photoreal upgrade (optional)

Overwrite the same slot filenames with MakeHuman / CC4 / MetaHuman exports.
Players still only download the game. See `docs/ASSET_PIPELINE.md`.

## Terrain = Terrain3D (desktop) / ProceduralTerrain (web)

Multi-layer height (continental + ridge + detail) with a soft spawn plaza.
PBR grass/dirt/sand maps on both backends. Terrain3D editor sculpt remains
a local-GPU authoring step (plugin stays disabled in CI).

## Lighting / sky

Desktop Forward+ + HDRI IBL (`kloppenheim_06_1k.hdr`); mobile/web
`gl_compatibility` with procedural sky fallback.

## World props

Filled: trees, rocks, **faceted crystals**, ruins, gates, furniture,
**Quaternius creatures**, **aircraft (Bob)**, neon, doors, cats.

## Related

- `scripts/bake_visual_gaps.py` — PeriHuman / cat / crystal bake
- `docs/ASSET_PIPELINE.md` — Blender → GLB
- `godot/assets/models/ATTRIBUTION.md` — licenses
