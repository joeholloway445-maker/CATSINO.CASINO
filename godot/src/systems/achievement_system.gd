extends Node
class_name AchievementSystem

signal achievement_unlocked(achievement_id: String)
signal progress_updated(achievement_id: String, progress: int, target: int)

const ACHIEVEMENTS = {
	# COMBAT ACHIEVEMENTS
	"first_blood": {
		"name": "First Blood",
		"description": "Defeat your first entity",
		"category": "combat",
		"points": 10,
		"reward_cosmetic": "badge_first_blood"
	},
	"monster_slayer": {
		"name": "Monster Slayer",
		"description": "Defeat 100 entities",
		"category": "combat",
		"points": 50,
		"progress_type": "counter",
		"target": 100
	},
	"entity_conqueror": {
		"name": "Entity Conqueror",
		"description": "Defeat one entity from each category",
		"category": "combat",
		"points": 100,
		"progress_type": "set",
		"target": ["Energy", "Entropy", "Gravity", "Matter", "Psyche", "Quantum"]
	},
	"critical_striker": {
		"name": "Critical Striker",
		"description": "Land 50 critical hits",
		"category": "combat",
		"points": 50,
		"progress_type": "counter",
		"target": 50
	},
	"flawless_victory": {
		"name": "Flawless Victory",
		"description": "Win 5 combats without taking damage",
		"category": "combat",
		"points": 100,
		"progress_type": "counter",
		"target": 5
	},

	# PROGRESSION ACHIEVEMENTS
	"level_10": {
		"name": "Novice Adventurer",
		"description": "Reach level 10",
		"category": "progression",
		"points": 25,
		"progress_type": "level",
		"target": 10
	},
	"level_50": {
		"name": "Seasoned Warrior",
		"description": "Reach level 50",
		"category": "progression",
		"points": 100,
		"progress_type": "level",
		"target": 50
	},
	"level_99": {
		"name": "Legendary Hero",
		"description": "Reach maximum level 99",
		"category": "progression",
		"points": 500,
		"progress_type": "level",
		"target": 99,
		"cosmetic": "aura_legendary"
	},

	# FACTION ACHIEVEMENTS
	"crown_alliance": {
		"name": "Crown Alliance",
		"description": "Join the Sovereign Crown",
		"category": "faction",
		"points": 50,
		"faction": "SovereignCrown"
	},
	"crown_champion": {
		"name": "Crown Champion",
		"description": "Reach Legendary reputation with the Sovereign Crown",
		"category": "faction",
		"points": 200,
		"faction": "SovereignCrown",
		"reputation_tier": "Legendary"
	},
	"veil_initiate": {
		"name": "Veiled Initiate",
		"description": "Join the Veiled Current",
		"category": "faction",
		"points": 50,
		"faction": "VeiledCurrent"
	},
	"wildlands_kin": {
		"name": "Wildlands Kin",
		"description": "Join Wildlands Ascendant",
		"category": "faction",
		"points": 50,
		"faction": "WildlandsAscendant"
	},
	"triple_agent": {
		"name": "Triple Agent",
		"description": "Reach Champion tier with all three factions",
		"category": "faction",
		"points": 300
	},

	# QUEST ACHIEVEMENTS
	"quest_seeker": {
		"name": "Quest Seeker",
		"description": "Complete 10 quests",
		"category": "quests",
		"points": 50,
		"progress_type": "counter",
		"target": 10
	},
	"lore_master": {
		"name": "Lore Master",
		"description": "Complete all Act 1 quests from all factions",
		"category": "quests",
		"points": 200,
		"progress_type": "set",
		"target": ["crown_act1_q3_integration_review", "veil_act1_q3_ascension", "wild_act1_q3_symbiosis"]
	},

	# COLLECTION ACHIEVEMENTS
	"collector": {
		"name": "Collector",
		"description": "Collect 50 unique entities",
		"category": "collection",
		"points": 100,
		"progress_type": "counter",
		"target": 50
	},
	"complete_dex": {
		"name": "Complete Dex",
		"description": "Collect all 144 entities",
		"category": "collection",
		"points": 500,
		"progress_type": "counter",
		"target": 144,
		"cosmetic": "title_collector"
	},
	"equipment_master": {
		"name": "Equipment Master",
		"description": "Equip a complete set of epic gear",
		"category": "collection",
		"points": 150
	},

	# SOCIAL ACHIEVEMENTS
	"ally_maker": {
		"name": "Ally Maker",
		"description": "Reach friendly disposition with 5 NPCs",
		"category": "social",
		"points": 75,
		"progress_type": "counter",
		"target": 5
	},
	"beloved": {
		"name": "Beloved (Achievement)",
		"description": "Reach affectionate disposition with 10 NPCs",
		"category": "social",
		"points": 200,
		"progress_type": "counter",
		"target": 10,
		"title_unlock": "Beloved"
	},

	# SEASONAL ACHIEVEMENTS
	"season_1_victor": {
		"name": "Season 1 Victor",
		"description": "Complete Season 1 battle pass",
		"category": "seasonal",
		"points": 300,
		"season": 1
	},
	"speedrunner": {
		"name": "Speedrunner",
		"description": "Complete Act 1 in under 2 hours",
		"category": "challenge",
		"points": 150
	}
}

