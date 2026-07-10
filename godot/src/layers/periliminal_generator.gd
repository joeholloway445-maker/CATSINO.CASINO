extends Node
class_name PeriliminalGenerator

# Generates a personalized Periliminal gauntlet based on Hope profile

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

func generate_gauntlet() -> Dictionary:
	var hope_profile = Hope.get_profile()
	var difficulty_curve = PeriliminalRuns.difficulty()

	# Calculate minimum depth required
	var min_depth = _calculate_min_depth(hope_profile, difficulty_curve)
	var max_depth = mini(min_depth + 10, 25)  # Cap at 25 floors

	# Generate floors
	var floors = []
	for floor_num in range(min_depth):
		floors.append(_generate_floor(floor_num, hope_profile, difficulty_curve))

	return {
		"min_depth": min_depth,
		"max_depth": max_depth,
		"floors": floors,
		"seed": randi(),
		"difficulty": difficulty_curve,
		"blessing_depth": PeriliminalRuns.blessing_depth()
	}

func _calculate_min_depth(profile: Dictionary, difficulty: float) -> int:
	var base_depth = 8

	# Each axis adds depth based on intensity
	var aggression_depth = int(profile.get("aggression", 0) * 1.2)  # Aggressive = deeper
	var caution_depth = int(profile.get("caution", 0) * 1.0)        # Cautious = slightly deeper
	var curiosity_depth = int(profile.get("curiosity", 0) * 1.3)    # Curious = deeper
	var greed_depth = int(profile.get("greed", 0) * 1.1)            # Greedy = deeper
	var fear_depth = int(profile.get("fear", 0) * 1.5)              # Fearful = much deeper
	var anxiety_depth = int(profile.get("anxiety", 0) * 1.6)        # Anxious = deepest

	var total = base_depth + aggression_depth + caution_depth + curiosity_depth + greed_depth + fear_depth + anxiety_depth

	# Difficulty multiplier
	if difficulty > 1.5:
		total += int((difficulty - 1.5) * 7)  # Cruel players go deeper

	return clamp(total, 8, 20)

func _generate_floor(floor_num: int, profile: Dictionary, difficulty: float) -> Dictionary:
	# Determine primary trap type for this floor (cycle through axes)
	var trap_type = TRAP_TYPES[floor_num % TRAP_TYPES.size()]
	var axis_index = floor_num % TRAP_AXES.size()
	var trap_axis = TRAP_AXES[axis_index]

	# Scale difficulty by floor depth
	var floor_difficulty = clamp(1.0 + (float(floor_num) / 20.0) * difficulty, 1.0, 3.0)

	# Generate trap-specific content
	var trap = TrapFloor.new()
	trap.trap_type = trap_type
	trap.difficulty = int(floor_difficulty * 100)
	trap.psychological_weight = float(floor_num) / 20.0  # Weight increases toward bottom

	match trap_type:
		"arena_combat":
			trap = _generate_arena_trap(floor_num, profile["aggression"], floor_difficulty)
		"falling_certainties":
			trap = _generate_certainty_trap(floor_num, profile["caution"], floor_difficulty)
		"forbidden_library":
			trap = _generate_library_trap(floor_num, profile["curiosity"], floor_difficulty)
		"infinite_vault":
			trap = _generate_vault_trap(floor_num, profile["greed"], floor_difficulty)
		"personified_terror":
			trap = _generate_terror_trap(floor_num, profile["fear"], floor_difficulty)
		"halls_of_desire":
			trap = _generate_desire_trap(floor_num, profile["lust"], floor_difficulty)
		"waiting_room":
			trap = _generate_waiting_trap(floor_num, profile["boredom"], floor_difficulty)
		"moral_gauntlet":
			trap = _generate_moral_trap(floor_num, profile["anxiety"], floor_difficulty)

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
		"safe_zones": max(1, int(3 - (floor_num / 5.0)))
	})

	# Exit: win all arena battles
	trap.exits.append("defeat_all_entities")

	return trap

