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

**MPFB2** (MakeHuman for Blender, CC0 asset packs) studio bake — textured
skin, high-poly eyes, teeth, brows/lashes, hair, shirt/pants/shoes:

| Slot | Role |
|---|---|
| `peri_human_player.glb` / `metahuman_player.glb` | Local player (MPFB male + wardrobe) |
| `peri_human_npc.glb` / `metahuman_npc.glb` | Default NPC (MPFB female + wardrobe) |
| `variants/metahuman_npc/*.glb` | Skin/hair/cloth color variants for crowds |
| `player_cat.glb` / `npc_cat.glb` | Catsino house skins |

Rebake: `python3 scripts/bake_mpfb_characters.py` (needs Blender 4.2 + MPFB
extension + CC0 packs; see script header). Fallback mesh bake remains in
`scripts/bake_visual_gaps.py`.

Runtime look-dev tunes Skin/Eye/Hair/Cloth (soft SSS/rim on Forward+;
MetaHumanGodot skin shader when surface names match).

### Optional cinema upgrade (owner trials)

Overwrite the same slot filenames with CC4 / MetaHuman / DAZ exports.
Players still only download the game. See `docs/PINNED_LEFT.md`.

## Cities = OSM2World futuristic DFW shells

`MegaCityBuilder` loads `osm2world_<hub>.glb` as the visual downtown when
present (dallas / fort_worth / arlington / denton). Layout JSON in
`world_data/osm/` stays the gameplay brain (streets, landmarks, venues).
Bake: `python3 scripts/bake_osm2world_cities.py` (Java + OSM2World + Blender).
Attribution: © OpenStreetMap contributors (ODbL) — see
`godot/world_data/osm/ATTRIBUTION.md`.

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

- `scripts/bake_mpfb_characters.py` — MPFB2 PeriHuman studio bake
- `scripts/bake_osm2world_cities.py` — OSM2World DFW shells
- `scripts/bake_visual_gaps.py` — cat / crystal / gap bake
- `docs/PINNED_LEFT.md` — pinned GOTY gates + owner trials
- `docs/ASSET_PIPELINE.md` — Blender → GLB
- `godot/assets/models/ATTRIBUTION.md` — licenses
