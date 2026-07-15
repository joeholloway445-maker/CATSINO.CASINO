class_name NPCGenerator
## Procedural NPC generator: 1,000+ unique realistic humans from
## data/npc_templates.json. Deterministic per seed — the same seed_key
## rebuilds the identical roster every boot (project convention:
## rng.seed = hash("thing_" + id)).
##
## Realism contract (docs/VISUAL_DIRECTION_ESO.md): output appearance
## params are NATURAL-HUMAN values — heights in meters inside adult range,
## skin tones from a 7-step natural palette, hair colors as real-world
## hexes with age-based greying. NpcBody consumes these; nothing here is
## stylized or cartoon-scaled.

const TEMPLATES_PATH := "res://data/npc_templates.json"
const ARCHETYPES := ["barista", "archivist", "authority", "lover", "reflection"]
const LAYERS := ["subliminal", "liminal", "supraliminal", "hyperliminal", "extraliminal", "periliminal"]
const DISTRICTS_PER_LAYER := {
	"subliminal": ["player_apartment"],
	"liminal": ["liminal_hub"],
	"supraliminal": ["dallas", "fort_worth", "denton", "arlington"],
	"hyperliminal": ["catsino_main", "catsino_vip"],
	"extraliminal": ["territories"],
	"periliminal": ["abstract_realm"],
}

## Natural skin palette (from docs/METAHUMAN_NPC_PIPELINE.md tone list).
const SKIN_HEX := {
	"pale":   "f2ebd9",
	"fair":   "e6d9bf",
	"olive":  "d9bfa6",
	"tan":    "bf9980",
	"medium": "b38066",
	"dark":   "99664d",
	"deep":   "734026",
}

## Real-world hair colors. "purple" stays a muted, plausibly-dyed plum —
## artistic archetypes dye their hair; nobody's head glows.
const HAIR_HEX := {
	"black":    "18120e",
	"brown":    "3b2a20",
	"auburn":   "5c3220",
	"red":      "7a3b24",
	"dark_red": "4d2019",
	"blonde":   "b08d57",
	"grey":     "8c8c8c",
	"white":    "d9d9d9",
	"purple":   "46345c",
}

## Adult stature ranges (meters) by name-pool flavor; build nudges it.
const HEIGHT_RANGE := {
	"first_names_feminine":  Vector2(1.55, 1.78),
	"first_names_masculine": Vector2(1.66, 1.91),
	"first_names_neutral":   Vector2(1.60, 1.85),
}
const BUILD_HEIGHT_NUDGE := {
	"slim": 0.0, "average": 0.0, "athletic": 0.015, "muscular": 0.03,
}

## Chassis base tones per archetype (the currently-installed body mesh is
## the tps-demo player robot, not a human — see NpcBody). Each is jittered
## per NPC so an archetype reads as a family, not 1,000 identical bots.
const CHASSIS_BASE_HEX := {
	"barista":    "a9825a",  # brass/copper — service-counter warmth
	"archivist":  "5c5a52",  # aged bronze/graphite — old paper, old metal
	"authority":  "3a3d42",  # gunmetal — the power-holder's plating
	"lover":      "7a2f3d",  # deep jewel red — magnetic, a little dangerous
	"reflection": "463a5c",  # violet-pearl — the uncanny one
}

var _templates: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _generated_cache: Dictionary = {}  # npc_id -> NPC dict

func _init() -> void:
	_load_templates()

func _load_templates() -> void:
	if not FileAccess.file_exists(TEMPLATES_PATH):
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

## Generate N unique NPCs for one layer (or mixed layers when "" is passed).
## Deterministic: same seed_key → same roster.
func generate_npcs(count: int, seed_key: String, layer_filter: String = "") -> Array[Dictionary]:
	_rng.seed = hash(seed_key)
	var result: Array[Dictionary] = []
	for i in range(count):
		var npc := _generate_single("npc_gen_%s_%d" % [seed_key, i], layer_filter)
		if not npc.is_empty():
			result.append(npc)
			_generated_cache[npc.id] = npc
	return result

## Generate (or fetch) a single NPC by id — deterministic per id.
func generate_npc(npc_id: String, layer: String = "") -> Dictionary:
	if _generated_cache.has(npc_id):
		return _generated_cache[npc_id]
	_rng.seed = hash(npc_id)
	var npc := _generate_single(npc_id, layer)
	if not npc.is_empty():
		_generated_cache[npc_id] = npc
	return npc

