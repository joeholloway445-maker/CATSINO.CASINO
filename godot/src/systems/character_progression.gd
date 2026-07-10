extends Node
class_name CharacterProgression

signal level_up(new_level: int)
signal skill_point_gained(points: int)
signal attribute_increased(attribute: String, new_value: int)

const BASE_STATS = {
	"health": 100,
	"mana": 50,
	"energy": 100,
	"strength": 10,
	"intelligence": 10,
	"agility": 10,
	"wisdom": 10,
	"defense": 5,
	"speed": 5,
	"attack": 15,
	"crit_chance": 0.05,
	"evasion": 0.0
}

const LEVEL_CURVE = {
	# XP required per level (accelerating)
	1: 0,
	2: 500,
	3: 1200,
	4: 2200,
	5: 3500,
	10: 15000,
	20: 50000,
	30: 120000,
	50: 350000,
	75: 1000000,
	99: 3000000
}

const SKILL_TREE = {
	"warrior_path": {
		"name": "Warrior Path",
		"description": "Master of close combat and defense",
		"skills": {
			"slash_1": {
				"name": "Basic Slash",
				"level": 1,
				"cost": 0,
				"damage": 30,
				"cooldown": 1,
				"description": "Basic attacking skill"
			},
			"power_slash": {
				"name": "Power Slash",
				"level": 5,
				"cost": 1,
				"requires": ["slash_1"],
				"damage": 60,
				"cooldown": 2,
				"description": "Powerful slash with increased damage"
			},
			"whirlwind": {
				"name": "Whirlwind Attack",
				"level": 15,
				"cost": 2,
				"requires": ["power_slash"],
				"damage": 50,
				"radius": 8,
				"cooldown": 3,
				"description": "Spin attack hitting all nearby enemies"
			},
			"shield_bash": {
				"name": "Shield Bash",
				"level": 10,
				"cost": 1,
				"damage": 35,
				"stun_chance": 0.5,
				"cooldown": 2,
				"description": "Bash with shield to stun enemies"
			},
			"defensive_stance": {
				"name": "Defensive Stance",
				"level": 8,
				"cost": 1,
				"defense_bonus": 0.5,
				"duration": 10,
				"cooldown": 4,
				"description": "Assume defensive position"
			}
		}
	},
	"mage_path": {
		"name": "Mage Path",
		"description": "Master of elemental and arcane magic",
		"skills": {
			"fireball": {
				"name": "Fireball",
				"level": 1,
				"cost": 0,
				"damage": 40,
				"element": "fire",
				"cooldown": 2,
				"description": "Cast a ball of fire"
			},
			"inferno": {
				"name": "Inferno",
				"level": 10,
				"cost": 2,
				"requires": ["fireball"],
				"damage": 80,
				"radius": 10,
				"cooldown": 4,
				"description": "Massive fire explosion"
			},
			"frost_bolt": {
				"name": "Frost Bolt",
				"level": 5,
				"cost": 1,
				"damage": 30,
				"element": "ice",
				"freeze_chance": 0.3,
				"cooldown": 2,
				"description": "Freeze enemy with ice"
			},
			"arcane_mastery": {
				"name": "Arcane Mastery",
				"level": 15,
				"cost": 2,
				"requires": ["fireball", "frost_bolt"],
				"intelligence_bonus": 0.3,
				"mana_regen": 5,
				"duration": "passive",
				"description": "Enhance all magical abilities"
			},
			"time_warp": {
				"name": "Time Warp",
				"level": 30,
				"cost": 3,
				"requires": ["arcane_mastery"],
				"effect": "rewind_time",
				"cooldown": 20,
				"description": "Rewind recent actions (rare)"
			}
		}
	},
	"ranger_path": {
		"name": "Ranger Path",
		"description": "Master of ranged combat and mobility",
		"skills": {
			"arrow_shot": {
				"name": "Arrow Shot",
				"level": 1,
				"cost": 0,
				"damage": 25,
				"range": 15,
				"cooldown": 1,
				"description": "Shoot a single arrow"
			},
			"multi_shot": {
				"name": "Multi-Shot",
				"level": 8,
				"cost": 1,
				"requires": ["arrow_shot"],
				"damage": 15,
				"projectile_count": 5,
				"cooldown": 3,
				"description": "Fire multiple arrows"
			},
			"piercing_shot": {
				"name": "Piercing Shot",
				"level": 12,
				"cost": 1,
				"damage": 50,
				"pierces": true,
				"cooldown": 2,
				"description": "Arrow that pierces through enemies"
			},
			"evasion": {
				"name": "Evasion",
				"level": 5,
				"cost": 1,
				"evasion_bonus": 0.25,
				"duration": "passive",
				"description": "Passive evasion chance"
			},
			"shadow_clone": {
				"name": "Shadow Clone",
				"level": 20,
				"cost": 2,
				"requires": ["evasion"],
				"effect": "create_clone",
				"cooldown": 5,
				"description": "Create decoy clone"
			}
		}
	}
}

