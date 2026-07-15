# Model & code attribution

| File | Source | License |
|---|---|---|
| `interim/tps_player.glb`, `player_human.glb`, `npc_human.glb` | [godotengine/tps-demo](https://github.com/godotengine/tps-demo) player model | **CC-BY 3.0** — assets Copyright (c) 2018 Juan Linietsky, Fernando Miguel Calabró (corrected: previously mislabeled MIT here; the demo's *code* is MIT, its *art assets* are CC-BY 3.0 per the demo's own LICENSE.md) |
| `city_prop.glb`, `ruin_pillar.glb` | godotengine/tps-demo level geometry | CC-BY 3.0, same as above |
| `rock.glb` | Terrain3D demo (Tokisan Games) | MIT |
| `godot/src/world/overworld/third_person_controller.gd` | Movement/camera physics pattern adapted from godotengine/tps-demo's `player/player.gd` (single-player rewrite, gun-robot/multiplayer scaffolding removed; ability-kit hotbar and cat/identity visual-mode switching are original) | MIT (code) |
| `godot/src/vehicles/land_vehicle.gd` | Steering/throttle model adapted from the official [godotengine/godot-demo-projects](https://github.com/godotengine/godot-demo-projects) `3d/truck_town` sample's `vehicles/vehicle.gd` (whole-repo MIT, no split code/asset license unlike tps-demo) — rewritten for our input map, procedural placeholder body/wheels, and VehicleSeat enter/exit instead of their multi-vehicle trailer/tow-truck rig | MIT (code) |
| `godot/src/vehicles/water_vehicle.gd`, `air_vehicle.gd`, `space_vehicle.gd` | Original — no equivalent official Godot demo exists for buoyancy or flight (unlike VehicleBody3D for land, Godot has no built-in boat/aircraft physics node), so these are from-scratch arcade models | MIT (code) |

**Target:** replace humanoids with **your MetaHuman GLB exports** at:
- `metahuman_player.glb` (local player identity)
- `metahuman_npc.glb` (generic NPC)
- `metahuman_<race_id>.glb` optional per-race variants

**Vehicle asset slots** (AssetLibrary.instance_or — drop a `.glb` in
`assets/models/` named for the slot, zero code changes needed):
- `vehicle_car_body.glb` — land (wheels stay procedural placeholders;
  swapping in a full external car rig with matching wheel positions is a
  deeper integration than a body-mesh swap, not yet wired)
- `vehicle_boat_body.glb` — water
- `vehicle_aircraft_body.glb` — air
- `vehicle_spacecraft_body.glb` — space

Free CC0 sources for these (same shopping-list pattern as everything
else — see `docs/ASSET_SHOPPING_LIST.md`): Kenney "Watercraft Kit" (boats),
Kenney/Quaternius "Space Kit" (spacecraft), Kenney "Racing Kit"/Quaternius
aircraft packs.

See `docs/VISUAL_DIRECTION_ESO.md`.
