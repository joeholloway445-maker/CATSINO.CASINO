class_name CompanionRegistry
# Unified registry combining all companion rosters.
# SC001-SC150, WA001-WA150, VC001-VC150, FL001-FL100 ≈ 550 (first 500 canonical).
# All display names resolve through OmniDexRegistry.companion_display_name().

static func get_all() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	all.append_array(CompanionRoster.get_sovereign_crown_roster())
	all.append_array(CompanionRoster.get_wildlands_ascendant_roster())
	all.append_array(CompanionRoster.get_veiled_current_roster())
	all.append_array(CompanionRoster.get_factionless_roster())
	all.append_array(CompanionRosterExtended.get_sovereign_crown_extended())
	all.append_array(CompanionRosterExtended2.get_wildlands_extended())
	all.append_array(CompanionRosterExtended2.get_veiled_extended())
	all.append_array(CompanionRosterExtended3.get_factionless_extended())
	all.append_array(CompanionRosterExtended4.get_sc_second_century())
	all.append_array(CompanionRosterExtended5.get_wa_third_fifty())
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

static func get_by_faction(faction: String) -> Array[Dictionary]:
	var want := normalize_faction(faction)
	var result: Array[Dictionary] = []
	for c in get_all():
		if normalize_faction(str(c.get("faction", ""))) == want:
			result.append(c.duplicate())
	return result

static func get_by_rarity(rarity: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c in get_all():
		if c.get("rarity") == rarity or str(c.get("rarity", "")) == str(rarity):
			result.append(c.duplicate())
	return result

static func get_random(faction: String = "") -> Dictionary:
	var pool := get_by_faction(faction) if faction != "" else get_all()
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()].duplicate()

static func get_total_count() -> int:
	return get_all().size()

static func display_name(companion_id: String) -> String:
	return OmniDexRegistry.companion_display_name(companion_id)