func get_npc(npc_id: String) -> Dictionary:
	return _generated_cache.get(npc_id, {})

## ── Private generation ────────────────────────────────────────────────────
func _generate_single(npc_id: String, layer_filter: String) -> Dictionary:
	if _templates.is_empty():
		return {}

	var layer: String = layer_filter if layer_filter != "" else str(LAYERS[_rng.randi() % LAYERS.size()])
	var districts: Array = DISTRICTS_PER_LAYER.get(layer, ["default"])
	var district := str(districts[_rng.randi() % districts.size()])

	var archetype_id: String = str(ARCHETYPES[_rng.randi() % ARCHETYPES.size()])
	var archetype := _get_archetype(archetype_id)
	if archetype.is_empty():
		return {}

	var layer_variant := _get_layer_variant(layer)
	var pool_key: String = ["first_names_neutral", "first_names_feminine", "first_names_masculine"][_rng.randi() % 3]
	var name_str := _generate_name(pool_key, archetype_id, layer)
	var age := _roll_age(archetype)
	var appearance := _generate_appearance(archetype, layer_variant, pool_key, age, archetype_id)
	var disposition := _get_disposition()
	var schedule := _get_schedule()
	var pos := _random_position()

	# Matches the WorldLoader npcs.json shape so handcrafted + generated
	# NPCs flow through the same spawner / dialogue UI unchanged.
	return {
		"id": npc_id,
		"name": name_str,
		"district": district,
		"layer": layer,
		"archetype": archetype_id,
		"role": str(archetype.get("role", "ambient")),
		"faction": _pick_faction(layer),
		"emoji": "👤",
		"greeting": NpcDialogueLibrary.greeting(archetype_id, layer),
		"position": {"x": pos.x, "y": pos.y, "z": pos.z},
		"shop_id": _generate_shop_id(archetype_id, district) if _rng.randf() < 0.15 else "",
		"quest_ids": _generate_quest_ids(archetype_id, layer),
		# Shared lore block per archetype × layer (see NpcDialogueLibrary).
		"dialogue_id": "%s_%s" % [archetype_id, layer],
		"dialogue_key": "%s_%s" % [archetype_id, layer],
		"appearance": appearance,
		"age": age,
		"disposition": str(disposition.get("mood", "neutral")),
		"daily_schedule": str(schedule.get("name", "vendor")),
		"availability": float(schedule.get("availability", 0.8)) * float(disposition.get("quest_availability", 0.8)),
		"lod_level": 0,
		"recruitable_as": _pick_recruitable_type(),
	}

func _get_archetype(id: String) -> Dictionary:
	for arch in _templates.get("archetypes", []):
		if arch.get("id", "") == id:
			return arch
	return {}

func _get_layer_variant(layer: String) -> Dictionary:
	for lv in _templates.get("layer_variants", []):
		if lv.get("layer", "") == layer:
			return lv
	return {}

func _generate_name(pool_key: String, archetype_id: String, layer: String) -> String:
	# The Periliminal Reflection is literally the player's mirror — it does
	# not get a stranger's name (see LORE_QUESTS_AND_NPCS.md).
	if archetype_id == "reflection" and layer == "periliminal":
		return "...You?"
	var pools: Dictionary = _templates.get("name_pools", {})
	var firsts: Array = pools.get(pool_key, ["Alex"])
	var lasts: Array = pools.get("last_names", ["Stone"])
	var first := str(firsts[_rng.randi() % firsts.size()]) if not firsts.is_empty() else "Alex"
	var last := str(lasts[_rng.randi() % lasts.size()]) if not lasts.is_empty() else "Stone"
	return "%s %s" % [first, last]

func _roll_age(archetype: Dictionary) -> int:
	var age_range: Dictionary = archetype.get("traits", {}).get("age", {"min": 20, "max": 65})
	return _rng.randi_range(int(age_range.get("min", 20)), int(age_range.get("max", 65)))

