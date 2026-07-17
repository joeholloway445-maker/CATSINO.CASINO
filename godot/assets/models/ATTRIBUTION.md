# Model & code attribution

| File | Source | License |
|---|---|---|
| `interim/tps_player.glb`, `player_human.glb` | [godotengine/tps-demo](https://github.com/godotengine/tps-demo) player model | **CC-BY 3.0** — assets Copyright (c) 2018 Juan Linietsky, Fernando Miguel Calabró (corrected: previously mislabeled MIT here; the demo's *code* is MIT, its *art assets* are CC-BY 3.0 per the demo's own LICENSE.md) |
| `rock.glb` | Terrain3D demo (Tokisan Games) | MIT |
| `rock_b.glb` | Terrain3D demo (Tokisan Games) | MIT |
| `vehicle_car_body.glb` (from `sedan.glb`) | [Kenney Car Kit](https://kenney.nl/assets/car-kit) | **CC0** |
| `vehicle_boat_body.glb` (from `boat-speed-a.glb`) | [Kenney Watercraft Kit](https://kenney.nl/assets/watercraft-kit) | **CC0** |
| `vehicle_spacecraft_body.glb` (from `craft_racer.glb`) | [Kenney Space Kit](https://kenney.nl/assets/space-kit) | **CC0** |
| `city_tower.glb` (from `building-skyscraper-c.glb`) | [Kenney City Kit (Commercial)](https://kenney.nl/assets/city-kit-commercial) | **CC0** |
| `city_lowrise.glb` (from `building-e.glb`) | [Kenney City Kit (Commercial)](https://kenney.nl/assets/city-kit-commercial) | **CC0** |
| `city_house.glb` (from `building-type-f.glb`) | [Kenney City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban) | **CC0** |
| `city_industrial.glb` (from `building-e.glb`) | [Kenney City Kit (Industrial)](https://kenney.nl/assets/city-kit-industrial) | **CC0** |
| `road_segment.glb` (from `road-straight.glb`) | [Kenney City Kit (Roads)](https://kenney.nl/assets/city-kit-roads) | **CC0** |
| `sidewalk.glb` (from `tile-low.glb`) | [Kenney City Kit (Roads)](https://kenney.nl/assets/city-kit-roads) | **CC0** |
| `streetlight.glb` (from `light-square.glb`) | [Kenney City Kit (Roads)](https://kenney.nl/assets/city-kit-roads) | **CC0** |
| `city_prop.glb` (from `planter.glb`) | [Kenney City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban) | **CC0** |
| `variants/city_tower/*.glb` (5 skyscrapers) | [Kenney City Kit (Commercial)](https://kenney.nl/assets/city-kit-commercial) | **CC0** |
| `variants/city_lowrise/*.glb` (6 buildings) | [Kenney City Kit (Commercial)](https://kenney.nl/assets/city-kit-commercial) | **CC0** |
| `variants/city_house/*.glb` (8 houses) | [Kenney City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban) | **CC0** |
| `variants/city_industrial/*.glb` (8 buildings) | [Kenney City Kit (Industrial)](https://kenney.nl/assets/city-kit-industrial) | **CC0** |
| `variants/city_prop/*.glb` (planter + 2 tree sizes) | [Kenney City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban) | **CC0** |
| `variants/vehicle_car_body/*.glb` (sedan/sedan-sports/taxi/suv/police) | [Kenney Car Kit](https://kenney.nl/assets/car-kit) | **CC0** |
| `variants/vehicle_spacecraft_body/*.glb` (racer + 4 speeders) | [Kenney Space Kit](https://kenney.nl/assets/space-kit) | **CC0** |
| `tree.glb` (from `tree-large.glb`) | [Kenney City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban) | **CC0** |
| `godot/src/world/overworld/third_person_controller.gd` | Movement/camera physics pattern adapted from godotengine/tps-demo's `player/player.gd` (single-player rewrite, gun-robot/multiplayer scaffolding removed; ability-kit hotbar and cat/identity visual-mode switching are original) | MIT (code) |
| `godot/src/vehicles/land_vehicle.gd` | Steering/throttle model adapted from the official [godotengine/godot-demo-projects](https://github.com/godotengine/godot-demo-projects) `3d/truck_town` sample's `vehicles/vehicle.gd` (whole-repo MIT, no split code/asset license unlike tps-demo) — rewritten for our input map, procedural placeholder body/wheels, and VehicleSeat enter/exit instead of their multi-vehicle trailer/tow-truck rig | MIT (code) |
| `godot/src/vehicles/water_vehicle.gd`, `air_vehicle.gd`, `space_vehicle.gd` | Original — no equivalent official Godot demo exists for buoyancy or flight (unlike VehicleBody3D for land, Godot has no built-in boat/aircraft physics node), so these are from-scratch arcade models | MIT (code) |

**STATUS UPDATE (2026-07-17): the human gap is CLOSED** — see the
"MakeHuman-generated humans" section at the bottom. `metahuman_player.glb`
and `npc_human.glb` now exist (MakeHuman/MPFB bodies, CC0), plus a
six-body `variants/npc_human/` pool picked per NPC. Unreal MetaHuman
exports remain a WELCOME upgrade path (higher fidelity faces/hair):
dropping `metahuman_npc.glb` / replacing `metahuman_player.glb` /
`metahuman_<race_id>.glb` still upgrades everything with zero code
changes — the resolver order is unchanged.

The paragraphs below are the history of how this gap was found and
worked around before it was closed; kept for context:

**Important correction:** that mesh is not actually a human — inspecting
its glTF materials shows `playerobot` (chassis) and `robotemitter` (glow
strip); its skinned mesh nodes are named `Robot_Body`/`Robot_Arms`/
`Robot_Cannons`. It's the tps-demo's sci-fi robot player character, not an
"interim human" as earlier comments/docs implied. `NpcBody`'s per-NPC
tinting previously targeted Skin/Hair surface names that don't exist on
this mesh and silently did nothing; it's been retargeted to also tint the
real `playerobot`/`robotemitter` surfaces (archetype-flavored chassis
color + faction-accent glow), and the `Robot_Cannons` mesh is hidden for
every archetype except Authority (a visible weapon fits "power-holder",
not "barista"). This is real, visible per-NPC variety within the current
mesh's actual constraints — it does not make the mesh a human.

**Vehicle asset slots** (AssetLibrary.instance_or — drop a `.glb` in
`assets/models/` named for the slot, zero code changes needed):
- `vehicle_car_body.glb` — ✅ filled (Kenney Car Kit `sedan.glb`). Wheels
  stay procedural placeholders; swapping in a full external car rig with
  matching wheel positions is a deeper integration than a body-mesh swap,
  not yet wired.
- `vehicle_boat_body.glb` — ✅ filled (Kenney Watercraft Kit `boat-speed-a.glb`)
- `vehicle_spacecraft_body.glb` — ✅ filled (Kenney Space Kit `craft_racer.glb`)
- `vehicle_aircraft_body.glb` — ❌ still empty. No Kenney aircraft kit
  exists yet (they've teased one but not shipped it as of this writing);
  no other CC0 single-file source was found. Falls back to the procedural
  box.

**City asset slots** (MegaCityBuilder / BuildingBuilder):
- `city_tower.glb` — ✅ filled (Kenney City Kit Commercial `building-skyscraper-c.glb`)
- `city_lowrise.glb` — ✅ filled (Kenney City Kit Commercial `building-e.glb`)
- `city_house.glb` — ✅ filled (Kenney City Kit Suburban `building-type-f.glb`)
- `city_industrial.glb` — ✅ filled (Kenney City Kit Industrial `building-e.glb`)
- `road_segment.glb` — ✅ filled (Kenney City Kit Roads `road-straight.glb`)
- `sidewalk.glb` — ✅ filled (Kenney City Kit Roads `tile-low.glb`)
- `streetlight.glb` — ✅ filled (Kenney City Kit Roads `light-square.glb`)
- `city_prop.glb` — ✅ filled (Kenney City Kit Suburban `planter.glb`)

**Resolved: `AssetLibrary.instance_variant(slot, rng)`** now picks
deterministically from a per-slot pool (`godot/data/asset_variants.json`
→ `assets/models/variants/<slot>/*.glb`), so the same city rebuilds
identically (same seed → same picks) while different buildings on the
same block use different meshes. `BuildingBuilder.build()`/`build_osm()`
thread the existing per-city `rng` through it; `BreakableProp` gets a
`variant_seed` set by its placer. `instance(slot)` / `instance_or()` are
unchanged and still work for every slot that has no variant pool.

Current pool sizes (all CC0, all from the packs below — well short of
what each pack actually ships, kept modest for repo size):

| Slot | Variants pulled in | Pack |
|---|---|---|
| `city_tower` | 5 of 5 skyscrapers | Kenney City Kit (Commercial) |
| `city_lowrise` | 6 of 14 buildings | Kenney City Kit (Commercial) |
| `city_house` | 8 of 21 houses | Kenney City Kit (Suburban) |
| `city_industrial` | 8 of 20 buildings | Kenney City Kit (Industrial) |
| `city_prop` | 3 (planter + 2 tree sizes) | Kenney City Kit (Suburban) |
| `vehicle_car_body` | 5 (sedan/sedan-sports/taxi/suv/police — same wheelbase class as the existing procedural wheel offsets) | Kenney Car Kit |
| `vehicle_spacecraft_body` | 5 (racer + 4 speeders) | Kenney Space Kit |

`road_segment`/`sidewalk` stay single-file on purpose — road tiles have
to interlock at fixed pivots/edges, and swapping them per-instance without
matching connector geometry would break the street grid, not just look
different. `vehicle_boat_body` also stays single-file (Watercraft Kit has
45 boats if a future pass wants to extend it the same way).

Further headroom in the same already-vetted CC0 packs, if a future pass
wants to go further:

| Pack | Total variants available | License |
|---|---|---|
| [Kenney City Kit (Commercial)](https://kenney.nl/assets/city-kit-commercial) | 14 full buildings + 5 skyscrapers + 16 low-detail | CC0 |
| [Kenney City Kit (Industrial)](https://kenney.nl/assets/city-kit-industrial) | 20 buildings + chimneys/tanks | CC0 |
| [Kenney City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban) | 21 houses + fences/paths/trees | CC0 |
| [Kenney City Kit (Roads)](https://kenney.nl/assets/city-kit-roads) | 70+ road/intersection/signage tiles | CC0 |
| [Kenney Car Kit](https://kenney.nl/assets/car-kit) | 13 vehicles (also delivery/truck/race — different wheelbase class, riskier to drop into the fixed wheel rig without visual QA) | CC0 |
| [Kenney Watercraft Kit](https://kenney.nl/assets/watercraft-kit) | 45 boats | CC0 |
| [Kenney Space Kit](https://kenney.nl/assets/space-kit) | 6 craft + full station/corridor kit | CC0 |

See `docs/VISUAL_DIRECTION_ESO.md`.

## MakeHuman-generated humans (2026-07-17 — the human gap is CLOSED)

| File | Source | License |
|---|---|---|
| `npc_human.glb`, `metahuman_player.glb`, `variants/npc_human/*.glb` (6 bodies) | Generated headlessly in this repo's pipeline: **MPFB v2.0.16** (MakeHuman Plugin For Blender, from extensions.blender.org, sha256-verified) running inside **bpy 5.0.1** (Blender as a Python module, PyPI). Parametric macro targets (gender/age/muscle/weight/proportions/height) baked per variant; helper cage stripped (13,380 verts each); real-world heights 1.64–1.84 m verified in the exported glTF accessors. | **CC0** — the MakeHuman project licenses characters exported with its tools as CC0; MPFB is GPL but its *output meshes* carry no license restriction. |

Details that matter to consumers:
- Materials are named `Skin` and `Outfit` — `NpcBody._apply_surface_tints`
  keys on those names: Skin gets the per-NPC natural skin-tone lerp,
  Outfit gets the archetype palette (brass barista / gunmetal authority /
  jewel-red lover / graphite archivist / violet reflection).
- Six builds ship in `variants/npc_human/` (f_slim/f_average/f_athletic/
  m_average/m_heavy/m_athletic); `NpcBody` picks one deterministically
  per NPC id via `AssetLibrary.instance_variant`. `npc_human.glb`
  (= m_average) remains the single-slot fallback; `metahuman_player.glb`
  (= m_athletic) upgrades the player from the tps-demo robot.
- Unrigged and unclothed-but-material-split (head/neck = Skin, below =
  fitted Outfit — reads as a bodysuit consistent with the identity-lens
  aesthetic). No skeletal animation exists in the game yet, so no rig is
  currently a non-loss; when animation lands, regenerate with MPFB's rig
  (`scripts/` pipeline can be re-run — see AGENTS.md).
- The tps-demo robot (`player_human.glb`) stays on disk as the last-chance
  fallback and for anything that intentionally wants the robot.
