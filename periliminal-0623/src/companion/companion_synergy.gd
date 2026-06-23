class_name CompanionSynergyCalculator
# Calculates team synergy bonus from equipped companions

static func calculate(companions: Array[Dictionary], player_faction: String) -> float:
	if companions.is_empty():
		return 0.0

	var faction_counts: Dictionary = {}
	for c in companions:
		var fac: String = c.get("faction", "Factionless")
		faction_counts[fac] = faction_counts.get(fac, 0) + 1

	var synergy := 0.0

	# Same-faction bonus: 0.05 per companion matching player faction
	var matching := faction_counts.get(player_faction, 0)
	synergy += matching * 0.05

	# Full team same faction: extra 0.1
	if matching == companions.size() and matching > 0:
		synergy += 0.10

	# Type diversity bonus (having all 3 types)
	var types: Dictionary = {}
	for c in companions:
		types[c.get("type", "balanced")] = true
	if types.has("light") and types.has("heavy") and types.has("tech"):
		synergy += 0.05

	# Rarity bonus
	for c in companions:
		match c.get("rarity", "common"):
			"uncommon": synergy += 0.01
			"rare": synergy += 0.02
			"epic": synergy += 0.04
			"legendary": synergy += 0.08

	return minf(synergy, 0.80)  # cap at 80%

static func get_lck_bonus(companions: Array[Dictionary]) -> int:
	var total := 0
	for c in companions:
		total += int(c.get("lck", 0))
	return int(total * 0.1)  # 10% of companion LCK stacks

static func get_type_mult(attack_type: String, defender_type: String) -> float:
	const TYPE_TABLE := {
		"light": {"heavy": 0.5, "tech": 1.5, "light": 1.0, "balanced": 1.0},
		"heavy": {"light": 1.5, "tech": 0.5, "heavy": 1.0, "balanced": 1.0},
		"tech": {"heavy": 1.5, "light": 0.5, "tech": 1.0, "balanced": 1.0},
		"balanced": {"light": 1.0, "heavy": 1.0, "tech": 1.0, "balanced": 1.0},
	}
	return TYPE_TABLE.get(attack_type, {}).get(defender_type, 1.0)
