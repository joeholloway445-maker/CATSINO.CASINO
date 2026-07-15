extends Node
## Autoload "NPCManager": manages NPC population with lazy-loading and LOD.
## Do not add class_name — it collides with the autoload singleton name.
## - Generates 1000+ unique NPCs per layer on demand
## - Keeps ~50 full-detail NPCs loaded at once (others use impostors)
## - Integrates with WorldLoader and NPCSpawner

const MAX_ACTIVE_NPCS := 50
const LOD_DISTANCE_NEAR := 30.0
const LOD_DISTANCE_FAR := 100.0

var generator: NPCGenerator
var _loaded_npcs: Dictionary = {}  # layer -> {npc_id -> NPC dict}
var _player: Node3D = null
var _active_instances: Array[Node] = []
var _npc_cache: Dictionary = {}  # npc_id -> cached data

signal npc_spawned(npc: Node3D, data: Dictionary)
signal npc_despawned(npc_id: String)

func _ready() -> void:
	generator = NPCGenerator.new()
	# Don't initialize yet; wait for WorldLoader
	if WorldLoader.world_loaded.is_connected(_on_world_loaded):
		return
	WorldLoader.world_loaded.connect(_on_world_loaded)
	if WorldLoader.districts.is_empty():
		return
	_on_world_loaded()

func _on_world_loaded() -> void:
	# Lore dialogue blocks first (one per archetype × layer) so every
	# generated NPC's dialogue_id resolves in npc_dialogue_ui.
	NpcDialogueLibrary.register_all()

	# Initialize: generate NPCs for each layer
	var seed_map := {
		"subliminal": "layer_subliminal",
		"liminal": "layer_liminal",
		"supraliminal": "layer_supraliminal",
		"hyperliminal": "layer_hyperliminal",
		"extraliminal": "layer_extraliminal",
		"periliminal": "layer_periliminal"
	}

	for layer: String in seed_map.keys():
		var seed_key: String = str(seed_map[layer])
		var count := _npc_count_for_layer(layer)
		var npcs := generator.generate_npcs(count, seed_key, layer)
		_loaded_npcs[layer] = {}
		for npc in npcs:
			_loaded_npcs[layer][npc.id] = npc
			_npc_cache[npc.id] = npc

	# Merge generated NPCs into WorldLoader
	for layer_key in _loaded_npcs.keys():
		var layer_npcs: Dictionary = _loaded_npcs[layer_key]
		WorldLoader.npcs.merge(layer_npcs)

	print("[NPCManager] Generated %d NPCs across %d layers" % [_npc_cache.size(), _loaded_npcs.size()])

func _npc_count_for_layer(layer: String) -> int:
	# Distribute ~1000 NPCs across layers; smaller layers get fewer
	var distribution := {
		"subliminal": 50,      # small - just your apartment area
		"liminal": 100,         # medium - transitional space
		"supraliminal": 300,    # large - 4 cities
		"hyperliminal": 150,    # medium-large - casino
		"extraliminal": 200,    # large - guild territories
		"periliminal": 200,     # medium - abstract realm
	}
	return distribution.get(layer, 100)

## Get an NPC by ID (may be from cache or generate fresh).
func get_npc(npc_id: String) -> Dictionary:
	if npc_id in _npc_cache:
		return _npc_cache[npc_id]
	var npc := generator.generate_npc(npc_id)
	if not npc.is_empty():
		_npc_cache[npc_id] = npc
	return npc

## Get all NPCs in a district (respects LOD distance).
func get_npcs_in_district(district_id: String, player_pos: Vector3 = Vector3.ZERO) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var npcs_by_dist: Array[Dictionary] = []

	for npc in WorldLoader.npcs.values():
		if npc.get("district", "") != district_id:
			continue

		var npc_pos := Vector3(
			npc.get("position", {}).get("x", 0.0),
			npc.get("position", {}).get("y", 0.0),
			npc.get("position", {}).get("z", 0.0)
		)

		var dist := npc_pos.distance_to(player_pos) if player_pos != Vector3.ZERO else 0.0
		npc["_distance"] = dist
		npcs_by_dist.append(npc)

	# Sort by distance
	npcs_by_dist.sort_custom(func(a, b): return a["_distance"] < b["_distance"])

	# Load nearest MAX_ACTIVE_NPCS at full detail; rest use impostors
	for i in range(npcs_by_dist.size()):
		var npc := npcs_by_dist[i]
		if i < MAX_ACTIVE_NPCS:
			npc["lod_level"] = 0 if npc["_distance"] < LOD_DISTANCE_NEAR else 1
		else:
			npc["lod_level"] = 2  # impostor / shadow
		npc["last_seen_distance"] = npc["_distance"]
		result.append(npc)

	return result

## Set the player reference for LOD distance calculations.
func set_player(player: Node3D) -> void:
	_player = player

## Preload a layer's NPCs into memory (called when entering a layer).
func preload_layer(layer_id: String) -> void:
	if layer_id in _loaded_npcs:
		# Already loaded; just update LOD
		pass
	else:
		# Generate on-demand
		var seed_key := "layer_%s" % layer_id
		var count := _npc_count_for_layer(layer_id)
		var npcs := generator.generate_npcs(count, seed_key, layer_id)
		_loaded_npcs[layer_id] = {}
		for npc in npcs:
			_loaded_npcs[layer_id][npc.id] = npc
			_npc_cache[npc.id] = npc
		WorldLoader.npcs.merge(_loaded_npcs[layer_id])

## Unload a layer's NPCs from memory (called when leaving a layer).
func unload_layer(layer_id: String) -> void:
	if layer_id in _loaded_npcs:
		# Keep in cache but remove active instances
		var layer_npcs: Dictionary = _loaded_npcs[layer_id]
		_active_instances = _active_instances.filter(func(inst):
			var npc_id = inst.name
			return not (npc_id in layer_npcs)
		)

## Register a spawned NPC node for tracking (called by NPCSpawner).
func register_instance(npc_id: String, node: Node3D) -> void:
	var data := get_npc(npc_id)
	if not data.is_empty():
		_active_instances.append(node)
		node.name = npc_id
		npc_spawned.emit(node, data)

## Unregister a despawned NPC node (called by NPCSpawner or cleanup).
func unregister_instance(npc_id: String) -> void:
	_active_instances = _active_instances.filter(func(n): return n.name != npc_id)
	npc_despawned.emit(npc_id)

## Update LOD for all active instances based on player distance.
## Uses the LIVE node position — ambient NPCs wander, so the spawn point
## in their data dict goes stale within seconds.
func update_lod(player_pos: Vector3) -> void:
	for inst in _active_instances:
		if not is_instance_valid(inst) or not (inst is Node3D):
			continue
		var dist: float = (inst as Node3D).global_position.distance_to(player_pos)
		var level := 0
		if dist >= LOD_DISTANCE_FAR:
			level = 2
		elif dist >= LOD_DISTANCE_NEAR:
			level = 1
		if inst.has_method("update_lod"):
			inst.call("update_lod", level)

func _process(_delta: float) -> void:
	if _player and is_instance_valid(_player):
		update_lod(_player.global_position)
