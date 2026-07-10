extends Node
class_name CombatSystem

# Real-time turn-based combat with abilities, status effects, and tactical positioning

signal combat_started(player_id: String, enemy_id: String)
signal turn_changed(turn_num: int, active_actor: String)
signal ability_used(attacker_id: String, ability_id: String, target_id: String)
signal damage_dealt(source: String, target: String, amount: int, crit: bool)
signal status_applied(target_id: String, status: String, duration: int)
signal combat_ended(winner_id: String)
signal entity_defeated(entity_id: String, conqueror_id: String)

const ABILITY_DATABASE = {
	# SOVEREIGN CROWN ABILITIES
	"solar_strike": {
		"name": "Solar Strike",
		"faction": "SovereignCrown",
		"type": "damage",
		"damage": 75,
		"energy_cost": 25,
		"cooldown": 2,
		"range": 5,
		"description": "Harness solar energy for a powerful strike",
		"animation": "slash_yellow"
	},
	"precision_strike": {
		"name": "Precision Strike",
		"faction": "SovereignCrown",
		"type": "damage",
		"damage": 50,
		"energy_cost": 15,
		"cooldown": 1,
		"crit_chance": 0.35,
		"range": 3,
		"description": "Strike with calculated precision for increased crit chance"
	},
	"shield_wall": {
		"name": "Shield Wall",
		"faction": "SovereignCrown",
		"type": "defense",
		"damage_reduction": 0.4,
		"energy_cost": 20,
		"cooldown": 3,
		"duration": 5,
		"description": "Defend against incoming damage",
		"animation": "shield_gold"
	},
	"order_decree": {
		"name": "Order Decree",
		"faction": "SovereignCrown",
		"type": "support",
		"energy_cost": 30,
		"cooldown": 4,
		"effect": "allied_damage_buff",
		"buff_amount": 0.25,
		"duration": 6,
		"description": "Grant allies increased damage output",
		"animation": "buff_golden"
	},

	# VEILED CURRENT ABILITIES
	"shadow_strike": {
		"name": "Shadow Strike",
		"faction": "VeiledCurrent",
		"type": "damage",
		"damage": 65,
		"energy_cost": 20,
		"cooldown": 2,
		"range": 4,
		"evasion_bonus": 0.15,
		"description": "Strike from darkness with evasion bonus"
	},
	"dream_veil": {
		"name": "Dream Veil",
		"faction": "VeiledCurrent",
		"type": "defense",
		"energy_cost": 25,
		"cooldown": 3,
		"effect": "confusion",
		"status_chance": 0.5,
		"duration": 4,
		"description": "Confuse enemies with illusory barriers"
	},
	"prophecy_strike": {
		"name": "Prophecy Strike",
		"faction": "VeiledCurrent",
		"type": "damage",
		"damage": 80,
		"energy_cost": 35,
		"cooldown": 4,
		"requires_ability": "prophecy_sight",
		"description": "Strike with knowledge of future outcomes"
	},
	"temporal_loop": {
		"name": "Temporal Loop",
		"faction": "VeiledCurrent",
		"type": "utility",
		"energy_cost": 40,
		"cooldown": 6,
		"effect": "rewind_turn",
		"description": "Rewind a failed action",
		"rare": true
	},

	# WILDLANDS ASCENDANT ABILITIES
	"feral_strike": {
		"name": "Feral Strike",
		"faction": "WildlandsAscendant",
		"type": "damage",
		"damage": 70,
		"energy_cost": 18,
		"cooldown": 2,
		"lifesteal": 0.3,
		"description": "Strike with primal force and recover health"
	},
	"evolution_surge": {
		"name": "Evolution Surge",
		"faction": "WildlandsAscendant",
		"type": "support",
		"energy_cost": 30,
		"cooldown": 4,
		"effect": "stat_boost",
		"duration": 8,
		"description": "Surge with evolutionary power for increased stats"
	},
	"symbiotic_bond": {
		"name": "Symbiotic Bond",
		"faction": "WildlandsAscendant",
		"type": "utility",
		"energy_cost": 25,
		"cooldown": 3,
		"effect": "companion_link",
		"description": "Link with companion for shared damage reduction"
	},
	"primal_fury": {
		"name": "Primal Fury",
		"faction": "WildlandsAscendant",
		"type": "damage",
		"damage": 110,
		"energy_cost": 50,
		"cooldown": 5,
		"effect": "rampage",
		"duration": 3,
		"description": "Unleash uncontrolled primal power"
	}
}

const STATUS_EFFECTS = {
	"burn": {"duration": 4, "damage_per_turn": 10, "element": "fire"},
	"freeze": {"duration": 3, "effect": "skip_turn_chance", "chance": 0.5},
	"poison": {"duration": 5, "damage_per_turn": 8, "element": "toxin"},
	"stun": {"duration": 1, "effect": "skip_turn", "prevents_abilities": true},
	"confusion": {"duration": 3, "effect": "random_action"},
	"bleed": {"duration": 6, "damage_per_turn": 5, "stackable": true},
	"weakness": {"duration": 4, "damage_reduction": 0.2},
	"vulnerability": {"duration": 3, "incoming_damage_increase": 0.25}
}

