extends Node
class_name ProceduralMapGenerator

# Layer definitions
const LAYERS = {
	"subliminal": {"color": Color.WHITE, "theme": "residential", "seed_offset": 0},
	"liminal": {"color": Color.LIGHT_GRAY, "theme": "commercial", "seed_offset": 1000},
	"supraliminal": {"color": Color.GRAY, "theme": "corporate", "seed_offset": 2000},
	"hyperliminal": {"color": Color.DARK_GRAY, "theme": "casino", "seed_offset": 3000},
	"extraliminal": {"color": Color.BLACK, "theme": "wilderness", "seed_offset": 4000},
	"periliminal": {"color": Color.DIM_GRAY, "theme": "void", "seed_offset": 5000}
}

# Tilemap dimensions
const CHUNK_SIZE = 32  # 32x32 tiles per chunk
const CHUNKS_PER_LAYER = 10  # 10x10 chunks = 320x320 tiles
const TILE_SIZE = 16  # 16 pixels per tile

# Noise parameters
var noise: FastNoiseLite
var terrain_type_noise: FastNoiseLite
var poi_noise: FastNoiseLite

func _ready() -> void:
	setup_noise()

func setup_noise() -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05
	noise.amplitude = 1.0

	terrain_type_noise = FastNoiseLite.new()
	terrain_type_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	terrain_type_noise.frequency = 0.08
	terrain_type_noise.amplitude = 1.0

	poi_noise = FastNoiseLite.new()
	poi_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	poi_noise.frequency = 0.02
	poi_noise.amplitude = 1.0

func generate_layer(layer_name: String) -> Dictionary:
	"""Generate complete map for one layer"""
	var layer_data = LAYERS[layer_name]
	var seed_offset = layer_data["seed_offset"]

	noise.seed = seed_offset
	terrain_type_noise.seed = seed_offset + 100
	poi_noise.seed = seed_offset + 200

	var tilemap_data = {
		"layer": layer_name,
		"width": CHUNKS_PER_LAYER * CHUNK_SIZE,
		"height": CHUNKS_PER_LAYER * CHUNK_SIZE,
		"tiles": [],
		"poi": [],
		"enemies": [],
		"npcs": []
	}

	# Generate terrain
	for y in range(tilemap_data["height"]):
		for x in range(tilemap_data["width"]):
			var tile_type = get_terrain_type(x, y, layer_name)
			tilemap_data["tiles"].append({
				"x": x,
				"y": y,
				"type": tile_type,
				"walkable": is_walkable(tile_type)
			})

	# Generate POIs (Points of Interest)
	tilemap_data["poi"] = generate_pois(layer_name)

	# Generate enemy spawn zones
	tilemap_data["enemies"] = generate_enemy_zones(layer_name)

	# Generate NPC locations
	tilemap_data["npcs"] = generate_npc_locations(layer_name)

	return tilemap_data

func get_terrain_type(x: int, y: int, layer_name: String) -> String:
	"""Determine tile type based on noise and layer"""
	var height_value = noise.get_noise_2d(float(x), float(y))
	var terrain_value = terrain_type_noise.get_noise_2d(float(x), float(y))

	var theme = LAYERS[layer_name]["theme"]

	# Map noise values to terrain types
	if height_value > 0.6:
		return "mountain_%s" % theme
	elif height_value > 0.2:
		return "hill_%s" % theme
	elif height_value > -0.2:
		if terrain_value > 0.3:
			return "water_%s" % theme
		else:
			return "grass_%s" % theme
	elif height_value > -0.6:
		return "sand_%s" % theme
	else:
		return "void_%s" % theme

func is_walkable(tile_type: String) -> bool:
	"""Check if tile is walkable"""
	var unwalkable = ["water_", "void_", "mountain_"]
	for u in unwalkable:
		if tile_type.begins_with(u):
			return false
	return true

func generate_pois(layer_name: String) -> Array[Dictionary]:
	"""Generate Points of Interest (quests, secrets, landmarks)"""
	var pois = []
	var poi_count = randi_range(8, 15)

	for i in range(poi_count):
		var x = randi_range(10, CHUNKS_PER_LAYER * CHUNK_SIZE - 10)
		var y = randi_range(10, CHUNKS_PER_LAYER * CHUNK_SIZE - 10)
		var poi_type = get_poi_type(layer_name)

		pois.append({
			"id": "%s_poi_%d" % [layer_name, i],
			"x": x,
			"y": y,
			"type": poi_type,
			"name": generate_poi_name(poi_type, layer_name),
			"quest_available": randi_range(0, 1) == 1,
			"difficulty": randi_range(1, 5)
		})

	return pois

func get_poi_type(layer_name: String) -> String:
	"""Determine POI type based on layer"""
	var theme_pois = {
		"residential": ["home", "shop", "park", "school"],
		"commercial": ["store", "office", "restaurant", "gas_station"],
		"corporate": ["tower", "lab", "vault", "headquarters"],
		"casino": ["casino", "bar", "hotel", "vault"],
		"wilderness": ["cave", "grove", "cliff", "lake"],
		"void": ["ruin", "void_gate", "echo_site", "paradox"]
	}

	var theme = LAYERS[layer_name]["theme"]
	var options = theme_pois[theme]
	return options[randi() % options.size()]

