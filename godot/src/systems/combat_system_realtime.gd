extends Node
class_name CombatSystemRealtime

# LIVE ACTION COMBAT - No turns, real-time cooldowns, positioning-based abilities

signal combat_started(player_id: String, enemy_id: String)
signal ability_used(attacker_id: String, ability_id: String, target_id: String, damage: int)
signal damage_dealt(source: String, target: String, amount: int, crit: bool, distance: float)
signal status_applied(target_id: String, status: String, duration: float)
signal ability_ready(actor_id: String, ability_id: String)
signal ability_on_cooldown(actor_id: String, ability_id: String, remaining: float)
signal combat_ended(winner_id: String, loser_id: String, stats: Dictionary)
signal entity_defeated(entity_id: String, conqueror_id: String, loot: Array)

# Live action parameters
const ABILITY_DATABASE = {
	# SOVEREIGN CROWN - Crown abilities
	"solar_strike": {
		"name": "Solar Strike",
		"faction": "SovereignCrown",
		"type": "damage",
		"damage_base": 75,
		"energy_cost": 25,
		"cooldown": 2.5,
		"range": 5.0,
		"cast_time": 0.6,
		"description": "Harness solar energy for a powerful strike",
		"animation": "slash_yellow"
	},
	"precision_strike": {
		"name": "Precision Strike",
		"faction": "SovereignCrown",
		"type": "damage",
		"damage_base": 50,
		"energy_cost": 15,
		"cooldown": 1.0,
		"crit_chance": 0.35,
		"range": 3.0,
		"cast_time": 0.3,
		"description": "Strike with calculated precision for increased crit chance"
	},
	"shield_wall": {
		"name": "Shield Wall",
		"faction": "SovereignCrown",
		"type": "defense",
		"damage_reduction": 0.4,
		"energy_cost": 20,
		"cooldown": 3.5,
		"duration": 5.0,
		"range": 0.0,
		"cast_time": 0.8,
		"description": "Defend against incoming damage"
	},
	"order_decree": {
		"name": "Order Decree",
		"faction": "SovereignCrown",
		"type": "support",
		"energy_cost": 30,
		"cooldown": 4.0,
		"range": 15.0,
		"cast_time": 1.0,
		"effect": "damage_buff",
		"buff_amount": 0.25,
		"duration": 6.0,
		"description": "Grant allies increased damage output"
	},

	# VEILED CURRENT - Mystical abilities
	"shadow_strike": {
		"name": "Shadow Strike",
		"faction": "VeiledCurrent",
		"type": "damage",
		"damage_base": 65,
		"energy_cost": 20,
		"cooldown": 2.0,
		"range": 4.0,
		"cast_time": 0.5,
		"evasion_bonus": 0.15,
		"description": "Strike from darkness with evasion bonus"
	},
	"dream_veil": {
		"name": "Dream Veil",
		"faction": "VeiledCurrent",
		"type": "control",
		"energy_cost": 25,
		"cooldown": 3.0,
		"range": 6.0,
		"cast_time": 0.7,
		"effect": "confusion",
		"status_chance": 0.5,
		"duration": 4.0,
		"description": "Confuse enemies with illusory barriers"
	},
	"prophecy_strike": {
		"name": "Prophecy Strike",
		"faction": "VeiledCurrent",
		"type": "damage",
		"damage_base": 80,
		"energy_cost": 35,
		"cooldown": 4.0,
		"range": 7.0,
		"cast_time": 1.2,
		"description": "Strike with knowledge of future outcomes"
	},
	"temporal_loop": {
		"name": "Temporal Loop",
		"faction": "VeiledCurrent",
		"type": "utility",
		"energy_cost": 40,
		"cooldown": 6.0,
		"range": 0.0,
		"cast_time": 1.5,
		"effect": "reset_cooldowns",
		"description": "Reset your ability cooldowns (rare ultimate)"
	},

	# WILDLANDS ASCENDANT - Primal abilities
	"feral_strike": {
		"name": "Feral Strike",
		"faction": "WildlandsAscendant",
		"type": "damage",
		"damage_base": 70,
		"energy_cost": 18,
		"cooldown": 1.5,
		"range": 3.0,
		"cast_time": 0.4,
		"lifesteal": 0.3,
		"description": "Strike savagely, stealing health from enemy"
	},
	"evolution_surge": {
		"name": "Evolution Surge",
		"faction": "WildlandsAscendant",
		"type": "buff",
		"energy_cost": 25,
		"cooldown": 5.0,
		"range": 0.0,
		"cast_time": 0.9,
		"effect": "self_buff",
		"stat_boost": {"strength": 20, "agility": 15},
		"duration": 8.0,
		"description": "Temporarily boost your physical stats"
	},
	"symbiotic_bond": {
		"name": "Symbiotic Bond",
		"faction": "WildlandsAscendant",
		"type": "support",
		"energy_cost": 20,
		"cooldown": 3.0,
		"range": 8.0,
		"cast_time": 0.6,
		"effect": "companion_buff",
		"description": "Strengthen your companion's next attack"
	},
	"primal_fury": {
		"name": "Primal Fury",
		"faction": "WildlandsAscendant",
		"type": "aoe",
		"damage_base": 60,
		"energy_cost": 30,
		"cooldown": 4.0,
		"range": 0.0,
		"cast_time": 1.1,
		"aoe_radius": 8.0,
		"description": "Unleash fury in an area around you"
	}
}

