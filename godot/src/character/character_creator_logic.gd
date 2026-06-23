class_name CharacterCreatorLogic
# Pure logic for the character creator — no UI dependency

static func build_starting_stats(race_id: String, faction: String, frame_id: String) -> Dictionary:
	var base := {pow=10, res=10, spd=10, lck=10, sty=10}
	var race_bonuses := RaceDataCharacter.get_stat_bonuses(race_id)
	for stat in race_bonuses.keys():
		base[stat] = base.get(stat, 0) + race_bonuses[stat]
	var faction_bonuses := FactionSystem.get_stat_bonuses(faction)
	for stat in faction_bonuses.keys():
		base[stat] = base.get(stat, 0) + faction_bonuses.get(stat, 0)
	var frame_data := FrameModData.get_frame(frame_id)
	if not frame_data.is_empty():
		for stat in ["pow", "res", "spd", "lck", "sty"]:
			base[stat] = frame_data.get(stat, base[stat])
	return base

static func validate_name(name: String) -> bool:
	return name.length() >= 2 and name.length() <= 20 and name.is_valid_identifier()

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
	PlayerProfile.set_faction(faction)
	PlayerProfile.set_frame(frame_id)
	PlayerProfile.username = name
	var companions := get_starter_companions(faction)
	for c in companions:
		PlayerProfile.companions.append(c)
	PlayerProfile.save()
