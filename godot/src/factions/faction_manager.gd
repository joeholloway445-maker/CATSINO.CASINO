extends Node
class_name FactionManager

signal faction_joined(faction: String)
signal faction_left(faction: String)
signal reputation_changed(faction: String, new_rep: int)
signal title_earned(title: String)

const FACTIONS = ["SovereignCrown", "VeiledCurrent", "WildlandsAscendant", "Factionless"]
const REP_THRESHOLDS = {
	0: "Unknown",
	50: "Acquaintance",
	100: "Ally",
	200: "Champion",
	300: "Legendary"
}

var _faction_reputations: Dictionary = {}
var _active_faction: String = "Factionless"

func _ready() -> void:
	# Initialize all factions at 0 reputation
	for faction in FACTIONS:
		_faction_reputations[faction] = 0

func join_faction(faction: String) -> bool:
	if faction not in FACTIONS:
		return false

	if faction == "Factionless":
		# Leave current faction
		if _active_faction != "Factionless":
			faction_left.emit(_active_faction)
		_active_faction = "Factionless"
		return true

	# Check if player can join (usually through quest completion)
	if _faction_reputations[faction] < 50:
		return false  # Need minimum reputation

	_active_faction = faction
	PlayerProfile.faction = faction
	faction_joined.emit(faction)
	return true

func add_reputation(faction: String, amount: int) -> int:
	if faction not in FACTIONS:
		return 0

	var old_rep = _faction_reputations[faction]
	var new_rep = clamp(old_rep + amount, -300, 300)
	_faction_reputations[faction] = new_rep

	# Check for reputation milestones (title acquisition)
	_check_title_milestones(faction, old_rep, new_rep)

	reputation_changed.emit(faction, new_rep)
	return new_rep

func get_reputation(faction: String) -> int:
	return _faction_reputations.get(faction, 0)

func get_reputation_tier(faction: String) -> String:
	var rep = get_reputation(faction)
	var tier = "Unknown"

	for threshold in REP_THRESHOLDS.keys():
		if rep >= threshold:
			tier = REP_THRESHOLDS[threshold]

	return tier

func get_all_reputations() -> Dictionary:
	return _faction_reputations.duplicate()

func _check_title_milestones(faction: String, old_rep: int, new_rep: int) -> void:
	# Check if any reputation milestones were crossed
	var milestones = {
		"SovereignCrown": {
			100: "Crown Agent",
			200: "Crown Investigator",
			300: "Magistrate"
		},
		"VeiledCurrent": {
			100: "Veiled Voice",
			200: "Prophet",
			300: "Veiled Heart"
		},
		"WildlandsAscendant": {
			100: "Ascendant Chosen",
			200: "Evolved",
			300: "Spore Herald"
		}
	}

	if faction in milestones:
		for rep_threshold in milestones[faction].keys():
			if old_rep < rep_threshold and new_rep >= rep_threshold:
				var title = milestones[faction][rep_threshold]
				_earn_title(title)

func _earn_title(title: String) -> void:
	if title not in PlayerProfile.titles:
		PlayerProfile.titles.append(title)
		IdentityLens.lens_changed.emit()
		title_earned.emit(title)

func get_active_faction() -> String:
	return _active_faction

func is_factional_conflict(npc_faction: String, player_faction: String) -> bool:
	# Determine if there's tension between player and NPC's factions
	if player_faction == "Factionless" or npc_faction == "Factionless":
		return false  # Factionless can interact with anyone

	if player_faction == npc_faction:
		return false  # Same faction

	# All factional pairs have some tension
	return true

func get_faction_disposition_modifier(npc_faction: String) -> int:
	var player_faction = _active_faction
	var player_rep = get_reputation(player_faction)

	if player_faction == npc_faction:
		return int(player_rep * 0.5)  # Friendly faction boost
	elif is_factional_conflict(npc_faction, player_faction):
		return -50  # Enemy faction penalty
	else:
		return 0  # Neutral

# ── Save/Load ──────────────────────────────────────────────────────────────
func save_state() -> Dictionary:
	return {
		"reputations": _faction_reputations.duplicate(),
		"active_faction": _active_faction
	}

func load_state(data: Dictionary) -> void:
	_faction_reputations = data.get("reputations", {})
	_active_faction = data.get("active_faction", "Factionless")
