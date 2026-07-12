class_name NPCGenerator
## Procedural NPC generator: creates 1000+ unique realistic humans from templates.
## Deterministic seeding ensures same roster per game instance.
## Integrates with WorldLoader NPC system and ambient_npc.gd behavior.

const TEMPLATES_PATH := "res://data/npc_templates.json"
const ARCHETYPES = ["barista", "archivist", "authority", "lover", "reflection"]
const LAYERS = ["subliminal", "liminal", "supraliminal", "hyperliminal", "extraliminal", "periliminal"]
const DISTRICTS_PER_LAYER = {
	"subliminal": ["player_apartment"],
	"liminal": ["liminal_hub"],
	"supraliminal": ["dallas", "fort_worth", "denton", "arlington"],
	"hyperliminal": ["catsino_main", "catsino_vip"],
	"extraliminal": ["territories"],
	"periliminal": ["abstract_realm"]
}

var _templates: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _generated_cache: Dictionary = {}  # npc_id -> NPC dict

func _init() -> void:
	_load_templates()

func _load_templates() -> void:
	if not ResourceLoader.exists(TEMPLATES_PATH):
		push_error("[NPCGenerator] Templates not found: " + TEMPLATES_PATH)
		return
	var file := FileAccess.open(TEMPLATES_PATH, FileAccess.READ)
	if file == null:
		push_error("[NPCGenerator] Cannot open templates file")
		return
	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		_templates = data
	else:
		push_error("[NPCGenerator] Invalid templates JSON")

## Generate N unique NPCs for a specific layer or globally.
## seed_key: used for deterministic generation (e.g., layer_id or "global")
## Returns Array[Dictionary] with generated NPC data.
func generate_npcs(count: int, seed_key: String, layer_filter: String = "") -> Array[Dictionary]:
	_rng.seed = hash(seed_key)
	var result: Array[Dictionary] = []
	var used_ids := {}

	for i in range(count):
		var npc_id := "npc_gen_%s_%d" % [seed_key, i]
		if npc_id in used_ids:
			i -= 1
			continue
		used_ids[npc_id] = true

		var npc := _generate_single(npc_id, layer_filter)
		if not npc.is_empty():
			result.append(npc)

	_generated_cache.merge(result.reduce(func(acc, n): acc[n.id] = n; return acc, {}))
	return result

## Generate a single NPC by ID (deterministic).
func generate_npc(npc_id: String, layer: String = "") -> Dictionary:
	if npc_id in _generated_cache:
		return _generated_cache[npc_id]

	_rng.seed = hash(npc_id)
	var npc := _generate_single(npc_id, layer)
	if not npc.is_empty():
		_generated_cache[npc_id] = npc
	return npc

## Get a cached NPC or generate it.
func get_npc(npc_id: String) -> Dictionary:
	return _generated_cache.get(npc_id, {})

## ── Private Generation ────────────────────────────────────────────────────────

func _generate_single(npc_id: String, layer_filter: String) -> Dictionary:
	if _templates.is_empty():
		return {}

	var layer := layer_filter if layer_filter else LAYERS[_rng.randi() % LAYERS.size()]
	var districts := DISTRICTS_PER_LAYER.get(layer, ["default"])
	var district := districts[_rng.randi() % districts.size()]

	var archetype_id := ARCHETYPES[_rng.randi() % ARCHETYPES.size()]
	var archetype := _get_archetype(archetype_id)
	if archetype.is_empty():
		return {}

	var layer_variant := _get_layer_variant(layer)
	var name_str := _generate_name()
	var age := _roll_age(archetype)
	var appearance := _generate_appearance(archetype, layer_variant)
	var disposition := _get_disposition()
	var schedule := _get_schedule()

	var pos_in_district := _random_position()

	# Build the NPC data structure matching existing WorldLoader format
	return {
		"id": npc_id,
		"name": name_str,
		"district": district,
		"layer": layer,
		"archetype": archetype_id,
		"role": archetype.get("role", "ambient"),
		"faction": _pick_faction(),
		"emoji": _archetype_emoji(archetype_id),
		"greeting": _generate_greeting(name_str, archetype_id, disposition, layer),
		"position": {
			"x": pos_in_district.x,
			"y": pos_in_district.y,
			"z": pos_in_district.z
		},
		"shop_id": _generate_shop_id(archetype_id, district) if _rng.randf() < 0.15 else "",
		"quest_ids": _generate_quest_ids(),
		"dialogue_id": "dlg_%s_%s" % [archetype_id, npc_id.substr(8)],
		# Appearance traits for rendering
		"appearance": appearance,
		"age": age,
		"disposition": disposition.mood,
		"daily_schedule": schedule.name,
		"availability": schedule.availability * disposition.quest_availability,
		# Performance: LOD info
		"lod_level": 0,
		"last_seen_distance": INF,
		# Behavior: how this NPC reacts to player presence
		"recruitable_as": _pick_recruitable_type(),
		"recruitable_quest_id": "recruit_%s_%s" % [archetype_id, npc_id.substr(8)] if _rng.randf() < 0.05 else "",
	}

func _get_archetype(id: String) -> Dictionary:
	if _templates.has("archetypes"):
		for arch in _templates.archetypes:
			if arch.get("id", "") == id:
				return arch
	return {}

func _get_layer_variant(layer: String) -> Dictionary:
	if _templates.has("layer_variants"):
		for lv in _templates.layer_variants:
			if lv.get("layer", "") == layer:
				return lv
	return {}