var _unlocked_achievements: Array[String] = []
var _achievement_progress: Dictionary = {}

func _ready() -> void:
	pass

func unlock_achievement(achievement_id: String) -> bool:
	if achievement_id in _unlocked_achievements:
		return false

	if achievement_id not in ACHIEVEMENTS:
		return false

	_unlocked_achievements.append(achievement_id)
	achievement_unlocked.emit(achievement_id)

	# Grant cosmetics/titles
	var achievement = ACHIEVEMENTS[achievement_id]
	if "cosmetic" in achievement:
		PlayerProfile.unlock_cosmetic(achievement["cosmetic"])
	if "title_unlock" in achievement:
		PlayerProfile.titles.append(achievement["title_unlock"])

	return true

func update_progress(achievement_id: String, progress: int) -> void:
	if achievement_id not in ACHIEVEMENTS:
		return

	if achievement_id in _unlocked_achievements:
		return

	var achievement = ACHIEVEMENTS[achievement_id]
	var target = achievement.get("target", 0)

	_achievement_progress[achievement_id] = progress
	progress_updated.emit(achievement_id, progress, target)

	if progress >= target and target > 0:
		unlock_achievement(achievement_id)

func add_progress(achievement_id: String, amount: int = 1) -> void:
	var current = _achievement_progress.get(achievement_id, 0)
	update_progress(achievement_id, current + amount)

func add_set_item(achievement_id: String, item: String) -> void:
	if achievement_id not in ACHIEVEMENTS:
		return

	var achievement = ACHIEVEMENTS[achievement_id]
	if achievement.get("progress_type") != "set":
		return

	var current = _achievement_progress.get(achievement_id, []) as Array
	if item not in current:
		current.append(item)
		_achievement_progress[achievement_id] = current

		var target = achievement.get("target", []) as Array
		if current.size() == target.size():
			unlock_achievement(achievement_id)

func get_achievement(achievement_id: String) -> Dictionary:
	return ACHIEVEMENTS.get(achievement_id, {})

func get_unlocked_achievements() -> Array[String]:
	return _unlocked_achievements.duplicate()

func get_achievement_progress(achievement_id: String) -> int:
	return _achievement_progress.get(achievement_id, 0)

func get_total_points() -> int:
	var total = 0
	for achievement_id in _unlocked_achievements:
		total += ACHIEVEMENTS[achievement_id].get("points", 0)
	return total

# ── Save/Load ──────────────────────────────────────────────────────────────
func save_state() -> Dictionary:
	return {
		"unlocked_achievements": _unlocked_achievements.duplicate(),
		"achievement_progress": _achievement_progress.duplicate()
	}

func load_state(data: Dictionary) -> void:
	_unlocked_achievements = data.get("unlocked_achievements", [])
	_achievement_progress = data.get("achievement_progress", {})
