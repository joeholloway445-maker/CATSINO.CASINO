extends Node
class_name PeriliminalGenerator

# Generates a personalized Periliminal gauntlet based on Hope profile.
# Floors are real content packs (entities + hazards + exits) applied by
# LayerWorld — not a denser random-spawn stand-in.

const TRAP_TYPES = [
	"arena_combat",       # Aggression trap
	"falling_certainties", # Caution trap
	"forbidden_library",  # Curiosity trap
	"infinite_vault",     # Greed trap
	"personified_terror", # Fear trap
	"halls_of_desire",    # Lust trap
	"waiting_room",       # Boredom trap
	"moral_gauntlet"      # Anxiety trap
]

const TRAP_AXES = [
	"aggression",
	"caution",
	"curiosity",
	"greed",
	"fear",
	"lust",
	"boredom",
	"anxiety"
]

class TrapFloor:
	var trap_type: String
	var difficulty: int
	var entities: Array[String]
	var hazards: Array[Dictionary]
	var exits: Array[String]
	var psychological_weight: float

var _rng := RandomNumberGenerator.new()

## `p_seed` makes dungeon / wipe-run gauntlets deterministic per ledger seed.
func generate_gauntlet(p_seed: int = 0) -> Dictionary:
	var hope_profile: Dictionary = {}
	if Hope != null and Hope.has_method("combat_profile"):
		hope_profile = Hope.combat_profile()
	else:
		hope_profile = {
			"aggression": 0.5, "caution": 0.5, "curiosity": 0.5, "greed": 0.5,
			"fear": 0.0, "lust": 0.0, "boredom": 0.0, "anxiety": 0.0,
		}
	var difficulty_curve := 1.0
	if PeriliminalRuns != null and PeriliminalRuns.has_method("difficulty"):
		difficulty_curve = float(PeriliminalRuns.difficulty())

	var used_seed := p_seed if p_seed != 0 else randi()
	_rng.seed = used_seed

	# Calculate minimum depth required
	var min_depth = _calculate_min_depth(hope_profile, difficulty_curve)
	var max_depth = mini(min_depth + 10, 25)  # Cap at 25 floors

	# Generate floors
	var floors = []
	for floor_num in range(min_depth):
		floors.append(_generate_floor(floor_num, hope_profile, difficulty_curve))

	var blessing := 3
	if PeriliminalRuns != null and PeriliminalRuns.has_method("blessing_depth"):
		blessing = int(PeriliminalRuns.blessing_depth())

	return {
		"min_depth": min_depth,
		"max_depth": max_depth,
		"floors": floors,
		"seed": used_seed,
		"difficulty": difficulty_curve,
		"blessing_depth": blessing
	}

## Resolve a floor entity token (`DEX_ID@stage` or legacy/special tokens)
## into `{line, stage}` for WorldEntity.setup.
static func resolve_entity_token(token: String) -> Dictionary:
	var raw := str(token)
	if raw.is_empty():
		return {}
	var stage := 1
	var id_part := raw
	if "@" in raw:
		var bits := raw.split("@")
		id_part = bits[0]
		stage = clampi(int(bits[1]) if bits.size() > 1 else 1, 1, 3)
	elif raw.begins_with("entity_"):
		# Legacy placeholder: entity_<category>_<stage>
		var parts := raw.split("_")
		if parts.size() >= 3:
			var cat := parts[1].capitalize()
			stage = clampi(int(parts[2]), 1, 3)
			var faction := "Factionless"
			if PlayerProfile != null:
				faction = CompanionRegistry.normalize_faction(PlayerProfile.faction)
			var line := EntityDexData.random_line_in_category(faction, cat)
			if line.is_empty():
				return {}
			return {"line": line, "stage": stage}
	elif raw.begins_with("psyche_illusion") or raw.begins_with("terror_manifestation"):
		var faction2 := "Factionless"
		if PlayerProfile != null:
			faction2 = CompanionRegistry.normalize_faction(PlayerProfile.faction)
		var psyche := EntityDexData.random_line_in_category(faction2, "Psyche")
		if psyche.is_empty():
			return {}
		return {"line": psyche, "stage": 2 if raw.begins_with("terror") else 1}
	var found := EntityDexData.by_id(id_part)
	if found.is_empty():
		return {}
	return {"line": found, "stage": stage}

func _calculate_min_depth(profile: Dictionary, difficulty: float) -> int:
	var base_depth = 8

	# Each axis adds depth based on intensity
	var aggression_depth = int(float(profile.get("aggression", 0)) * 1.2)
	var caution_depth = int(float(profile.get("caution", 0)) * 1.0)
	var curiosity_depth = int(float(profile.get("curiosity", 0)) * 1.3)
	var greed_depth = int(float(profile.get("greed", 0)) * 1.1)
	var fear_depth = int(float(profile.get("fear", 0)) * 1.5)
	var anxiety_depth = int(float(profile.get("anxiety", 0)) * 1.6)

	var total = base_depth + aggression_depth + caution_depth + curiosity_depth + greed_depth + fear_depth + anxiety_depth

	# Difficulty multiplier
	if difficulty > 1.5:
		total += int((difficulty - 1.5) * 7)  # Cruel players go deeper

	return clampi(total, 8, 20)

