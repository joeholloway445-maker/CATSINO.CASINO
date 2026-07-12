# Visual direction: realistic ESO bar

**Why the screenshots looked ugly:** the game had **zero character/environment
GLBs**. Controllers fell back to an orange capsule “cat,” cities were box
meshes, and ground was a flat noise plane on `gl_compatibility`. That was a
graybox, not the art direction.

**Locked direction for AAA GOTY v0.1:** Elder Scrolls Online–class realism —
human(oid) MetaHumans, sculpted terrain, Forward+ lighting on desktop.

## Characters = MetaHumans (Godot runtime)

Epic now licenses finished MetaHumans for use outside Unreal (Unity/Godot).
Authoring still happens in **Unreal MetaHuman Creator** (UE 5.6+). This repo
does **not** ship MetaHuman binary assets (you bring your own exports).

### Pipeline (you run this once per hero / race)

1. Create or Mesh-to-MetaHuman in Unreal 5.6+.
2. Export → Blender (ARKit morph bake if needed — see
   [MetaHumanGodot](https://github.com/ibrews/MetaHumanGodot) / Capafy pipeline).
3. Export **GLB** into:
   - `godot/assets/models/metahuman_player.glb` — local player
   - `godot/assets/models/metahuman_npc.glb` — peers / NPCs
   - optional `metahuman_<race_id>.glb` per Identity race
4. Open the project in Godot **Forward+**. Skin/eye/hair look-dev shaders are
   vendored under `godot/assets/shaders/metahuman/` (community MetaHumanGodot,
   MIT / not Epic-affiliated).

### Runtime resolver

`MetahumanCharacter` (`godot/src/character/metahuman_character.gd`):

`metahuman_*` → `player_human` / `npc_human` (interim TPS demo mesh) →
`CharacterRig` procedural last resort.

Orange capsules are **gone** from the default path.

### Interim mesh (until your MetaHumans land)

MIT Godot TPS demo player is staged as `player_human.glb` / `npc_human.glb`
so layers already show a real humanoid, not a capsule. Replace these files
with MetaHuman exports without code changes.

## Terrain = Terrain3D (desktop) / ProceduralTerrain (web)

| Target | Backend |
|---|---|
| Desktop / native AAA | **Terrain3D** v1.0.0 (Godot 4.3 GDExtension) in `addons/terrain_3d/` |
| Web export | `ProceduralTerrain` (TerrainBridge falls back automatically) |

`TerrainBridge` + `TerrainWorld` generate a noise heightfield with grass/dirt
auto-shader when Terrain3D’s classes are present.

Sculpt hero regions in the editor (Terrain3D tools), or import World
Machine / Gaea heightmaps — see Terrain3D docs.

## Renderer

| Platform | Method |
|---|---|
| Desktop | `forward_plus` (SSAO / SSIL / volumetric fog / glow) |
| Mobile / Web | `gl_compatibility` |

## What you still drop in by hand

- MetaHuman GLBs (above)
- City kits → `city_tower.glb`, etc. (`docs/SHIPPING.md` §3)
- PBR ground textures into Terrain3D texture assets / `assets/terrain/`
- HDRI (optional) for studio-quality reflection probes

## Related

- `docs/V01_GOTY.md` — goal lock
- `docs/ADDONS.md` — Terrain3D native-only note (web fallback kept)
- `godot/assets/models/ATTRIBUTION.md` — interim mesh licenses