var _active_combats: Dictionary = {}
var _turn_queue: Array[String] = []
var _current_turn: int = 0

func _ready() -> void:
	pass

func start_combat(player_id: String, enemy_id: String) -> void:
	var combat_id = "%s_vs_%s_%d" % [player_id, enemy_id, randi()]

	_active_combats[combat_id] = {
		"player_id": player_id,
		"enemy_id": enemy_id,
		"turn": 0,
		"actors": [player_id, enemy_id],
		"initiative": {}
	}

	# Calculate initiative
	var player_speed = PlayerProfile.get_stat("speed") + randi_range(-5, 5)
	var enemy_speed = 15 + randi_range(-5, 5)  # Placeholder

	_active_combats[combat_id]["initiative"][player_id] = player_speed
	_active_combats[combat_id]["initiative"][enemy_id] = enemy_speed

	# Sort by initiative
	var sorted_actors = _active_combats[combat_id]["actors"].duplicate()
	sorted_actors.sort_custom(func(a, b):
		return _active_combats[combat_id]["initiative"][a] > _active_combats[combat_id]["initiative"][b]
	)
	_active_combats[combat_id]["actors"] = sorted_actors

	combat_started.emit(player_id, enemy_id)
	_advance_turn(combat_id)

func use_ability(combat_id: String, actor_id: String, ability_id: String, target_id: String) -> bool:
	if combat_id not in _active_combats:
		return false

	var combat = _active_combats[combat_id]
	var ability = ABILITY_DATABASE.get(ability_id)

	if not ability:
		return false

	# Check energy cost
	var actor_energy = PlayerProfile.get_stat("energy") if actor_id == combat["player_id"] else 50
	if actor_energy < ability["energy_cost"]:
		return false

	# Calculate damage
	var damage = ability.get("damage", 0)
	var crit = randf() < ability.get("crit_chance", 0.1)
	if crit:
		damage = int(damage * 1.5)

	match ability.get("type"):
		"damage":
			_deal_damage(combat_id, actor_id, target_id, damage, crit)
		"defense":
			_apply_defense(combat_id, target_id, ability)
		"support":
			_apply_buff(combat_id, target_id, ability)
		"utility":
			_apply_utility(combat_id, ability)

	ability_used.emit(actor_id, ability_id, target_id)

	# Consume energy
	if actor_id == combat["player_id"]:
		PlayerProfile.add_stat_modifier("energy", -ability["energy_cost"])

	_advance_turn(combat_id)
	return true

func _deal_damage(combat_id: String, source_id: String, target_id: String, damage: int, crit: bool) -> void:
	damage = maxi(1, damage - randi_range(0, 15))  # Add damage variance

	damage_dealt.emit(source_id, target_id, damage, crit)

	# Check for defeat
	if target_id == _active_combats[combat_id]["player_id"]:
		PlayerProfile.add_stat_modifier("health", -damage)
		if PlayerProfile.get_stat("health") <= 0:
			_end_combat(combat_id, source_id)
	else:
		# Enemy defeated check
		if damage >= 100:  # Placeholder
			_end_combat(combat_id, source_id)

func _apply_defense(combat_id: String, target_id: String, ability: Dictionary) -> void:
	_active_combats[combat_id]["%s_defense" % target_id] = ability.get("damage_reduction", 0)

func _apply_buff(combat_id: String, target_id: String, ability: Dictionary) -> void:
	var effect = ability.get("effect")
	if target_id == _active_combats[combat_id]["player_id"]:
		match effect:
			"allied_damage_buff":
				PlayerProfile.add_stat_modifier("attack", int(ability.get("buff_amount", 0.1) * 100))

func _apply_utility(combat_id: String, ability: Dictionary) -> void:
	match ability.get("effect"):
		"rewind_turn":
			_current_turn = maxi(0, _current_turn - 1)

func _advance_turn(combat_id: String) -> void:
	if combat_id not in _active_combats:
		return

	var combat = _active_combats[combat_id]
	combat["turn"] += 1

	var active_actor = combat["actors"][combat["turn"] % combat["actors"].size()]
	turn_changed.emit(combat["turn"], active_actor)

func _end_combat(combat_id: String, winner_id: String) -> void:
	if combat_id in _active_combats:
		var combat = _active_combats[combat_id]
		entity_defeated.emit(combat["enemy_id"], winner_id)
		combat_ended.emit(winner_id)
		_active_combats.erase(combat_id)

func get_combat_state(combat_id: String) -> Dictionary:
	return _active_combats.get(combat_id, {})

# ── Save/Load ──────────────────────────────────────────────────────────────
func save_state() -> Dictionary:
	return {"active_combats": _active_combats.duplicate(true)}

func load_state(data: Dictionary) -> void:
	_active_combats = data.get("active_combats", {})
