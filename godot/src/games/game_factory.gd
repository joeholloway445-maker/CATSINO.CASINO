extends Node

# ── Signals ────────────────────────────────────────────────────────────────────
signal game_created(type: GameType, variant_id: int, instance: Node)
signal template_registered(type: GameType)

# ── Enums ──────────────────────────────────────────────────────────────────────
enum GameType { SLOTS, RACING, SPORTS, CARDS, PUZZLE, ARCADE }

# ── Constants ──────────────────────────────────────────────────────────────────
const MAX_VARIANTS := 200

# ── State ──────────────────────────────────────────────────────────────────────
var _templates: Dictionary = {}           # GameType -> Array[PackedScene]
var _variant_configs: Dictionary = {}     # GameType -> Array[Dictionary]

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_generate_variant_configs()

func initialize() -> void:
	_try_load_default_templates()

# ── Public API ─────────────────────────────────────────────────────────────────
func register_template(type: GameType, packed_scene: PackedScene) -> void:
	if type not in _templates:
		_templates[type] = []
	_templates[type].append(packed_scene)
	emit_signal("template_registered", type)

func create_game(type: GameType, variant_id: int) -> Node:
	variant_id = clampi(variant_id, 0, MAX_VARIANTS - 1)
	var config := get_variant_config(type, variant_id)
	var instance: Node

	# Prefer an exact catalog scene for featured lobby variants.
	var catalog_scene := _catalog_scene_for(type, variant_id)
	if catalog_scene != "" and ResourceLoader.exists(catalog_scene):
		var packed: PackedScene = load(catalog_scene) as PackedScene
		if packed:
			instance = packed.instantiate()
		else:
			instance = Node.new()
	elif type in _templates and not _templates[type].is_empty():
		var scene_idx: int = variant_id % _templates[type].size()
		var scene: PackedScene = _templates[type][scene_idx]
		instance = scene.instantiate()
	else:
		instance = Node.new()
		instance.name = "%s_%d" % [GameType.keys()[type], variant_id]

	for key in config:
		instance.set_meta(key, config[key])

	emit_signal("game_created", type, variant_id, instance)
	return instance

func create_game_from_catalog(type: int, variant_id: int) -> Node:
	return create_game(type as GameType, variant_id)

func _catalog_scene_for(type: GameType, variant_id: int) -> String:
	for entry in get_game_catalog():
		if int(entry.get("game_type", -1)) == int(type) and int(entry.get("variant_id", -1)) == variant_id:
			return str(entry.get("scene", ""))
	return ""

func get_variant_config(type: GameType, variant_id: int) -> Dictionary:
	if type in _variant_configs and variant_id < _variant_configs[type].size():
		return _variant_configs[type][variant_id]
	return _generate_single_config(type, variant_id)

func get_all_variants(type: GameType) -> Array[Dictionary]:
	if type in _variant_configs:
		return _variant_configs[type]
	return []

## Lobby catalog — one featured card per game type with a real scene when possible.
func get_game_catalog() -> Array:
	var featured := [
		{name="Lucky Cat Slots", type=GameType.SLOTS, type_label="Slots", scene="res://scenes/games/slots/slot_machine.tscn", min_bet=10},
		{name="Neon Circuit", type=GameType.RACING, type_label="Racing", scene="res://scenes/games/racing/race_track.tscn", min_bet=50},
		{name="Paw Ball", type=GameType.SPORTS, type_label="Sports", scene="res://scenes/games/sports/paw_ball.tscn", min_bet=25},
		{name="Black Cat 21", type=GameType.CARDS, type_label="Cards", scene="res://scenes/games/arcade/blackjack.tscn", min_bet=10},
		{name="Whisker Wins Poker", type=GameType.CARDS, type_label="Cards", scene="res://scenes/games/arcade/paw_poker.tscn", min_bet=10},
		{name="Texas Hold'em", type=GameType.CARDS, type_label="Cards", scene="res://scenes/games/arcade/holdem.tscn", min_bet=20},
		{name="Cat Puzzle", type=GameType.PUZZLE, type_label="Puzzle", scene="res://scenes/games/arcade/cat_puzzle.tscn", min_bet=15},
		{name="Fortune Wheel", type=GameType.ARCADE, type_label="Arcade", scene="res://scenes/games/arcade/fortune_wheel.tscn", min_bet=20},
		{name="Scratch Card", type=GameType.ARCADE, type_label="Arcade", scene="res://scenes/games/arcade/scratch_card.tscn", min_bet=15},
		{name="Coin Pusher", type=GameType.ARCADE, type_label="Arcade", scene="res://scenes/games/arcade/coin_pusher.tscn", min_bet=10},
	]
	var out: Array = []
	for i in featured.size():
		var e: Dictionary = featured[i]
		out.append({
			"name": e.name,
			"type_label": e.type_label,
			"game_type": int(e.type),
			"variant_id": i,
			"min_bet": int(e.min_bet),
			"scene": str(e.scene),
		})
	return out

