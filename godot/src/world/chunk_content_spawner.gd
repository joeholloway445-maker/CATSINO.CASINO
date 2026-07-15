class_name ChunkContentSpawner
extends RefCounted
## Deterministically decides what world content — liminal doors, vehicle
## spawn points — appears in a newly-built wild chunk. Same seeding
## convention as ProceduralRegionGenerator (coord-derived, so every client
## generates identical placements — required for a shared multiplayer
## world), but a different salt so door/vehicle rolls are independent of
## the biome roll at the same coordinate. Never touches hub chunks
## (hand-authored, frozen — see WorldChunk.is_hub).
##
## Space vehicles are deliberately NOT spawned here: this is a flat XZ
## chunk grid with no altitude/orbital concept, so a spacecraft appearing
## in a random field chunk would be ungrounded lore-wise. Space vehicle
## spawn points are hand-placed at hub spawn locations instead (see
## layer_world.gd/overworld.gd's _place_hub_vehicle_spawns()).

const SALT := 0x53504e57 # "SPNW"
## Must match ProceduralTerrain.WATER_LEVEL_Y / WaterVehicle.WATER_LEVEL_Y —
## a boat needs to spawn floating ON the water surface, not at the
## (deliberately submerged, negative) seabed height like land/air spawns
## use.
const WATER_LEVEL_Y := 0.0

const DOOR_CHANCE := 0.08
const LAND_VEHICLE_CHANCE := 0.10
const AIR_VEHICLE_CHANCE := 0.05
## Rolled only on "coastal" biome chunks (see ProceduralRegionGenerator) —
## much higher than the others since coastal chunks are already rare, and
## a body of water with no boat anywhere near it isn't much of a body of
## water to a player.
const WATER_VEHICLE_CHANCE := 0.35

static func spawn(root: Node3D, chunk: WorldChunk, coord: Vector2i, size: float, terrain: TerrainBridge) -> void:
	if chunk.is_hub:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _salted_seed(coord)

	if rng.randf() < DOOR_CHANCE:
		_spawn_door(root, rng, size, terrain)

	var biome := str(chunk.biome.get("biome", "plains"))
	if biome == "coastal":
		if rng.randf() < WATER_VEHICLE_CHANCE:
			var boat := WaterVehicle.new()
			boat.position = Vector3(rng.randf() * size, WATER_LEVEL_Y, rng.randf() * size)
			root.add_child(boat)
	else:
		if rng.randf() < LAND_VEHICLE_CHANCE:
			_spawn_at(root, rng, size, terrain, LandVehicle.new())
		if rng.randf() < AIR_VEHICLE_CHANCE:
			# Small lift so the aircraft doesn't start embedded in the ground.
			_spawn_at(root, rng, size, terrain, AirVehicle.new(), 2.5)

static func _spawn_door(root: Node3D, rng: RandomNumberGenerator, size: float, terrain: TerrainBridge) -> void:
	var door := LiminalDoor.new()
	var px := rng.randf() * size
	var pz := rng.randf() * size
	door.position = Vector3(px, _ground_height(terrain, root, px, pz), pz)
	root.add_child(door)

static func _spawn_at(root: Node3D, rng: RandomNumberGenerator, size: float, terrain: TerrainBridge, vehicle: Node3D, y_offset: float = 0.0) -> void:
	var px := rng.randf() * size
	var pz := rng.randf() * size
	vehicle.position = Vector3(px, _ground_height(terrain, root, px, pz) + y_offset, pz)
	root.add_child(vehicle)

static func _ground_height(terrain: TerrainBridge, root: Node3D, local_x: float, local_z: float) -> float:
	if terrain == null:
		return 0.0
	return terrain.height_at(root.position.x + local_x, root.position.z + local_z)

static func _salted_seed(coord: Vector2i) -> int:
	return SALT ^ (coord.x * 668265263 + coord.y * 374761393)
