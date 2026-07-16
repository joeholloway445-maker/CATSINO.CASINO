class_name FactionData
extends RefCounted

const FACTIONS: Dictionary = {
	"Factionless": {
		"name": "Factionless",
		"description": "Wanderers bound by no allegiance, masters of their own fate.",
		"lore": "Untethered by allegiance, the Factionless roam Paws Vegas as free agents. They answer to no crown, follow no current, and bow to no wildland. Their neutrality is both their weakness and their greatest strength — for when all factions war, the Factionless endure.",
		"bonus_type": "lck",
		"bonus_value": 5,
		"color_hex": "#AAAAAA",
		"emblem_emoji": "🌀"
	},
	"SovereignCrown": {
		"name": "SovereignCrown",
		"description": "Rulers of the golden hierarchy, wielding power through discipline and dominance.",
		"lore": "The golden hierarchy rules from the heights of Cat Coliseum. Their creed is simple: power is earned through discipline, and dominance is the natural right of those strong enough to claim it. SovereignCrown members are feared, respected, and envied across all districts.",
		"bonus_type": "pow",
		"bonus_value": 10,
		"color_hex": "#FFD700",
		"emblem_emoji": "👑"
	},
	"VeiledCurrent": {
		"name": "VeiledCurrent",
		"description": "Masters of the unseen flow, threading through shadow and speed.",
		"lore": "Masters of the unseen current that flows beneath Paws Vegas, the VeiledCurrent move like water — fast, adaptable, and impossible to hold. They haunt Neon Alley like whispers, winning races not by brute force but by reading the invisible rhythms of the track.",
		"bonus_type": "spd",
		"bonus_value": 10,
		"color_hex": "#00CED1",
		"emblem_emoji": "🌊"
	},
	"WildlandsAscendant": {
		"name": "WildlandsAscendant",
		"description": "Survivors born from chaos, their resilience is legend.",
		"lore": "Born from the chaos of Cat Forest, where only the toughest survive, the WildlandsAscendant wear their scars as badges of honor. They outlast every challenger, shrug off wounds that would fell lesser cats, and emerge from every trial stronger than before.",
		"bonus_type": "res",
		"bonus_value": 10,
		"color_hex": "#228B22",
		"emblem_emoji": "🌿"
	}
}

const RIVALS: Dictionary = {
	"Factionless": "SovereignCrown",
	"SovereignCrown": "WildlandsAscendant",
	"VeiledCurrent": "WildlandsAscendant",
	"WildlandsAscendant": "SovereignCrown"
}

static func get_faction_info(faction_name: String) -> Dictionary:
	if faction_name in FACTIONS:
		return FACTIONS[faction_name].duplicate(true)
	push_warning("FactionData: unknown faction '%s'" % faction_name)
	return {}

static func get_rival_faction(faction_name: String) -> String:
	return RIVALS.get(faction_name, "")

static func get_all_faction_names() -> Array[String]:
	var names: Array[String] = []
	for key in FACTIONS:
		names.append(key)
	return names

static func apply_faction_bonus(faction_name: String, stat_dict: Dictionary) -> Dictionary:
	var info = get_faction_info(faction_name)
	if info.is_empty():
		return stat_dict
	var result = stat_dict.duplicate(true)
	var bonus_type: String = info["bonus_type"]
	var bonus_value: int = info["bonus_value"]
	if bonus_type in result:
		result[bonus_type] = result[bonus_type] + bonus_value
	return result