func generate_poi_name(poi_type: String, layer_name: String) -> String:
	"""Generate name for POI"""
	var names = {
		"home": ["Cozy House", "Apartment", "Residential Unit"],
		"shop": ["General Store", "Convenience Store", "Merchant"],
		"park": ["Green Space", "Recreation Area", "Community Park"],
		"school": ["Education Center", "Learning Hub", "Academy"],
		"tower": ["Corporate Tower", "Optimization Hub", "Data Center"],
		"cave": ["Primal Cave", "Sacred Cavern", "Beast's Lair"],
		"grove": ["Ancient Grove", "Symbiosis Forest", "Evolution Nexus"],
		"void": ["Void Rupture", "Entropy Site", "Paradox Fold"],
	}

	if names.has(poi_type):
		var option_list = names[poi_type]
		return option_list[randi() % option_list.size()]
	return "POI_%s" % layer_name

func generate_enemy_zones(layer_name: String) -> Array[Dictionary]:
	"""Generate enemy spawn zones"""
	var zones = []
	var zone_count = randi_range(4, 8)

	for i in range(zone_count):
		var x = randi_range(10, CHUNKS_PER_LAYER * CHUNK_SIZE - 10)
		var y = randi_range(10, CHUNKS_PER_LAYER * CHUNK_SIZE - 10)
		var radius = randi_range(20, 50)

		zones.append({
			"id": "%s_zone_%d" % [layer_name, i],
			"center_x": x,
			"center_y": y,
			"radius": radius,
			"level_range": [1 + (2 * i), 5 + (2 * i)],
			"entity_types": get_layer_entities(layer_name),
			"spawn_rate": 0.3  # 30% chance per tile per update
		})

	return zones

func get_layer_entities(layer_name: String) -> Array[String]:
	"""Get entity types for each layer"""
	var faction_map = {
		"residential": "SovereignCrown",
		"commercial": "SovereignCrown",
		"corporate": "SovereignCrown",
		"casino": "HyperLiminal",
		"wilderness": "WildlandsAscendant",
		"void": "VeiledCurrent"
	}

	var theme = LAYERS[layer_name]["theme"]
	var faction = faction_map[theme]

	# Return sample of entities from faction
	# In production, would reference full entity roster
	return ["%s_1" % faction, "%s_2" % faction, "%s_3" % faction]

func generate_npc_locations(layer_name: String) -> Array[Dictionary]:
	"""Generate NPC locations"""
	# Subliminal is a private safe zone — never seed ambient NPCs.
	if layer_name == "subliminal":
		return []
	var npcs = []
	var npc_count = randi_range(5, 10)

	for i in range(npc_count):
		var x = randi_range(10, CHUNKS_PER_LAYER * CHUNK_SIZE - 10)
		var y = randi_range(10, CHUNKS_PER_LAYER * CHUNK_SIZE - 10)
		var npc_type = get_npc_archetype(layer_name)

		npcs.append({
			"id": "%s_npc_%d" % [layer_name, i],
			"x": x,
			"y": y,
			"type": npc_type,
			"name": generate_npc_name(npc_type),
			"quest_available": randi_range(0, 1) == 1,
			"dialogue_key": "npc_%s_%d" % [layer_name, i]
		})

	return npcs

func get_npc_archetype(layer_name: String) -> String:
	"""Get NPC archetype for layer"""
	var archetypes = {
		"residential": ["barista", "neighbor", "child"],
		"commercial": ["merchant", "clerk", "customer"],
		"corporate": ["executive", "employee", "intern"],
		"casino": ["dealer", "gambler", "security"],
		"wilderness": ["hunter", "shaman", "beast"],
		"void": ["echo", "phantom", "reflection"]
	}

	var theme = LAYERS[layer_name]["theme"]
	var options = archetypes[theme]
	return options[randi() % options.size()]

func generate_npc_name(archetype: String) -> String:
	"""Generate name for NPC"""
	var first_names = ["Alex", "Morgan", "Jordan", "Casey", "Riley", "Taylor", "Avery", "Sam"]
	var last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis"]

	return "%s %s" % [
		first_names[randi() % first_names.size()],
		last_names[randi() % last_names.size()]
	]

func export_layer_as_json(layer_data: Dictionary, output_path: String) -> bool:
	"""Export layer data as JSON for Godot TileMap import"""
	var json_str = JSON.stringify(layer_data)
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		return true
	return false

func generate_all_layers() -> Dictionary:
	"""Generate all 6 layers and export"""
	var all_layers = {}

	for layer_name in LAYERS.keys():
		print("Generating layer: %s" % layer_name)
		var layer_data = generate_layer(layer_name)
		all_layers[layer_name] = layer_data

		# Export to file
		var output_path = "res://assets/maps/%s_map.json" % layer_name
		export_layer_as_json(layer_data, output_path)

	return all_layers
