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

Quaternius Ultimate Modular Males (**CC0**) as:

| Slot | Role |
|---|---|
| `peri_human_player.glb` / `metahuman_player.glb` | Local player |
| `peri_human_npc.glb` / `metahuman_npc.glb` | Default NPC |
| `variants/metahuman_npc/*.glb` | Outfit variety for crowds |

Stylized humanoids with multiple outfits — readable people in the city,
**not** photoreal MetaHuman faces yet.

### Studio-only photoreal upgrade (optional, still zero player friction)

If we want closer to ESO faces later, **we** (not players) bake once:

1. MakeHuman / CC4 / Unreal MetaHuman → Blender → GLB
2. Overwrite the same slot filenames above
3. Ship the new build

Players still only download the game. See `docs/ASSET_PIPELINE.md`.

Skin/eye/hair look-dev shaders (for future photoreal bakes) live under
`godot/assets/shaders/metahuman/` (community MetaHumanGodot, MIT).

## Terrain = Terrain3D (desktop) / ProceduralTerrain (web)

| Target | Backend |
|---|---|
| Desktop / native AAA | **Terrain3D** v1.0.0 (Godot 4.3 GDExtension) in `addons/terrain_3d/` |
| Web export | `ProceduralTerrain` (TerrainBridge falls back automatically) |

`TerrainBridge` + `TerrainWorld` generate a noise heightfield with grass/dirt
auto-shader when Terrain3D’s classes are present.

## Renderer

| Platform | Method |
|---|---|
| Desktop | `forward_plus` (SSAO / SSIL / volumetric fog / glow) |
| Mobile / Web | `gl_compatibility` |

## Related

- `godot/AGENTS.md` — slot drop procedure for Ziva
- `docs/ASSET_PIPELINE.md` — Blender → GLB
- `godot/assets/models/ATTRIBUTION.md` — licenses
