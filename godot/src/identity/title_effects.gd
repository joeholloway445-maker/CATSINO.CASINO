extends Node
class_name TitleEffects

# Title effects: how earned titles change gameplay and identity

const TITLE_EFFECTS = {
	"Unbound": {
		"identity_multiplier": 2.0,
		"faction_rep_cost": 50,
		"npc_reaction": "wary",
		"description": "You've rejected all factions. The world respects your independence."
	},
	"Synchronized": {
		"identity_multiplier": 2.0,
		"faction_rep": {"SovereignCrown": 100},
		"npc_reaction": "deferential",
		"stat_bonus": {"efficiency": 0.2},
		"description": "You are perfectly optimized. The Crown sees you as one of their own."
	},
	"Surrendered": {
		"identity_multiplier": 2.0,
		"faction_rep": {"VeiledCurrent": 100},
		"npc_reaction": "reverent",
		"ability_unlock": "prophecy_sight",
		"description": "You have accepted mystery. The Veiled Current speaks through you."
	},
	"Evolved": {
		"identity_multiplier": 2.0,
		"faction_rep": {"WildlandsAscendant": 100},
		"npc_reaction": "territorial",
		"stat_bonus": {"adaptation": 0.3},
		"description": "You are becoming something new. The Wildlands recognize you as kin."
	},
	"Witness": {
		"identity_multiplier": 3.0,
		"faction_rep": {},
		"npc_reaction": "curious",
		"ability_unlock": "omniscient_perspective",
		"description": "You have seen all. You are the keeper of truth."
	},
	"Breaker of Chains": {
		"identity_multiplier": 3.0,
		"faction_rep": {"SovereignCrown": -200, "VeiledCurrent": -100, "WildlandsAscendant": -100},
		"npc_reaction": "fearful",
		"ability_unlock": "system_subversion",
		"description": "You have sabotaged every faction. The world sees you as chaos."
	},
	"Pariah": {
		"identity_multiplier": 2.5,
		"faction_rep": {"SovereignCrown": -100, "VeiledCurrent": -100, "WildlandsAscendant": -100},
		"npc_reaction": "hostile",
		"stat_penalty": {"reputation": -0.5},
		"description": "Every NPC you met, you betrayed. No one trusts you."
	},
	"Beloved": {
		"identity_multiplier": 4.0,
		"npc_reaction": "affectionate",
		"ability_unlock": "mass_influence",
		"description": "Five or more NPCs call you friend. You are the center of their world."
	},
	"Crown Agent": {
		"identity_multiplier": 1.5,
		"faction_rep": {"SovereignCrown": 150},
		"npc_reaction": "deferential",
		"stat_bonus": {"authority": 0.15},
		"description": "You serve the Sovereign Crown. Your loyalty is your power."
	},
	"Veiled Voice": {
		"identity_multiplier": 1.5,
		"faction_rep": {"VeiledCurrent": 150},
		"npc_reaction": "reverent",
		"ability_unlock": "prophecy_channeling",
		"description": "You speak the language of Liminal. Mysteries bow to you."
	},
	"Ascendant Chosen": {
		"identity_multiplier": 1.5,
		"faction_rep": {"WildlandsAscendant": 150},
		"npc_reaction": "respectful",
		"stat_bonus": {"combat": 0.15},
		"description": "The Wildlands have marked you for evolution. You are one of them."
	}
}

static func get_title_effect(title: String) -> Dictionary:
	return TITLE_EFFECTS.get(title, {})

static func apply_title_effects(player_profile: Dictionary) -> void:
	var total_multiplier = 1.0
	var combined_effects = {
		"identity_multipliers": [],
		"stat_bonuses": {},
		"stat_penalties": {},
		"abilities_unlocked": [],
		"faction_effects": {},
		"npc_reactions": []
	}

	# Each title multiplies identity seed by 2 (or more for special titles)
	for title in player_profile.get("titles", []):
		var effect = get_title_effect(title)
		if not effect.is_empty():
			var mult = effect.get("identity_multiplier", 2.0)
			combined_effects["identity_multipliers"].append({
				"title": title,
				"multiplier": mult
			})
			total_multiplier *= mult

			# Collect stat bonuses
			if "stat_bonus" in effect:
				for stat in effect["stat_bonus"].keys():
					if stat not in combined_effects["stat_bonuses"]:
						combined_effects["stat_bonuses"][stat] = 0.0
					combined_effects["stat_bonuses"][stat] += effect["stat_bonus"][stat]

			# Collect stat penalties
			if "stat_penalty" in effect:
				for stat in effect["stat_penalty"].keys():
					if stat not in combined_effects["stat_penalties"]:
						combined_effects["stat_penalties"][stat] = 0.0
					combined_effects["stat_penalties"][stat] += effect["stat_penalty"][stat]

			# Unlock abilities
			if "ability_unlock" in effect:
				combined_effects["abilities_unlocked"].append(effect["ability_unlock"])

			# Faction effects
			if "faction_rep" in effect:
				for faction in effect["faction_rep"].keys():
					if faction not in combined_effects["faction_effects"]:
						combined_effects["faction_effects"][faction] = 0
					combined_effects["faction_effects"][faction] += effect["faction_rep"][faction]

			# NPC reactions
			if "npc_reaction" in effect:
				combined_effects["npc_reactions"].append({
					"title": title,
					"reaction": effect["npc_reaction"]
				})

	# Store combined effects in player profile
	player_profile["title_effects"] = combined_effects
	player_profile["total_identity_multiplier"] = total_multiplier

	# Apply stat bonuses/penalties to player stats
	_apply_stat_modifications(combined_effects)

	# Apply faction reputation effects
	_apply_faction_effects(combined_effects)

	# Unlock abilities
	_unlock_abilities(combined_effects["abilities_unlocked"])

