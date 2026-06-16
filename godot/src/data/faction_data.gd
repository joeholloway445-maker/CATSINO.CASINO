class_name FactionData


static func get_faction_info(faction_name: String) -> Dictionary:
	match faction_name:
		"Factionless":
			return {
				"name":        "Factionless",
				"description": "Untethered by allegiance, guided only by instinct.",
				"lore":        "The Factionless roam the neon streets without banner or bond. They answer to no sovereign, no current, no wild call — only the roll of the dice and the luck they carry. Many underestimate them. Most regret it.",
				"bonus_type":  "lck",
				"bonus_value": 5,
				"color_hex":   "#888888",
				"emblem_emoji": "🎲",
				"rival":       "SovereignCrown",
			}
		"SovereignCrown":
			return {
				"name":        "Sovereign Crown",
				"description": "The golden hierarchy rules Paw Vegas from gilded towers.",
				"lore":        "Born from the first casino lords of Paw Vegas, the Sovereign Crown believes power flows through order, wealth, and the iron discipline of the house. Their operatives are schooled in brute force and tactical dominance — where others gamble, they control.",
				"bonus_type":  "pow",
				"bonus_value": 10,
				"color_hex":   "#FFD700",
				"emblem_emoji": "👑",
				"rival":       "WildlandsAscendant",
			}
		"VeiledCurrent":
			return {
				"name":        "Veiled Current",
				"description": "Masters of the unseen current that flows beneath all things.",
				"lore":        "The Veiled Current was never founded — it simply appeared, like static before a storm. Their agents move faster than light through the grid, surfing the hidden data streams of the neon underworld. Speed is their creed, invisibility their art.",
				"bonus_type":  "spd",
				"bonus_value": 10,
				"color_hex":   "#00F6FF",
				"emblem_emoji": "🌊",
				"rival":       "SovereignCrown",
			}
		"WildlandsAscendant":
			return {
				"name":        "Wildlands Ascendant",
				"description": "Born from the chaos beyond the neon boundary.",
				"lore":        "Out past Arcade Galaxy, where the city grid dissolves into Cat Forest, the Wildlands Ascendant clawed their way into legend. They worship resilience above all — every scar is a trophy, every loss a lesson absorbed into unbreakable hide.",
				"bonus_type":  "res",
				"bonus_value": 10,
				"color_hex":   "#39FF88",
				"emblem_emoji": "🐾",
				"rival":       "VeiledCurrent",
			}
		_:
			return {}


static func get_rival_faction(faction_name: String) -> String:
	var info := get_faction_info(faction_name)
	return info.get("rival", "Factionless")


static func get_stat_bonus(faction_name: String) -> Dictionary:
	var info := get_faction_info(faction_name)
	if info.is_empty():
		return {}
	return { info["bonus_type"]: info["bonus_value"] }


static func all_factions() -> Array[String]:
	return ["Factionless", "SovereignCrown", "VeiledCurrent", "WildlandsAscendant"]