func _generate_certainty_trap(floor_num: int, caution: float, difficulty: float) -> TrapFloor:
	var trap = TrapFloor.new()
	trap.trap_type = "falling_certainties"
	trap.difficulty = int(difficulty * 100)

	# Non-Euclidean hallway with unstable floor
	trap.hazards.append({
		"type": "unstable_floor",
		"safe_tiles_percentage": int(50.0 - (caution * 20.0)),
		"fall_damage": int(20.0 * difficulty)
	})

	# Illusion entities (not real threats)
	for i in range(2):
		trap.entities.append("psyche_illusion_%d" % floor_num)

	# Exit: walk forward despite uncertainty
	trap.exits.append("reach_hallway_end")

	return trap

func _generate_library_trap(floor_num: int, curiosity: float, difficulty: float) -> TrapFloor:
	var trap = TrapFloor.new()
	trap.trap_type = "forbidden_library"
	trap.difficulty = int(difficulty * 100)

	# Knowledge costs: each book read drains something precious
	var book_count = int(3 + (floor_num / 4.0) + (curiosity * 5.0))
	trap.hazards.append({
		"type": "knowledge_cost",
		"books": book_count,
		"cost_per_book": ["memory", "stat_temporary", "lifespan"][int(floor_num / 7.0)]
	})

	# Exit: leave without reading the final book
	trap.exits.append("resist_knowledge")

	return trap

func _generate_vault_trap(floor_num: int, greed: float, difficulty: float) -> TrapFloor:
	var trap = TrapFloor.new()
	trap.trap_type = "infinite_vault"
	trap.difficulty = int(difficulty * 100)

	# Infinite resources but deeper = more dangerous
	var depth_into_vault = floor_num
	trap.hazards.append({
		"type": "environmental_danger",
		"pressure": int(10.0 * (depth_into_vault / 20.0)),
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

	# Manifestation of player's personal fears (from profile)
	trap.entities.append("terror_manifestation_%d" % floor_num)

	# Terror increases with floor depth
	trap.hazards.append({
		"type": "psychological_pressure",
		"sanity_drain": int(5.0 * (float(floor_num) / 20.0)),
		"hallucinations": true,
		"escape_chance": max(10, int(50.0 - (fear * 30.0)))
	})

	# Exit: face the terror or run
	trap.exits.append("confront_terror")
	trap.exits.append("flee_terror")

	return trap

func _generate_desire_trap(floor_num: int, lust: float, difficulty: float) -> TrapFloor:
	var trap = TrapFloor.new()
	trap.trap_type = "halls_of_desire"
	trap.difficulty = int(difficulty * 100)

	# Everything the player desires is available
	trap.hazards.append({
		"type": "hollow_satisfaction",
		"emptiness_per_indulgence": int(10.0 * (float(floor_num) / 20.0)),
		"identity_erosion": true
	})

	# Exit: turn away from all desire
	trap.exits.append("walk_alone")

	return trap

func _generate_waiting_trap(floor_num: int, boredom: float, difficulty: float) -> TrapFloor:
	var trap = TrapFloor.new()
	trap.trap_type = "waiting_room"
	trap.difficulty = int(difficulty * 100)

	# Nothing happens. You wait.
	trap.hazards.append({
		"type": "temporal_stasis",
		"requires_time_passage": int(30 - (boredom * 10.0)),  # Bored players escape faster
		"despair_buildup": true
	})

	# Exit: accept stasis and walk out
	trap.exits.append("accept_waiting")

	return trap

func _generate_moral_trap(floor_num: int, anxiety: float, difficulty: float) -> TrapFloor:
	var trap = TrapFloor.new()
	trap.trap_type = "moral_gauntlet"
	trap.difficulty = int(difficulty * 100)

	# Series of impossible moral choices
	var choice_count = int(2 + (floor_num / 5.0))
	trap.hazards.append({
		"type": "moral_dilemma",
		"choices": choice_count,
		"accumulated_guilt": true,
		"sanity_cost": int(10.0 * anxiety)
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
	# Pick a random entity from EntityDexData for given category and stage
	var stage_clamped = clamp(stage, 1, 3)
	return "entity_%s_%d" % [category.to_lower(), stage_clamped]