# Status effects dictionary
const STATUS_EFFECTS = {
	"burn": {"damage_per_sec": 5, "color": Color.ORANGE_RED},
	"freeze": {"movement_slow": 0.5, "cooldown_slow": 0.3, "color": Color.CYAN},
	"poison": {"damage_per_sec": 3, "stat_debuff": {"strength": -10}, "color": Color.GREEN},
	"stun": {"disable_abilities": true, "duration": 2.0, "color": Color.YELLOW},
	"confusion": {"reversed_controls": true, "color": Color.MAGENTA},
	"bleed": {"damage_per_sec": 2, "damage_on_move": 2, "color": Color.RED},
	"weakness": {"damage_reduction": 0.2, "stat_debuff": {"strength": -20}, "color": Color.GRAY},
	"vulnerability": {"damage_increase_taken": 0.3, "color": Color.DARK_RED}
}

# Combat state
var active_combats: Dictionary = {}  # combat_id -> combat_data
var player_cooldowns: Dictionary = {}  # player_id -> {ability_id -> remaining_time}
var player_energy: Dictionary = {}  # player_id -> current_energy
var player_positions: Dictionary = {}  # player_id -> Vector2
var player_status_effects: Dictionary = {}  # player_id -> [status_effects]

# Combat parameters
const ENERGY_MAX = 100
const ENERGY_REGEN_PER_SEC = 20  # Regenerate 20 energy per second when not in combat
const ENERGY_REGEN_COMBAT = 10   # Regenerate 10 energy per second in combat
const COMBAT_TIMEOUT = 300.0  # 5 minutes

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# Update all active combats
	var combat_ids = active_combats.keys()
	for combat_id in combat_ids:
		update_combat(combat_id, delta)

func start_combat(player_id: String, enemy_id: String, player_pos: Vector2, enemy_pos: Vector2) -> String:
	"""Start a live-action combat encounter"""
	var combat_id = "%s_vs_%s_%d" % [player_id, enemy_id, randi()]

	active_combats[combat_id] = {
		"player_id": player_id,
		"enemy_id": enemy_id,
		"status": "active",
		"start_time": Time.get_ticks_msec(),
		"duration": 0.0,
		"player_health": 100,
		"enemy_health": 100,
		"player_damage_dealt": 0,
		"enemy_damage_dealt": 0,
		"abilities_used": []
	}

	player_positions[player_id] = player_pos
	player_positions[enemy_id] = enemy_pos
	player_energy[player_id] = ENERGY_MAX
	player_energy[enemy_id] = ENERGY_MAX
	player_cooldowns[player_id] = {}
	player_cooldowns[enemy_id] = {}
	player_status_effects[player_id] = []
	player_status_effects[enemy_id] = []

	combat_started.emit(player_id, enemy_id)
	return combat_id

