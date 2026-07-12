class_name CompanionRegistry
# Unified registry combining all companion rosters.
# Uses each roster file's real API (static funcs / const arrays).

static func get_all() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	all.append_array(CompanionRoster.get_sovereign_crown_roster())
	all.append_array(CompanionRoster.get_wildlands_ascendant_roster())
	all.append_array(CompanionRoster.get_veiled_current_roster())
	all.append_array(CompanionRoster.get_factionless_roster())
	all.append_array(CompanionRosterExtended.get_sovereign_crown_extended())
	all.append_array(CompanionRosterExtended2.WILDLANDS_EXTENDED)
	all.append_array(CompanionRosterExtended2.VEILED_EXTENDED)
	all.append_array(CompanionRosterExtended3.FACTIONLESS_EXTENDED)
	all.append_array(CompanionRosterExtended4.SC_SECOND_CENTURY)
	all.append_array(CompanionRosterExtended5.WA_THIRD_FIFTY)
	all.append_array(CompanionRosterExtended6.VC_COMPANIONS_3)
	all.append_array(CompanionRosterExtended7.FL_COMPANIONS_3)
	all.append_array(CompanionRosterExtended8.PRESTIGE_COMPANIONS)
	return all

static func get_by_id(companion_id: String) -> Dictionary:
	for c in get_all():
		if c.get("id") == companion_id:
			return c.duplicate()
	return {}

## Roster files use both "SovereignCrown" and "sovereign_crown" styles.
static func normalize_faction(f: String) -> String:
	match f.to_lower().replace("_", "").replace(" ", ""):
		"sovereigncrown": return "SovereignCrown"
		"wildlandsascendant", "wildlandsascendants": return "WildlandsAscendant"
		"veiledcurrent": return "VeiledCurrent"
		_: return "Factionless"

## Entities are faction-exclusive: each faction's roster is only accessible
## to its members. The Factionless entities are the Lone Wolf roster —
## accessible only to players who stay Factionless.
static func is_accessible(entity: Dictionary, player_faction: String) -> bool:
	return normalize_faction(str(entity.get("faction", ""))) == normalize_faction(player_faction)

static func accessible_roster(player_faction: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c in get_all():
		if is_accessible(c, player_faction):
			result.append(c)
	return result

static func get_random(player_faction: String = "") -> Dictionary:
	var pool := accessible_roster(player_faction) if not player_faction.is_empty() else get_all()
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()].duplicate()

static func get_by_faction(faction: String) -> Array[Dictionary]:
	return accessible_roster(faction)