static func _apply_stat_modifications(effects: Dictionary) -> void:
	var bonuses = effects.get("stat_bonuses", {})
	var penalties = effects.get("stat_penalties", {})

	for stat in bonuses.keys():
		PlayerProfile.add_stat_modifier(stat, bonuses[stat])

	for stat in penalties.keys():
		PlayerProfile.add_stat_modifier(stat, penalties[stat])

static func _apply_faction_effects(effects: Dictionary) -> void:
	var faction_effects = effects.get("faction_effects", {})

	for faction in faction_effects.keys():
		var rep_change = faction_effects[faction]
		FactionManager.add_reputation(faction, rep_change)

static func _unlock_abilities(abilities: Array) -> void:
	for ability in abilities:
		PlayerProfile.unlock_ability(ability)

# ── NPC Reaction Modifiers ─────────────────────────────────────────────────
static func get_npc_reaction_modifier(npc_id: String, player_profile: Dictionary) -> Dictionary:
	var reactions = player_profile.get("title_effects", {}).get("npc_reactions", [])
	var combined_reaction = "neutral"
	var reaction_strength = 0

	for reaction_data in reactions:
		match reaction_data["reaction"]:
			"deferential":
				combined_reaction = "deferential"
				reaction_strength = 1
			"reverent":
				combined_reaction = "reverent"
				reaction_strength = 2
			"affectionate":
				combined_reaction = "affectionate"
				reaction_strength = 3
			"respectful":
				combined_reaction = "respectful"
				reaction_strength = 1
			"wary":
				combined_reaction = "wary"
				reaction_strength = 1
			"fearful":
				combined_reaction = "fearful"
				reaction_strength = -2
			"hostile":
				combined_reaction = "hostile"
				reaction_strength = -3

	return {
		"reaction": combined_reaction,
		"strength": reaction_strength,
		"dialogue_modifier": _get_dialogue_modifier(combined_reaction)
	}

static func _get_dialogue_modifier(reaction: String) -> String:
	match reaction:
		"deferential":
			return "They speak to you with formal respect."
		"reverent":
			return "They treat you as something sacred."
		"affectionate":
			return "They light up when they see you."
		"respectful":
			return "They nod with genuine recognition."
		"wary":
			return "They watch you carefully, suspiciously."
		"fearful":
			return "They flinch when you approach."
		"hostile":
			return "They turn their back on you."
		_:
			return ""

# ── Cosmetic Changes ───────────────────────────────────────────────────────
static func get_title_cosmetics(titles: Array) -> Dictionary:
	var cosmetics = {
		"aura_color": Color.WHITE,
		"aura_intensity": 0.0,
		"title_badge": null,
		"particle_effect": null
	}

	if titles.is_empty():
		return cosmetics

	# Multiple titles create combined aura
	var aura_colors = []
	var max_intensity = 0.0

	for title in titles:
		match title:
			"Unbound":
				aura_colors.append(Color.GRAY)
				max_intensity = max(max_intensity, 0.3)
			"Synchronized":
				aura_colors.append(Color.GOLD)
				max_intensity = max(max_intensity, 0.5)
			"Surrendered":
				aura_colors.append(Color.INDIGO)
				max_intensity = max(max_intensity, 0.6)
			"Evolved":
				aura_colors.append(Color.GREEN)
				max_intensity = max(max_intensity, 0.4)
			"Witness":
				aura_colors.append(Color.CYAN)
				max_intensity = max(max_intensity, 0.7)
			"Beloved":
				aura_colors.append(Color.PINK)
				max_intensity = max(max_intensity, 0.8)

	# Blend aura colors
	if not aura_colors.is_empty():
		var blended = aura_colors[0]
		for i in range(1, aura_colors.size()):
			blended = blended.lerp(aura_colors[i], 0.3)
		cosmetics["aura_color"] = blended
		cosmetics["aura_intensity"] = max_intensity

	# Particle effects for high-value titles
	if "Beloved" in titles:
		cosmetics["particle_effect"] = "hearts_and_light"
	elif "Witness" in titles:
		cosmetics["particle_effect"] = "starfield_orbit"
	elif "Breaker of Chains" in titles:
		cosmetics["particle_effect"] = "shattered_chains"

	return cosmetics

# ── Identity Rarity Display ────────────────────────────────────────────────
static func get_rarity_text(identity_seed: int) -> String:
	# Already calculated in IdentityLens.rarity_denominator()
	# This just formats it
	var denominator = IdentityLens.rarity_denominator()
	return "You are 1 in %s." % _format_number(denominator)

static func _format_number(n: int) -> String:
	var s = str(n)
	var out = ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