func use_ability(actor_id: String, ability_id: String, target_id: String, target_pos: Vector2) -> bool:
	"""Use an ability in real-time (no turn system)"""

	# Check if ability exists
	if not ABILITY_DATABASE.has(ability_id):
		return false

	var ability = ABILITY_DATABASE[ability_id]

	# Check if actor has enough energy
	if player_energy.get(actor_id, 0) < ability["energy_cost"]:
		return false

	# Check if ability is on cooldown
	var cooldown_remaining = player_cooldowns[actor_id].get(ability_id, 0.0)
	if cooldown_remaining > 0.0:
		ability_on_cooldown.emit(actor_id, ability_id, cooldown_remaining)
		return false

	# Check range
	var actor_pos = player_positions.get(actor_id, Vector2.ZERO)
	var distance = actor_pos.distance_to(target_pos)
	if distance > ability["range"] and ability["range"] > 0:
		return false

	# Deduct energy
	player_energy[actor_id] -= ability["energy_cost"]

	# Set cooldown
	player_cooldowns[actor_id][ability_id] = ability["cooldown"]

	# Calculate damage with variance
	var damage = calculate_damage(actor_id, ability, target_id)
	var crit_bonus := 0.0
	if actor_id == "player" and PlayerProfile:
		crit_bonus = float(ModMechanics.combat_for(PlayerProfile.selected_mod).crit_chance_bonus)
	var is_crit = randf() < (float(ability.get("crit_chance", 0.05)) + crit_bonus)
	if is_crit:
		damage = int(damage * 1.5)

	# Apply damage
	apply_damage(actor_id, target_id, damage, is_crit)

	# Apply status effects if ability has them
	if ability.has("effect") and ability["effect"] != "":
		apply_status_effect(target_id, ability["effect"], ability.get("duration", 3.0))

	ability_used.emit(actor_id, ability_id, target_id, damage)
	return true

func calculate_damage(actor_id: String, ability: Dictionary, target_id: String) -> int:
	"""Calculate damage with variance and modifiers"""
	var base_damage = ability.get("damage_base", 0)
	var variance = randf_range(0.85, 1.15)  # ±15% variance
	var damage = int(base_damage * variance)

	# Apply actor's stat bonuses
	var strength_bonus = get_actor_stat(actor_id, "strength")
	damage += int(strength_bonus * 0.5)  # 50% of strength adds to damage

	# Apply target's defense reduction
	var defense = get_actor_stat(target_id, "defense")
	var defense_reduction = int(defense * 0.3)  # 30% of defense reduces damage
	damage = max(1, damage - defense_reduction)

	return damage

func apply_damage(attacker_id: String, target_id: String, amount: int, is_crit: bool) -> void:
	"""Apply damage to target"""
	# Find combat containing these actors
	for combat_id in active_combats.keys():
		var combat = active_combats[combat_id]
		if (combat["player_id"] == target_id or combat["enemy_id"] == target_id):
			if combat["player_id"] == target_id:
				combat["player_health"] -= amount
				combat["enemy_damage_dealt"] += amount
			else:
				combat["enemy_health"] -= amount
				combat["player_damage_dealt"] += amount

			damage_dealt.emit(attacker_id, target_id, amount, is_crit,
				player_positions[attacker_id].distance_to(player_positions[target_id]))

			# Check if target is defeated
			if combat["player_health"] <= 0 or combat["enemy_health"] <= 0:
				end_combat(combat_id)

func apply_status_effect(target_id: String, effect_type: String, duration: float) -> void:
	"""Apply status effect to target"""
	if not STATUS_EFFECTS.has(effect_type):
		return

	player_status_effects[target_id].append({
		"type": effect_type,
		"duration": duration,
		"elapsed": 0.0
	})

	status_applied.emit(target_id, effect_type, int(duration))

func update_combat(combat_id: String, delta: float) -> void:
	"""Update combat state every frame"""
	var combat = active_combats[combat_id]

	if combat["status"] != "active":
		return

	combat["duration"] += delta

	# Regenerate energy
	var player_id = combat["player_id"]
	var enemy_id = combat["enemy_id"]

	player_energy[player_id] = min(ENERGY_MAX, player_energy[player_id] + ENERGY_REGEN_COMBAT * delta)
	player_energy[enemy_id] = min(ENERGY_MAX, player_energy[enemy_id] + ENERGY_REGEN_COMBAT * delta)

	# Update cooldowns
	update_cooldowns(player_id, delta)
	update_cooldowns(enemy_id, delta)

	# Update status effects
	update_status_effects(player_id, delta)
	update_status_effects(enemy_id, delta)

	# Timeout combat if too long
	if combat["duration"] > COMBAT_TIMEOUT:
		end_combat(combat_id)