# ── Private ────────────────────────────────────────────────────────────────────
func _generate_variant_configs() -> void:
	var rng := RandomNumberGenerator.new()
	for type in GameType.values():
		_variant_configs[type] = []
		for i in range(MAX_VARIANTS):
			rng.seed = hash("%d_%d" % [type, i])
			_variant_configs[type].append(_generate_single_config(type, i, rng))

func _generate_single_config(type: GameType, variant_id: int, rng: RandomNumberGenerator = null) -> Dictionary:
	if not rng:
		rng = RandomNumberGenerator.new()
		rng.seed = hash("%d_%d" % [type, variant_id])

	var base := {
		"variant_id":  variant_id,
		"game_type":   GameType.keys()[type],
		"min_bet":     rng.randi_range(10, 100),
		"max_bet":     rng.randi_range(500, 10000),
		"rtp":         rng.randf_range(0.92, 0.98),  # Return to player
		"volatility":  ["low", "medium", "high"][rng.randi() % 3],
	}

	match type:
		GameType.SLOTS:
			base.merge({
				"reels":       rng.randi_range(3, 6),
				"rows":        rng.randi_range(3, 5),
				"paylines":    rng.randi_range(9, 243),
				"wild_mult":   rng.randi_range(2, 10),
				"free_spins":  rng.randi_range(5, 20),
				"theme":       ["Egyptian", "Space", "Cats", "Neon", "Fantasy"][rng.randi() % 5],
			})
		GameType.RACING:
			base.merge({
				"track_length": rng.randi_range(800, 3000),
				"num_racers":   rng.randi_range(4, 12),
				"race_type":    ["Sprint", "Endurance", "Obstacle"][rng.randi() % 3],
				"boost_pads":   rng.randi_range(0, 8),
			})
		GameType.SPORTS:
			base.merge({
				"sport":         ["Football", "Basketball", "Tennis", "Boxing"][rng.randi() % 4],
				"match_length":  rng.randi_range(60, 180),
				"team_size":     rng.randi_range(1, 11),
			})
		GameType.CARDS:
			base.merge({
				"card_game":  ["Poker", "Blackjack", "Baccarat", "Rummy"][rng.randi() % 4],
				"decks":      rng.randi_range(1, 8),
				"max_players":rng.randi_range(2, 8),
			})
		GameType.PUZZLE:
			base.merge({
				"grid_size":  rng.randi_range(5, 10),
				"difficulty": ["easy", "medium", "hard", "expert"][rng.randi() % 4],
				"time_limit": rng.randi_range(60, 300),
			})
		GameType.ARCADE:
			base.merge({
				"lives":        rng.randi_range(3, 5),
				"levels":       rng.randi_range(5, 30),
				"power_ups":    rng.randi_range(2, 8),
				"genre":        ["Shooter", "Platformer", "Runner", "Puzzle"][rng.randi() % 4],
			})
	return base

func _try_load_default_templates() -> void:
	var type_paths := {
		GameType.SLOTS:  "res://scenes/games/slots/",
		GameType.RACING: "res://scenes/games/racing/",
		GameType.SPORTS: "res://scenes/games/sports/",
		GameType.CARDS:  "res://scenes/games/arcade/",
		GameType.PUZZLE: "res://scenes/games/arcade/",
		GameType.ARCADE: "res://scenes/games/arcade/",
	}
	for type in type_paths:
		var path: String = type_paths[type]
		var dir := DirAccess.open(path)
		if not dir:
			continue
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if fname.ends_with(".tscn"):
				var scene := load(path + fname)
				if scene is PackedScene:
					register_template(type, scene)
			fname = dir.get_next()