func _generate_name() -> String:
	var pool_key := ["first_names_neutral", "first_names_feminine", "first_names_masculine"][_rng.randi() % 3]
	var names = _templates.get("name_pools", {}).get(pool_key, ["NPC"])
	var first := names[_rng.randi() % names.size()] if not names.is_empty() else "NPC"

	var last_names = _templates.get("name_pools", {}).get("last_names", ["Person"])
	var last := last_names[_rng.randi() % last_names.size()] if not last_names.is_empty() else "Person"

	return "%s %s" % [first, last]

func _roll_age(archetype: Dictionary) -> int:
	var traits = archetype.get("traits", {})
	var age_range = traits.get("age", {"min": 20, "max": 65})
	var min_age = age_range.get("min", 20)
	var max_age = age_range.get("max", 65)
	return _rng.randi_range(min_age, max_age)

func _generate_appearance(archetype: Dictionary, layer_variant: Dictionary) -> Dictionary:
	var traits = archetype.get("traits", {})

	# Build selection arrays
	var hair_colors = traits.get("hair_colors", ["brown", "black"])
	var hair_styles = traits.get("hair_styles", ["short"])
	var skin_tones = traits.get("skin_tones", ["fair"])
	var builds = traits.get("build", ["average"])

	return {
		"build": builds[_rng.randi() % builds.size()],
		"hair_color": hair_colors[_rng.randi() % hair_colors.size()],
		"hair_style": hair_styles[_rng.randi() % hair_styles.size()],
		"skin_tone": skin_tones[_rng.randi() % skin_tones.size()],
		"outfit_base": traits.get("outfit_base", "casual"),
		"layer_color_palette": layer_variant.get("color_palette", ["neutral"]),
		"lighting": layer_variant.get("lighting", "daylight"),
	}

func _get_disposition() -> Dictionary:
	var dispositions = _templates.get("dispositions", [])
	if dispositions.is_empty():
		return {"mood": "neutral", "greeting_shift": 0.0, "quest_availability": 0.8}
	return dispositions[_rng.randi() % dispositions.size()].duplicate()

func _get_schedule() -> Dictionary:
	var schedules = _templates.get("daily_schedules", [])
	if schedules.is_empty():
		return {"name": "vendor", "hours": "8-18", "availability": 0.8}
	return schedules[_rng.randi() % schedules.size()].duplicate()

func _generate_greeting(name: String, archetype_id: String, disposition: Dictionary, layer: String) -> String:
	var greetings := {
		"barista": [
			"What can I get you?",
			"Welcome! First time here?",
			"The usual, or something new?",
			"You look like you need a break.",
			"Take a seat, relax for a moment."
		],
		"archivist": [
			"Ah, another curious mind.",
			"I've been expecting someone like you.",
			"The knowledge you seek is... complicated.",
			"Have you come to learn?",
			"The past holds many secrets."
		],
		"authority": [
			"State your business.",
			"You're in our territory now.",
			"We maintain order here.",
			"Everything runs smoothly under our watch.",
			"Peace through strength."
		],
		"lover": [
			"Well, well, well... who do we have here?",
			"Charmed to make your acquaintance.",
			"I think we're going to be great friends.",
			"You have excellent taste.",
			"Let me show you something special."
		],
		"reflection": [
			"Interesting... I see something in you.",
			"The mirror shows what's hidden.",
			"Not everyone can perceive this place as you do.",
			"You're asking the right questions.",
			"Truth wears many faces."
		]
	}

	var greeting_pool = greetings.get(archetype_id, ["Hello."])
	var base_greeting = greeting_pool[_rng.randi() % greeting_pool.size()]

	# Modify by disposition and layer
	if disposition.greeting_shift < -0.2:
		return "[%s seems uninterested] %s" % [name, base_greeting]
	elif layer == "periliminal":
		return "[%s speaks from the void] %s" % [name, base_greeting]
	else:
		return base_greeting

func _generate_quest_ids() -> Array:
	var result: Array = []
	if _rng.randf() < 0.3:
		result.append("quest_%d" % _rng.randi() % 100)
	return result

func _generate_shop_id(archetype_id: String, district: String) -> String:
	var shop_types := {
		"barista": "cafe",
		"archivist": "library",
		"authority": "garrison",
		"lover": "salon",
		"reflection": "curiosities"
	}
	var shop_type = shop_types.get(archetype_id, "general")
	return "%s_%s_%d" % [district, shop_type, _rng.randi() % 10]

func _pick_faction() -> String:
	return ["SovereignCrown", "VeiledCurrent", "WildlandsAscendant", "Factionless"][_rng.randi() % 4]

func _archetype_emoji(archetype_id: String) -> String:
	return {
		"barista": "☕",
		"archivist": "📚",
		"authority": "🛡️",
		"lover": "💎",
		"reflection": "🔮"
	}.get(archetype_id, "🐱")

func _pick_recruitable_type() -> String:
	var roll = _rng.randf()
	if roll < 0.02:
		return "companion"
	elif roll < 0.04:
		return "pet"
	elif roll < 0.05:
		return "mount"
	return ""

func _random_position() -> Vector3:
	return Vector3(
		_rng.randf_range(-50.0, 50.0),
		0.0,
		_rng.randf_range(-50.0, 50.0)
	)