func _generate_floor(floor_num: int, profile: Dictionary, difficulty: float) -> Dictionary:
	# Determine primary trap type for this floor (cycle through axes)
	var trap_type = TRAP_TYPES[floor_num % TRAP_TYPES.size()]

	# Scale difficulty by floor depth
	var floor_difficulty = clampf(1.0 + (float(floor_num) / 20.0) * difficulty, 1.0, 3.0)

	# Generate trap-specific content
	var trap = TrapFloor.new()
	match trap_type:
		"arena_combat":
			trap = _generate_arena_trap(floor_num, float(profile.get("aggression", 0.5)), floor_difficulty)
		"falling_certainties":
			trap = _generate_certainty_trap(floor_num, float(profile.get("caution", 0.5)), floor_difficulty)
		"forbidden_library":
			trap = _generate_library_trap(floor_num, float(profile.get("curiosity", 0.5)), floor_difficulty)
		"infinite_vault":
			trap = _generate_vault_trap(floor_num, float(profile.get("greed", 0.5)), floor_difficulty)
		"personified_terror":
			trap = _generate_terror_trap(floor_num, float(profile.get("fear", 0.0)), floor_difficulty)
		"halls_of_desire":
			trap = _generate_desire_trap(floor_num, float(profile.get("lust", 0.0)), floor_difficulty)
		"waiting_room":
			trap = _generate_waiting_trap(floor_num, float(profile.get("boredom", 0.0)), floor_difficulty)
		"moral_gauntlet":
			trap = _generate_moral_trap(floor_num, float(profile.get("anxiety", 0.0)), floor_difficulty)

	return {
		"floor": floor_num,
		"trap_type": trap.trap_type,
		"difficulty": trap.difficulty,
		"entities": trap.entities,
		"hazards": trap.hazards,
		"exits": trap.exits,
		"weight": trap.psychological_weight,
		"description": _describe_floor(trap_type, floor_num)
	}

func _generate_arena_trap(floor_num: int, aggression: float, difficulty: float) -> TrapFloor:
	var trap = TrapFloor.new()
	trap.trap_type = "arena_combat"
	trap.difficulty = int(difficulty * 100)
	trap.psychological_weight = float(floor_num) / 20.0

	# Generate entities for arena
	var entity_count = int(1 + (floor_num / 5.0) + (aggression * 0.5))
	var entity_categories = ["Energy", "Gravity", "Matter"]  # Combat-focused

	for i in range(entity_count):
		var category = entity_categories[i % entity_categories.size()]
		var entity_id = _pick_random_entity(category, int(floor_num / 3.0) + 1)
		trap.entities.append(entity_id)

	# Arena hazards: damaging floor, walls closing in
	trap.hazards.append({
		"type": "damage_floor",
		"damage_per_second": int(5.0 * difficulty),
		"safe_zones": maxi(1, int(3 - (floor_num / 5.0)))
	})

	# Exit: win all arena battles
	trap.exits.append("defeat_all_entities")

	return trap

func _generate_certainty_trap(floor_num: int, caution: float, difficulty: float) -> TrapFloor:
	var trap = TrapFloor.new()
	trap.trap_type = "falling_certainties"
	trap.difficulty = int(difficulty * 100)
	trap.psychological_weight = float(floor_num) / 20.0

	# Non-Euclidean hallway with unstable floor
	trap.hazards.append({
		"type": "unstable_floor",
		"safe_tiles_percentage": int(50.0 - (caution * 20.0)),
		"fall_damage": int(20.0 * difficulty)
	})

	# Illusion entities (not real threats)
	for i in range(2):
		trap.entities.append(_pick_random_entity("Psyche", 1))

	# Exit: walk forward despite uncertainty
	trap.exits.append("reach_hallway_end")

	return trap

func _generate_library_trap(floor_num: int, curiosity: float, difficulty: float) -> TrapFloor:
	var trap = TrapFloor.new()
	trap.trap_type = "forbidden_library"
	trap.difficulty = int(difficulty * 100)
	trap.psychological_weight = float(floor_num) / 20.0

	# Knowledge costs: each book read drains something precious
	var book_count = int(3 + (floor_num / 4.0) + (curiosity * 5.0))
	trap.hazards.append({
		"type": "knowledge_cost",
		"books": book_count,
		"cost_per_book": ["memory", "stat_temporary", "lifespan"][int(floor_num / 7.0) % 3]
	})

	# Exit: leave without reading the final book
	trap.exits.append("resist_knowledge")

	return trap

