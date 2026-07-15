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
| `godot/src/world/overworld/third_person_controller.gd` | Movement/camera physics pattern adapted from godotengine/tps-demo's `player/player.gd` (single-player rewrite, gun-robot/multiplayer scaffolding removed; ability-kit hotbar and cat/identity visual-mode switching are original) | MIT (code) |
| `godot/src/vehicles/land_vehicle.gd` | Steering/throttle model adapted from the official [godotengine/godot-demo-projects](https://github.com/godotengine/godot-demo-projects) `3d/truck_town` sample's `vehicles/vehicle.gd` (whole-repo MIT, no split code/asset license unlike tps-demo) — rewritten for our input map, procedural placeholder body/wheels, and VehicleSeat enter/exit instead of their multi-vehicle trailer/tow-truck rig | MIT (code) |
| `godot/src/vehicles/water_vehicle.gd`, `air_vehicle.gd`, `space_vehicle.gd` | Original — no equivalent official Godot demo exists for buoyancy or flight (unlike VehicleBody3D for land, Godot has no built-in boat/aircraft physics node), so these are from-scratch arcade models | MIT (code) |

**Target:** replace humanoids with **your MetaHuman GLB exports** at:
- `metahuman_player.glb` (local player identity)
- `metahuman_npc.glb` (generic NPC — still missing; NPCs currently fall
  through to `player_human.glb`, see below)
- `metahuman_<race_id>.glb` optional per-race variants

**No CC0/MIT source for a photoreal human was found that doesn't require a
DCC-tool export step** (see `docs/ASSET_SHOPPING_LIST.md` "Humans" section
for what was actually checked and why each was rejected/deferred). Until
MetaHuman exports land, every human in the game — player AND all 1,000+
generated NPCs — renders as the same `player_human.glb` mesh.

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

**Known limitation:** `AssetLibrary.instance(slot)` resolves exactly ONE
file per slot name — there's no variant/random-pick mechanism, so every
tower in every city currently uses the identical `city_tower.glb` mesh.
The source packs above ship far more variety than this can use yet:

| Pack | Variants available | License |
|---|---|---|
| [Kenney City Kit (Commercial)](https://kenney.nl/assets/city-kit-commercial) | 14 full buildings + 5 skyscrapers + 16 low-detail | CC0 |
| [Kenney City Kit (Industrial)](https://kenney.nl/assets/city-kit-industrial) | 20 buildings + chimneys/tanks | CC0 |
| [Kenney City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban) | 21 houses + fences/paths/trees | CC0 |
| [Kenney City Kit (Roads)](https://kenney.nl/assets/city-kit-roads) | 70+ road/intersection/signage tiles | CC0 |
| [Kenney Car Kit](https://kenney.nl/assets/car-kit) | 13 vehicles (sedan/suv/taxi/police/truck/race/delivery) | CC0 |
| [Kenney Watercraft Kit](https://kenney.nl/assets/watercraft-kit) | 45 boats | CC0 |
| [Kenney Space Kit](https://kenney.nl/assets/space-kit) | 6 craft + full station/corridor kit | CC0 |

A natural follow-up: extend `AssetLibrary` to accept an array per slot
(`city_tower_a`, `city_tower_b`, … or a `variants()` call) and pull the
rest of these packs in — same CC0 license, already verified, zero new
licensing work.

See `docs/VISUAL_DIRECTION_ESO.md`.
