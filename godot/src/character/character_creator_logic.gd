class_name CharacterCreatorLogic
# Pure logic for the character creator — no UI dependency
# Autoload access via AutoloadGate (class_name scripts must not bare-ref Autoloads).

static func build_starting_stats(race_id: String, faction: String, frame_id: String, mod_id: String = "") -> Dictionary:
	var base := {pow=10, res=10, spd=10, lck=10, sty=10}
	var race_bonuses := RaceDataCharacter.get_stat_bonuses(race_id)
	for stat in race_bonuses.keys():
		base[stat] = base.get(stat, 0) + race_bonuses[stat]
	var faction_bonuses: Dictionary = {}
	var factions := AutoloadGate.get_node("FactionSystem")
	if factions and factions.has_method("get_stat_bonuses"):
		faction_bonuses = factions.call("get_stat_bonuses", faction)
	for stat in faction_bonuses.keys():
		base[stat] = base.get(stat, 0) + faction_bonuses.get(stat, 0)
	# Frames and mods carry their stats in `stat_bonus` and ADD to the base —
	# they never replace the race/faction contributions.
	base = FrameModData.apply_frame_stats(frame_id, base)
	if not mod_id.is_empty():
		base = FrameModData.apply_mod_stats(mod_id, base)
	return base

static func validate_name(name: String) -> bool:
	var trimmed := name.strip_edges()
	if trimmed.length() < 2 or trimmed.length() > 20:
		return false
	# Allow spaces between words; reject control / punctuation noise.
	var cleaned := trimmed.replace(" ", "")
	return cleaned.is_valid_identifier()

static func get_starter_companions(faction: String) -> Array[String]:
	match faction:
		"SovereignCrown": return ["SC001", "SC002"]
		"WildlandsAscendant": return ["WA001", "WA002"]
		"VeiledCurrent": return ["VC001", "VC002"]
		_: return ["FL001", "FL002"]

static func build_loadout(race_id: String, frame_id: String, mod_id: String = "") -> Dictionary:
	return {
		"race": RaceDataCharacter.get_race(race_id),
		"frame": FrameModData.get_frame(frame_id),
		"mod": FrameModData.get_mod(mod_id) if not mod_id.is_empty() else {},
	}

static func apply_creation(race_id: String, faction: String, frame_id: String, name: String) -> void:
	var profile := AutoloadGate.get_node("PlayerProfile")
	if profile == null:
		push_error("CharacterCreatorLogic: PlayerProfile unavailable")
		return
	profile.call("set_faction", faction)
	profile.call("set_race", race_id)
	profile.call("set_frame", frame_id)
	profile.set("username", name.strip_edges())
	var companions := get_starter_companions(faction)
	var active: Array = profile.get("active_companion_ids")
	if active == null:
		active = []
	for c in companions:
		if c not in active:
			active.append(c)
	profile.set("active_companion_ids", active)
	profile.set("has_expedition", true)
	if profile.has_method("_save"):
		profile.call("_save")
	if profile.has_signal("profile_updated"):
		profile.emit_signal("profile_updated")
