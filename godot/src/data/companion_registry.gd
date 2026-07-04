class_name CompanionRegistry
# Unified registry combining all companion rosters
# SC001-SC150, WA001-WA150, VC001-VC150, FL001-FL100 = 550 (first 500 are canonical)

static func get_all() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	all.append_array(CompanionRoster.SC_COMPANIONS)
	all.append_array(CompanionRosterExtended.SC_COMPANIONS_2 if "SC_COMPANIONS_2" in CompanionRosterExtended else [])
	all.append_array(CompanionRosterExtended.WA_COMPANIONS if "WA_COMPANIONS" in CompanionRosterExtended else [])
	all.append_array(CompanionRosterExtended2.WA_COMPANIONS_2 if ClassDB.class_exists("CompanionRosterExtended2") else [])
	all.append_array(CompanionRosterExtended3.FL_COMPANIONS if ClassDB.class_exists("CompanionRosterExtended3") else [])
	all.append_array(CompanionRosterExtended4.SC_COMPANIONS_3 if ClassDB.class_exists("CompanionRosterExtended4") else [])
	all.append_array(CompanionRosterExtended5.WA_COMPANIONS_3 if ClassDB.class_exists("CompanionRosterExtended5") else [])
	all.append_array(CompanionRosterExtended6.VC_COMPANIONS_3 if ClassDB.class_exists("CompanionRosterExtended6") else [])
	all.append_array(CompanionRosterExtended7.FL_COMPANIONS_3 if ClassDB.class_exists("CompanionRosterExtended7") else [])
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

static func get_by_faction(faction: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c in get_all():
		if c.get("faction") == faction:
			result.append(c.duplicate())
	return result

static func get_by_rarity(rarity: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c in get_all():
		if c.get("rarity") == rarity:
			result.append(c.duplicate())
	return result

static func get_random(faction: String = "") -> Dictionary:
	var pool := get_by_faction(faction) if faction != "" else get_all()
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()].duplicate()

static func get_total_count() -> int:
	return get_all().size()
