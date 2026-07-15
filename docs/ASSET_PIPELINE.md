# Asset pipeline — Blender → GLTF/GLB → Godot 4

How Periliminal.Space eats external art. Drop files into the slots below;
`AssetLibrary` picks them up with **zero code changes**.

## Golden rule

The ship target is **Web** (`gl_compatibility`). Prefer **CC0 / MIT** art
you can commit. Many "free" marketplaces forbid redistributing source files
in a public repo — those go in `godot/assets/private/` (gitignored) or a
private CI bucket, never a commit.

Details + license verdicts: [`ASSET_SHOPPING_LIST.md`](ASSET_SHOPPING_LIST.md).
Addon stack: [`ADDONS.md`](ADDONS.md).

## Import path (every DCC tool)

```
Source tool (DAZ / CC4 / MetaHuman / Meshy / Sketchfab / …)
    → Blender (clean mesh, LODs, apply scale, triangulate if needed)
    → Export GLB (embedded textures, Y-up, +Z forward Godot default)
    → Drop into godot/assets/models/<slot>.glb
    → Open project once so Godot reimports
```

Blender export checklist:
- Apply all transforms (`Ctrl-A`)
- Real-world scale (~2m human height)
- One armature root named clearly
- Prefer **glTF Binary (.glb)** with textures embedded
- Strip unused materials / unseen LODs for Web size

## Slot map (models)

| Slot file | Used for |
|---|---|
| `metahuman_player.glb` / `metahuman_npc.glb` | Photoreal humans (preferred) |
| `player_human.glb` / `npc_human.glb` | Interim humanoids |
| `player_cat.glb` / `npc_cat.glb` | Catsino house skins |
| `creature.glb` | Wild / PVXC creatures |
| `tree.glb` / `rock.glb` / `crystal.glb` | Liminal props |
| `city_tower` / `city_lowrise` / `city_house` / `city_industrial` | Structures |
| `road_segment` / `sidewalk` / `streetlight` / `city_prop` | City kit |
| `vehicle_car_body` / `vehicle_boat_body` / `vehicle_aircraft_body` / `vehicle_spacecraft_body` | Vehicles |
| `apartment_prop.glb` | Hideout furniture |
| `ruin_pillar` / `extraction_gate` / `harvest_node` | Layer props |

Variants: `godot/assets/models/variants/<slot>/*.glb` +
`godot/data/asset_variants.json`.

## Slot map (audio / UI / env)

| Path | Source in repo now |
|---|---|
| `assets/audio/<slot>.ogg` | Kenney Casino + Interface + UI (CC0) |
| `assets/ui/input_prompts/` | Kenney Input Prompts Touch + Keyboard (CC0) |
| `assets/shaders/{crt,vhs,dither}_overlay.gdshader` | Mood overlays (wired via `RealityBendOverlay`) |
| `assets/environments/*.hdr` | Poly Haven HDRI (CC0) — `kloppenheim_06_1k.hdr` |
| `assets/textures/<slot>_albedo.jpg` | Poly Haven PBR (already) |

## Free / trial sources (owner list)

Use these to feed multi-layer worlds (GTA detail × ESO/WoW scale × Marvel
epic) — always check license before commit:

| Source | Best for | Commit-safe? |
|---|---|---|
| **RenderPeople Free** | Photoreal scanned people | ❌ private only (no redistribute) |
| **DAZ Studio + free Genesis** | Customizable hyper-real humans | ⚠️ export + Interactive License |
| **Sketchfab free filter** | Characters, creatures, vehicles, buildings | ⚠️ per-model (CC0 ok) |
| **TurboSquid free** | People, cars, props, structures | ❌ usually no redistribute |
| **CGTrader free** | PBR humans/creatures/vehicles/arch | ❌ unless explicit CC0 |
| **Poly Haven** | PBR textures + HDRIs | ✅ CC0 — used |
| **Godot Asset Library** | Godot-ready packs (often stylized) | ✅ if MIT/CC0 |
| **itch.io (Godot tag)** | Characters / vehicles / envs | ✅ if MIT/CC0 |
| **Reallusion CC4 (30-day trial)** | Photoreal characters + clothing | ⚠️ verify export license |
| **Meshy / Tripo3D / Luma** | AI text/image → GLTF (all categories) | ⚠️ tier ownership terms |
| **Kenney / Quaternius** | Stylized city / vehicles / UI / SFX | ✅ CC0 — heavily used |
| **MetaHuman (UE Creator → GLB)** | ESO-bar humans | ✅ for engine use; keep exports out of public redistrib if Epic terms require |

## What not to duplicate

| Skip adding | Already covered by |
|---|---|
| Terrain3D on Web | `ProceduralTerrain` / `TerrainBridge` (Terrain3D stays native-only) |
| LimboAI | Beehave (GDScript BT) |
| GLoot as live inventory | `inventory_manager.gd` / `inventory_system.gd` (GLoot vendored for a *future* UI unifier only) |
| MarcoFazio Virtual Joystick as authority | `TouchControls` (floating stick + action buttons) |

## Private drop folder

Non-redistributable downloads go here (ignored by git):

```
godot/assets/private/
  characters/
  creatures/
  vehicles/
  structures/
  README.md   # committed — explains the folder
```

Export cleaned GLBs from private → public slots only when the license
allows redistribution, or ship them via a private release artifact.