func update_cooldowns(actor_id: String, delta: float) -> void:
	"""Decrease cooldown timers"""
	if not player_cooldowns.has(actor_id):
		return

	for ability_id in player_cooldowns[actor_id].keys():
		player_cooldowns[actor_id][ability_id] -= delta
		if player_cooldowns[actor_id][ability_id] <= 0:
			player_cooldowns[actor_id][ability_id] = 0
			ability_ready.emit(actor_id, ability_id)

func update_status_effects(actor_id: String, delta: float) -> void:
	"""Update status effect durations and apply damage"""
	if not player_status_effects.has(actor_id):
		return

	var effects_to_remove = []

	for i in range(player_status_effects[actor_id].size()):
		var effect = player_status_effects[actor_id][i]
		effect["elapsed"] += delta

		# Apply ongoing damage (burn, poison, bleed)
		var effect_data = STATUS_EFFECTS[effect["type"]]
		if effect_data.has("damage_per_sec"):
			var damage = int(effect_data["damage_per_sec"] * delta)
			apply_damage("status_effect", actor_id, damage, false)

		# Remove expired effects
		if effect["elapsed"] >= effect["duration"]:
			effects_to_remove.append(i)

	# Remove expired effects (reverse order to maintain indices)
	for i in range(effects_to_remove.size() - 1, -1, -1):
		player_status_effects[actor_id].remove_at(effects_to_remove[i])

func end_combat(combat_id: String) -> void:
	"""End combat and determine winner"""
	var combat = active_combats[combat_id]
	combat["status"] = "ended"

	var winner_id = combat["player_id"] if combat["player_health"] > combat["enemy_health"] else combat["enemy_id"]
	var loser_id = combat["enemy_id"] if winner_id == combat["player_id"] else combat["player_id"]

	var stats = {
		"duration": combat["duration"],
		"player_damage": combat["player_damage_dealt"],
		"enemy_damage": combat["enemy_damage_dealt"],
		"winner_health": combat["player_health"] if winner_id == combat["player_id"] else combat["enemy_health"]
	}

	combat_ended.emit(winner_id, loser_id, stats)
	entity_defeated.emit(loser_id, winner_id, [])  # TODO: Loot generation

func move_actor(actor_id: String, new_position: Vector2) -> void:
	"""Move actor in real-time (for positioning-based abilities)"""
	player_positions[actor_id] = new_position

func get_actor_stat(actor_id: String, stat_name: String) -> int:
	"""Get actor stat. The local player reads their real race/frame stat
	sheet (CharacterCreatorLogic) with their mod's combat math layered on
	top (ModMechanics); anything else (no CharacterProgression system for
	NPCs/enemies yet) falls back to the flat placeholder."""
	if actor_id == "player" and PlayerProfile:
		var stats := CharacterCreatorLogic.build_starting_stats(
			PlayerProfile.selected_race_id, PlayerProfile.faction, PlayerProfile.selected_frame)
		var combat := ModMechanics.combat_for(PlayerProfile.selected_mod)
		match stat_name:
			"strength": return int(float(stats.get("pow", 10)) * float(combat.damage_mult))
			"defense": return int(float(stats.get("res", 10)) * float(combat.defense_mult))
	return 10  # Default stat value

func get_energy_level(actor_id: String) -> float:
	"""Get current energy as percentage (0-1)"""
	return player_energy.get(actor_id, 0.0) / ENERGY_MAX

func get_ability_cooldown(actor_id: String, ability_id: String) -> float:
	"""Get remaining cooldown for ability"""
	return player_cooldowns.get(actor_id, {}).get(ability_id, 0.0)

func is_in_range(actor_id: String, target_id: String, range_required: float) -> bool:
	"""Check if actor can reach target"""
	var distance = player_positions[actor_id].distance_to(player_positions[target_id])
	return distance <= range_required

func save_combat_stats(combat_id: String) -> Dictionary:
	"""Save combat stats for database"""
	if not active_combats.has(combat_id):
		return {}

	var combat = active_combats[combat_id]
	return {
		"player_id": combat["player_id"],
		"enemy_id": combat["enemy_id"],
		"duration": combat["duration"],
		"player_health_final": combat["player_health"],
		"enemy_health_final": combat["enemy_health"],
		"player_damage_dealt": combat["player_damage_dealt"],
		"enemy_damage_dealt": combat["enemy_damage_dealt"]
	}