func _generate_appearance(archetype: Dictionary, layer_variant: Dictionary, pool_key: String, age: int, archetype_id: String) -> Dictionary:
	var traits: Dictionary = archetype.get("traits", {})
	var builds: Array = traits.get("build", ["average"])
	var hair_colors: Array = traits.get("hair_colors", ["brown"])
	var hair_styles: Array = traits.get("hair_styles", ["short"])
	var skin_tones: Array = traits.get("skin_tones", ["fair"])

	var build := str(builds[_rng.randi() % builds.size()])
	var skin := str(skin_tones[_rng.randi() % skin_tones.size()])
	var hair := str(hair_colors[_rng.randi() % hair_colors.size()])

	# Age greys hair naturally: rising odds past 45, white territory past 65.
	if age > 45 and _rng.randf() < float(age - 45) / 30.0:
		hair = "white" if (age > 65 and _rng.randf() < 0.5) else "grey"

	# Two gaussian-ish rolls average toward the middle of the range —
	# crowds cluster around average height with believable outliers.
	var hr: Vector2 = HEIGHT_RANGE.get(pool_key, Vector2(1.60, 1.85))
	var t := (_rng.randf() + _rng.randf()) * 0.5
	var height := lerpf(hr.x, hr.y, t) + float(BUILD_HEIGHT_NUDGE.get(build, 0.0))

	# Layer-appropriate outfit from the template's modifier table.
	var outfit := str(traits.get("outfit_base", "casual"))
	var mods: Dictionary = layer_variant.get("outfit_modifiers", {})
	var outfit_options: Array = mods.get(archetype_id, [])
	if not outfit_options.is_empty():
		outfit = str(outfit_options[_rng.randi() % outfit_options.size()])

	return {
		"build": build,
		"height_m": snappedf(height, 0.01),
		"hair_color": hair,
		"hair_color_hex": str(HAIR_HEX.get(hair, "3b2a20")),
		"hair_style": str(hair_styles[_rng.randi() % hair_styles.size()]),
		"skin_tone": skin,
		"skin_tone_hex": str(SKIN_HEX.get(skin, "d9bfa6")),
		"chassis_hex": _jittered_hex(str(CHASSIS_BASE_HEX.get(archetype_id, "888888"))),
		"outfit": outfit,
		"layer_color_palette": layer_variant.get("color_palette", ["neutral"]),
		"lighting": str(layer_variant.get("lighting", "daylight")),
	}

## Jitters a base hex color's value/saturation per NPC (±12%) so an
## archetype family reads as individuals sharing a palette, not clones.
func _jittered_hex(base_hex: String) -> String:
	var c := Color(base_hex)
	var h := c.h
	var s := clampf(c.s * _rng.randf_range(0.85, 1.15), 0.0, 1.0)
	var v := clampf(c.v * _rng.randf_range(0.85, 1.15), 0.0, 1.0)
	return Color.from_hsv(h, s, v).to_html(false)

func _get_disposition() -> Dictionary:
	var dispositions: Array = _templates.get("dispositions", [])
	if dispositions.is_empty():
		return {"mood": "neutral", "greeting_shift": 0.0, "quest_availability": 0.8}
	return dispositions[_rng.randi() % dispositions.size()].duplicate()

func _get_schedule() -> Dictionary:
	var schedules: Array = _templates.get("daily_schedules", [])
	if schedules.is_empty():
		return {"name": "vendor", "hours": "8-18", "availability": 0.8}
	return schedules[_rng.randi() % schedules.size()].duplicate()

func _generate_quest_ids(archetype_id: String, layer: String) -> Array:
	# ~30% of NPCs can point the player at their archetype's layer quest
	# hook (quest content itself lives with QuestManager / world_data).
	if _rng.randf() < 0.3:
		return ["hook_%s_%s" % [archetype_id, layer]]
	return []

func _generate_shop_id(archetype_id: String, district: String) -> String:
	var shop_types := {
		"barista": "cafe",
		"archivist": "library",
		"authority": "garrison",
		"lover": "salon",
		"reflection": "curiosities",
	}
	return "%s_%s_%d" % [district, str(shop_types.get(archetype_id, "general")), _rng.randi() % 10]

func _pick_faction(layer: String) -> String:
	# The Subliminal is private and pre-factional; its figures read neutral.
	if layer == "subliminal":
		return "Factionless"
	return ["SovereignCrown", "VeiledCurrent", "WildlandsAscendant", "Factionless"][_rng.randi() % 4]

func _pick_recruitable_type() -> String:
	var roll := _rng.randf()
	if roll < 0.02:
		return "companion"
	elif roll < 0.04:
		return "pet"
	elif roll < 0.05:
		return "mount"
	return ""

func _random_position() -> Vector3:
	return Vector3(_rng.randf_range(-50.0, 50.0), 0.0, _rng.randf_range(-50.0, 50.0))
