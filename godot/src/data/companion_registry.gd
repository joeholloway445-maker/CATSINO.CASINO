class_name CompanionRegistry
extends RefCounted
## Canonical companion roster accessors for OmniDex and related UIs.
## Prefer shared consts over fragile get_script() lookups.

static func get_all() -> Array:
	var out: Array = []
	out.append_array(WildlandsExtendedCompanions.WILDLANDS_EXTENDED)
	out.append_array(VeiledCurrentExtendedCompanions.VEILED_EXTENDED)
	out.append_array(FactionlessExtendedCompanions.FACTIONLESS_EXTENDED)
	out.append_array(SovereignCrownSecondCentury.SC_SECOND_CENTURY)
	out.append_array(WildlandsAscendantsThirdFifty.WA_THIRD_FIFTY)
	out.append_array(VeiledCurrentCompanions.VC_COMPANIONS)
	out.append_array(FactionlessCompanions.FL_COMPANIONS)
	out.append_array(PrestigeCompanions.PRESTIGE_COMPANIONS)
	return out


static func get_by_id(companion_id: String) -> Dictionary:
	for companion in get_all():
		if str(companion.get("id", "")) == companion_id:
			return companion
	return {}


static func get_by_rarity(rarity: String) -> Array:
	var out: Array = []
	for companion in get_all():
		if str(companion.get("rarity", "")) == rarity:
			out.append(companion)
	return out


static func get_total_count() -> int:
	return get_all().size()


static func display_name(companion_id: String) -> String:
	return OmniDexRegistry.companion_display_name(companion_id)


static func get_random(rng: RandomNumberGenerator = null) -> Dictionary:
	var accessible := CompanionUnlockSystem.accessible_roster()
	if accessible.is_empty():
		return {}
	var local_rng := rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		local_rng.randomize()
	return accessible[local_rng.randi() % accessible.size()]


static func get_by_faction(faction: String) -> Array:
	var out: Array = []
	for companion in CompanionUnlockSystem.accessible_roster():
		if str(companion.get("faction", "")) == faction:
			out.append(companion)
	return out
