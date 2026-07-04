extends Node
class_name FactionSystem
# Faction allegiance and synergy bonus calculation

const FACTIONS = {
	"SovereignCrown": {
		color = Color(1.0, 0.84, 0.0),
		icon = "👑",
		desc = "Elite. Exclusive. Absolute.",
		slot_bonus = 0.10,
		combat_bonus = 0.05,
		race_spd_bonus = 0,
		companion_synergy_threshold = 2,
		lore = "The SovereignCrown rules Paw Vegas from the Crown Tower. Membership is by invitation only — or by proving yourself undeniable.",
	},
	"WildlandsAscendant": {
		color = Color(0.2, 0.8, 0.2),
		icon = "🌿",
		desc = "Nature's fury, harnessed.",
		slot_bonus = 0.05,
		combat_bonus = 0.10,
		race_spd_bonus = 5,
		companion_synergy_threshold = 2,
		lore = "Born from Cat Forest, the Wildlands faction believes nature is the ultimate power. Their companions are the strongest in open terrain.",
	},
	"VeiledCurrent": {
		color = Color(0.2, 0.6, 1.0),
		icon = "🌊",
		desc = "Flow unseen. Strike true.",
		slot_bonus = 0.12,
		combat_bonus = 0.08,
		race_spd_bonus = 8,
		companion_synergy_threshold = 2,
		lore = "The Veiled Current operates beneath the surface — literally. Neon Alley's water district is their stronghold.",
	},
	"Factionless": {
		color = Color(0.6, 0.6, 0.6),
		icon = "⚡",
		desc = "Bound by nothing.",
		slot_bonus = 0.0,
		combat_bonus = 0.0,
		race_spd_bonus = 0,
		companion_synergy_threshold = 0,
		lore = "Not a faction so much as an acknowledgment: some cats answer to no one. They receive no faction bonuses — but suffer no faction restrictions either.",
	},
}

## Canonical display labels — internal ids stay camel-cased.
const DISPLAY_NAMES := {
	"SovereignCrown": "Sovereign Crown",
	"VeiledCurrent": "Veiled Current",
	"WildlandsAscendant": "Wildlands Ascendant",
	"Factionless": "Factionless",
}

static func display_name(faction: String) -> String:
	return DISPLAY_NAMES.get(faction, faction)

static func get_faction_data(faction: String) -> Dictionary:
	return FACTIONS.get(faction, {})

static func calculate_synergy(player_faction: String, companion_ids: Array[String]) -> float:
	if companion_ids.is_empty(): return 1.0
	var faction_data = get_faction_data(player_faction)
	if faction_data.is_empty(): return 1.0

	var matching = 0
	for cid in companion_ids:
		var companion = _get_companion_faction(cid)
		if companion == player_faction:
			matching += 1

	var threshold = int(faction_data.get("companion_synergy_threshold", 2))
	if threshold <= 0: return 1.0
	var synergy_stacks = matching / threshold
	return 1.0 + synergy_stacks * 0.1

static func get_combat_mult(faction: String) -> float:
	var data = get_faction_data(faction)
	return 1.0 + float(data.get("combat_bonus", 0.0))

static func get_slot_mult(faction: String) -> float:
	var data = get_faction_data(faction)
	return 1.0 + float(data.get("slot_bonus", 0.0))

static func get_race_spd_bonus(faction: String) -> int:
	var data = get_faction_data(faction)
	return int(data.get("race_spd_bonus", 0))

static func _get_companion_faction(companion_id: String) -> String:
	if companion_id.begins_with("SC"): return "SovereignCrown"
	if companion_id.begins_with("WA"): return "WildlandsAscendant"
	if companion_id.begins_with("VC"): return "VeiledCurrent"
	return "Factionless"