var _level: int = 1
var _xp: int = 0
var _skill_points: int = 0
var _base_stats: Dictionary = {}
var _learned_skills: Array[String] = []
var _stat_modifiers: Dictionary = {}

func _ready() -> void:
	_base_stats = BASE_STATS.duplicate()

func gain_xp(amount: int) -> void:
	_xp += amount

	# Check for level up
	var next_level_xp = _get_xp_for_level(_level + 1)
	while _xp >= next_level_xp and _level < 99:
		_xp -= next_level_xp
		_level += 1
		_skill_points += 2  # Gain 2 skill points per level
		_level_up()
		next_level_xp = _get_xp_for_level(_level + 1)

func _level_up() -> void:
	# Stat increases per level
	_base_stats["health"] += 15
	_base_stats["mana"] += 8
	_base_stats["strength"] += 1
	_base_stats["intelligence"] += 1
	_base_stats["agility"] += 1

	level_up.emit(_level)
	skill_point_gained.emit(2)

func learn_skill(skill_id: String) -> bool:
	# Find skill in tree
	var skill = _find_skill(skill_id)
	if not skill:
		return false

	if skill_id in _learned_skills:
		return false

	# Check prerequisites
	var requires = skill.get("requires", [])
	for required_skill in requires:
		if required_skill not in _learned_skills:
			return false

	# Check level
	if _level < skill.get("level", 1):
		return false

	# Check skill points
	var cost = skill.get("cost", 1)
	if _skill_points < cost:
		return false

	_skill_points -= cost
	_learned_skills.append(skill_id)
	return true

func _find_skill(skill_id: String) -> Dictionary:
	for path in SKILL_TREE.values():
		if skill_id in path["skills"]:
			return path["skills"][skill_id]
	return {}

func get_stat(stat_name: String) -> int:
	var base = _base_stats.get(stat_name, 0)
	var modifier = _stat_modifiers.get(stat_name, 0)
	return base + modifier

func add_stat_modifier(stat: String, amount: int) -> void:
	_stat_modifiers[stat] = _stat_modifiers.get(stat, 0) + amount
	attribute_increased.emit(stat, get_stat(stat))

func get_level() -> int:
	return _level

func get_xp() -> int:
	return _xp

func get_xp_to_next_level() -> int:
	return _get_xp_for_level(_level + 1) - _xp

func get_skill_points() -> int:
	return _skill_points

func get_learned_skills() -> Array[String]:
	return _learned_skills.duplicate()

func _get_xp_for_level(level: int) -> int:
	# Interpolate between known values
	if level in LEVEL_CURVE:
		return LEVEL_CURVE[level]

	# Linear interpolation for levels not explicitly defined
	var lower_level = 1
	var upper_level = 99
	var lower_xp = LEVEL_CURVE[1]
	var upper_xp = LEVEL_CURVE[99]

	for key in LEVEL_CURVE.keys():
		if key < level and key > lower_level:
			lower_level = key
			lower_xp = LEVEL_CURVE[key]
		if key >= level and key < upper_level:
			upper_level = key
			upper_xp = LEVEL_CURVE[key]

	var progress = float(level - lower_level) / float(upper_level - lower_level)
	return int(lower_xp + (upper_xp - lower_xp) * progress)

# ── Save/Load ──────────────────────────────────────────────────────────────
func save_state() -> Dictionary:
	return {
		"level": _level,
		"xp": _xp,
		"skill_points": _skill_points,
		"base_stats": _base_stats.duplicate(),
		"learned_skills": _learned_skills.duplicate(),
		"stat_modifiers": _stat_modifiers.duplicate()
	}

func load_state(data: Dictionary) -> void:
	_level = data.get("level", 1)
	_xp = data.get("xp", 0)
	_skill_points = data.get("skill_points", 0)
	_base_stats = data.get("base_stats", BASE_STATS.duplicate())
	_learned_skills = data.get("learned_skills", [])
	_stat_modifiers = data.get("stat_modifiers", {})