func _generate_vault_trap(floor_num: int, greed: float, difficulty: float) -> TrapFloor:
	var trap = TrapFloor.new()
	trap.trap_type = "infinite_vault"
	trap.difficulty = int(difficulty * 100)
	trap.psychological_weight = float(floor_num) / 20.0

	# Infinite resources but deeper = more dangerous
	var depth_into_vault = floor_num
	trap.hazards.append({
		"type": "environmental_danger",
		"pressure": int(10.0 * (float(depth_into_vault) / 20.0) * (1.0 + greed)),
		"toxic_gas": true
	})

	# Guardian entities in deeper sections
	if depth_into_vault > 5:
		trap.entities.append(_pick_random_entity("Gravity", int(depth_into_vault / 3.0)))

	# Exit: leave with what you have
	trap.exits.append("exit_vault")

	return trap

func _generate_terror_trap(floor_num: int, fear: float, difficulty: float) -> TrapFloor:
	var trap = TrapFloor.new()
	trap.trap_type = "personified_terror"
	trap.difficulty = int(difficulty * 100)
	trap.psychological_weight = float(floor_num) / 20.0

	# Manifestation of player's personal fears (from profile)
	trap.entities.append(_pick_random_entity("Psyche", clampi(2 + int(fear * 2.0), 2, 3)))

	# Terror increases with floor depth
	trap.hazards.append({
		"type": "psychological_pressure",
		"sanity_drain": maxi(1, int(5.0 * (float(floor_num) / 20.0) * difficulty)),
		"hallucinations": true,
		"escape_chance": maxi(10, int(50.0 - (fear * 30.0)))
	})

	# Exit: face the terror or run
	trap.exits.append("confront_terror")
	trap.exits.append("flee_terror")

	return trap

func _generate_desire_trap(floor_num: int, lust: float, difficulty: float) -> TrapFloor:
	var trap = TrapFloor.new()
	trap.trap_type = "halls_of_desire"
	trap.difficulty = int(difficulty * 100)
	trap.psychological_weight = float(floor_num) / 20.0

	# Everything the player desires is available
	trap.hazards.append({
		"type": "hollow_satisfaction",
		"emptiness_per_indulgence": int(10.0 * (float(floor_num) / 20.0) * (1.0 + lust)),
		"identity_erosion": true
	})

	# Exit: turn away from all desire
	trap.exits.append("walk_alone")

	return trap

func _generate_waiting_trap(floor_num: int, boredom: float, difficulty: float) -> TrapFloor:
	var trap = TrapFloor.new()
	trap.trap_type = "waiting_room"
	trap.difficulty = int(difficulty * 100)
	trap.psychological_weight = float(floor_num) / 20.0

	# Nothing happens. You wait.
	trap.hazards.append({
		"type": "temporal_stasis",
		"requires_time_passage": int(30 - (boredom * 10.0)),  # Bored players escape faster
		"despair_buildup": true,
		"drain": maxi(1, int(2.0 * difficulty))
	})

	# Exit: accept stasis and walk out
	trap.exits.append("accept_waiting")

	return trap

func _generate_moral_trap(floor_num: int, anxiety: float, difficulty: float) -> TrapFloor:
	var trap = TrapFloor.new()
	trap.trap_type = "moral_gauntlet"
	trap.difficulty = int(difficulty * 100)
	trap.psychological_weight = float(floor_num) / 20.0

	# Series of impossible moral choices
	var choice_count = int(2 + (floor_num / 5.0))
	trap.hazards.append({
		"type": "moral_dilemma",
		"choices": choice_count,
		"accumulated_guilt": true,
		"sanity_cost": maxi(1, int(10.0 * maxf(anxiety, 0.2) * difficulty))
	})

	# Exit: commit to a choice despite uncertainty
	trap.exits.append("make_final_choice")

	return trap

func _describe_floor(trap_type: String, floor_num: int) -> String:
	var descriptions = {
		"arena_combat": "Arena Floor %d: The ground shakes. Entities await." % floor_num,
		"falling_certainties": "Hallway %d: Every step could be your last." % floor_num,
		"forbidden_library": "Library %d: Infinite knowledge, infinite cost." % floor_num,
		"infinite_vault": "Vault %d: The deeper you go, the less you breathe." % floor_num,
		"personified_terror": "Chamber %d: Something wears your fears." % floor_num,
		"halls_of_desire": "Hall %d: Everything you want is here." % floor_num,
		"waiting_room": "Room %d: Nothing moves. Nothing changes." % floor_num,
		"moral_gauntlet": "Trial %d: No good choices remain." % floor_num,
	}
	return descriptions.get(trap_type, "Unknown Floor %d" % floor_num)

func _pick_random_entity(category: String, stage: int) -> String:
	# Real EntityDexData line id + stage — LayerWorld spawns these as WorldEntity.
	var stage_clamped := clampi(stage, 1, 3)
	var faction := "Factionless"
	if PlayerProfile != null:
		faction = CompanionRegistry.normalize_faction(PlayerProfile.faction)
	var line := EntityDexData.random_line_in_category(faction, category, _rng)
	if line.is_empty():
		return "entity_%s_%d" % [category.to_lower(), stage_clamped]
	return "%s@%d" % [str(line.get("id", "")), stage_clamped]
