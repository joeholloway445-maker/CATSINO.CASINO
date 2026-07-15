class_name VehicleWorldWiring
extends RefCounted
## Shared by overworld.gd/layer_world.gd: hand-placed hub vehicle spawn
## points (reliable and guaranteed, unlike ChunkContentSpawner's
## probabilistic wild-chunk spawns) plus the streaming-radius/fog-distance
## bump while any vehicle is piloted, so terrain loads in fewer, larger
## chunks instead of small on-foot-sized ones at car/boat/plane speed.
##
## No water vehicle spawn point at hubs: hub chunks are flat, pre-authored
## plazas (WorldChunk.is_hub) with no water body — ProceduralTerrain only
## builds its water surface plane for "coastal" biome wild chunks, so a
## boat placed at a hub spawn would just be sitting on dry ground. Water
## vehicles stay procedural-only, tied to real coastal chunks where a body
## of water actually exists (see ChunkContentSpawner).
##
## Space vehicle DOES get a hub spawn point despite space travel being
## lore-exceptional (see ChunkContentSpawner's own note on this) — a
## placeholder decision until a dedicated "spaceport" concept exists;
## flagged here rather than silently deciding to omit it, since "spawn
## points for everything" was the explicit ask.

const BIGGER_VIEW_RADIUS := 5 # vs ProceduralTerrain.DEFAULT_VIEW_RADIUS(2)
const BIGGER_FOG_DISTANCE := 260.0 # matches BIGGER_VIEW_RADIUS * CHUNK_SIZE(64), minus margin

static func spawn_hub_vehicles(parent: Node3D, terrain: TerrainBridge, base_pos: Vector3) -> Array:
	var vehicles: Array = []

	var land := LandVehicle.new()
	land.position = base_pos + Vector3(6, 0, 0)
	land.position.y = terrain.height_at(land.position.x, land.position.z)
	parent.add_child(land)
	vehicles.append(land)

	var air := AirVehicle.new()
	air.position = base_pos + Vector3(-6, 0, 0)
	air.position.y = terrain.height_at(air.position.x, air.position.z) + 2.5
	parent.add_child(air)
	vehicles.append(air)

	var space := SpaceVehicle.new()
	space.position = base_pos + Vector3(0, 0, -10)
	space.position.y = terrain.height_at(space.position.x, space.position.z) + 3.0
	parent.add_child(space)
	vehicles.append(space)

	return vehicles

## Connects every spawned vehicle's VehicleSeat signals so piloting any of
## them drives terrain streaming (chunk_changed, same as the on-foot
## player) and temporarily widens the loaded radius + push-back fog while
## occupied, restoring both on exit.
static func wire_streaming_bump(vehicles: Array, terrain: TerrainBridge, sky: DayNightSky) -> void:
	for v in vehicles:
		if not ("seat" in v) or v.seat == null:
			continue
		v.seat.chunk_changed.connect(func(coord: Vector2i) -> void: terrain.stream_around(coord))
		v.seat.entered.connect(func() -> void:
			terrain.set_view_radius(BIGGER_VIEW_RADIUS)
			sky.set_fog_distance(BIGGER_FOG_DISTANCE))
		v.seat.exited.connect(func() -> void:
			terrain.set_view_radius(ProceduralTerrain.DEFAULT_VIEW_RADIUS)
			sky.set_fog_distance(DayNightSky.DEFAULT_FOG_DISTANCE))
