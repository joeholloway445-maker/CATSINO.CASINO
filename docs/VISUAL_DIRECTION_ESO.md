# Visual direction: realistic ESO bar + shipped PeriHumans

**Why early screenshots looked ugly:** zero character/environment GLBs —
orange capsules, box cities, flat ground.

**Locked direction for AAA GOTY v0.1:** Elder Scrolls Online–class realism
on desktop where possible; **players never install Unreal, MakeHuman, or
any third-party character tool**. PeriHumans ship as GLBs in the build.

## Characters = PeriHumans (shipped)

`MetahumanCharacter` resolves:

`peri_human_*` / `metahuman_*` → `player_human` / `npc_human` →
`CharacterRig` last resort.

### What ships today (no player setup)

Blender Studio **Human Base Meshes** (**CC0**), baked once into:

| Slot | Role |
|---|---|
| `peri_human_player.glb` / `metahuman_player.glb` | Local player (realistic male base) |
| `peri_human_npc.glb` / `metahuman_npc.glb` | Default NPC (realistic female base) |
| `variants/metahuman_npc/*.glb` | Skin/cloth color variants for crowds |

Realistic anatomy + simple clothes (game-safe). Runtime look-dev tunes
Skin/Eye/Hair/Cloth materials (soft SSS/rim on Forward+; MetaHumanGodot
skin shader when surface names match). Not MetaHuman skin-pore cinema
yet — clothing is still placeholder geometry.

### Studio-only photoreal upgrade (optional, still zero player friction)

If we want closer to ESO faces later, **we** (not players) bake once:

1. MakeHuman / CC4 / Unreal MetaHuman → Blender → GLB
2. Overwrite the same slot filenames above
3. Ship the new build

Players still only download the game. See `docs/ASSET_PIPELINE.md`.

Skin/eye/hair look-dev shaders live under
`godot/assets/shaders/metahuman/` (community MetaHumanGodot, MIT).

## Terrain = Terrain3D (desktop) / ProceduralTerrain (web)

| Target | Backend |
|---|---|
| Desktop / native AAA | **Terrain3D** v1.0.0 (Godot 4.3 GDExtension) in `addons/terrain_3d/` |
| Web export | `ProceduralTerrain` (TerrainBridge falls back automatically) |

`TerrainWorld` prefers AmbientCG / Poly Haven PBR maps for Terrain3D
grass/dirt. `ProceduralTerrain` UV-maps chunks and applies
`grass` / `dirt` / `sand` / `asphalt` texture slots by biome.

## Lighting / sky

| Platform | Method |
|---|---|
| Desktop | `forward_plus` + SSAO / SSIL / SSR / volumetric fog |
| Mobile / Web | `gl_compatibility` (glow + depth fog only) |

`DayNightSky` uses Poly Haven HDRI (`kloppenheim_06_1k.hdr`) for sky IBL
when present, with sun energy still cycling day→night. Falls back to the
procedural neon-dusk palette if the HDRI is missing.

## World props (filled CC0 slots)

Nature / furniture / castle kits fill `tree`, `rock`, `crystal` (interim
mushrooms), `ruin_pillar`, `extraction_gate`, `apartment_prop`,
`harvest_node`, `creature` (interim bear), `neon_sign`, `city_door`.
Variant pools scatter forests/ruins without cloning one mesh.

Still empty / stylized: `player_cat` / `npc_cat`, photoreal creatures,
`vehicle_aircraft_body`, true gem crystals.

## Related

- `godot/AGENTS.md` — slot drop procedure for agents
- `docs/ASSET_PIPELINE.md` — Blender → GLB
- `godot/assets/models/ATTRIBUTION.md` — licenses
