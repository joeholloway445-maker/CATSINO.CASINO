extends Node
class_name CharacterIdentitySystem

# Unified Race → Frame → Mod character identity system
# Races: Determine texture, base model appearance
# Frames: Determine lights, sounds, class abilities (Warrior/Mage/Ranger)
# Mods: Determine in-game math (damage, defense), mobility (speed, agility)

# ═════════════════════════════════════════════════════════════════
# RACES (20 cat types - texture/appearance drivers)
# ═════════════════════════════════════════════════════════════════

const RACES = {
	"tabby": {
		"name": "Tabby",
		"cat_type": "domestic_shorthair",
		"texture_type": "morphic",
		"primary_color": Color(0.55, 0.42, 0.25),
		"fur_pattern": "striped",
		"size_modifier": 1.0,
		"base_stats": {"pow": 0, "res": 0, "spd": 0, "lck": 2}
	},
	"siamese": {
		"name": "Siamese",
		"cat_type": "siamese",
		"texture_type": "crystalline",
		"primary_color": Color(0.85, 0.78, 0.65),
		"fur_pattern": "colorpoint",
		"size_modifier": 0.9,
		"base_stats": {"pow": 0, "res": 0, "spd": 2, "lck": 0}
	},
	"maine_coon": {
		"name": "Maine Coon",
		"cat_type": "maine_coon",
		"texture_type": "biotech",
		"primary_color": Color(0.4, 0.3, 0.2),
		"fur_pattern": "fluffy",
		"size_modifier": 1.3,
		"base_stats": {"pow": 3, "res": 2, "spd": -1, "lck": 0}
	},
	"persian": {
		"name": "Persian",
		"cat_type": "persian",
		"texture_type": "regal",
		"primary_color": Color(0.95, 0.92, 0.85),
		"fur_pattern": "long_haired",
		"size_modifier": 1.1,
		"base_stats": {"pow": -1, "res": 2, "spd": -1, "lck": 3}
	},
	"bengal": {
		"name": "Bengal",
		"cat_type": "bengal",
		"texture_type": "solar",
		"primary_color": Color(0.85, 0.55, 0.2),
		"fur_pattern": "spotted",
		"size_modifier": 1.05,
		"base_stats": {"pow": 2, "res": 0, "spd": 3, "lck": 1}
	},
	"russian_blue": {
		"name": "Russian Blue",
		"cat_type": "russian_blue",
		"texture_type": "abyssal",
		"primary_color": Color(0.5, 0.55, 0.6),
		"fur_pattern": "short_dense",
		"size_modifier": 0.95,
		"base_stats": {"pow": 0, "res": 3, "spd": 0, "lck": 2}
	},
	"sphynx": {
		"name": "Sphynx",
		"cat_type": "sphynx",
		"texture_type": "spectral",
		"primary_color": Color(0.9, 0.8, 0.7),
		"fur_pattern": "hairless",
		"size_modifier": 0.85,
		"base_stats": {"pow": 1, "res": 0, "spd": 1, "lck": 4}
	},
	"ragdoll": {
		"name": "Ragdoll",
		"cat_type": "ragdoll",
		"texture_type": "symbiotic",
		"primary_color": Color(0.9, 0.85, 0.75),
		"fur_pattern": "colorpoint_silky",
		"size_modifier": 1.2,
		"base_stats": {"pow": 0, "res": 4, "spd": -2, "lck": 1}
	},
	"scottish_fold": {
		"name": "Scottish Fold",
		"cat_type": "scottish_fold",
		"texture_type": "amphibious",
		"primary_color": Color(0.6, 0.5, 0.4),
		"fur_pattern": "folded_ears",
		"size_modifier": 0.95,
		"base_stats": {"pow": 0, "res": 1, "spd": 1, "lck": 3}
	},
	"abyssinian": {
		"name": "Abyssinian",
		"cat_type": "abyssinian",
		"texture_type": "electric",
		"primary_color": Color(0.7, 0.45, 0.25),
		"fur_pattern": "ticked",
		"size_modifier": 0.9,
		"base_stats": {"pow": 1, "res": 0, "spd": 4, "lck": 2}
	},
	"burmese": {
		"name": "Burmese",
		"cat_type": "burmese",
		"texture_type": "mutated",
		"primary_color": Color(0.35, 0.25, 0.2),
		"fur_pattern": "satin",
		"size_modifier": 1.0,
		"base_stats": {"pow": 2, "res": 1, "spd": 1, "lck": 1}
	},
	"turkish_angora": {
		"name": "Turkish Angora",
		"cat_type": "turkish_angora",
		"texture_type": "celestial",
		"primary_color": Color(0.95, 0.95, 0.95),
		"fur_pattern": "silky_long",
		"size_modifier": 0.95,
		"base_stats": {"pow": 0, "res": 1, "spd": 2, "lck": 2}
	},
	"norwegian_forest": {
		"name": "Norwegian Forest",
		"cat_type": "norwegian_forest",
		"texture_type": "decayed",
		"primary_color": Color(0.45, 0.4, 0.3),
		"fur_pattern": "fluffy_long",
		"size_modifier": 1.25,
		"base_stats": {"pow": 3, "res": 3, "spd": -1, "lck": 0}
	},
	"birman": {
		"name": "Birman",
		"cat_type": "birman",
		"texture_type": "temporal",
		"primary_color": Color(0.88, 0.82, 0.7),
		"fur_pattern": "colorpoint_silky",
		"size_modifier": 1.05,
		"base_stats": {"pow": 0, "res": 2, "spd": 0, "lck": 4}
	},
	"tonkinese": {
		"name": "Tonkinese",
		"cat_type": "tonkinese",
		"texture_type": "dimensional",
		"primary_color": Color(0.55, 0.45, 0.35),
		"fur_pattern": "colorpoint_mink",
		"size_modifier": 0.95,
		"base_stats": {"pow": 1, "res": 1, "spd": 2, "lck": 2}
	},
	"devon_rex": {
		"name": "Devon Rex",
		"cat_type": "devon_rex",
		"texture_type": "phasic",
		"primary_color": Color(0.6, 0.55, 0.45),
		"fur_pattern": "curly_short",
		"size_modifier": 0.8,
		"base_stats": {"pow": 0, "res": 0, "spd": 3, "lck": 3}
	},
	"oriental": {
		"name": "Oriental",
		"cat_type": "oriental",
		"texture_type": "radiant",
		"primary_color": Color(0.3, 0.25, 0.2),
		"fur_pattern": "sleek_short",
		"size_modifier": 0.85,
		"base_stats": {"pow": 1, "res": 0, "spd": 2, "lck": 1}
	},
	"somali": {
		"name": "Somali",
		"cat_type": "somali",
		"texture_type": "voidlike",
		"primary_color": Color(0.65, 0.4, 0.2),
		"fur_pattern": "ticked_long",
		"size_modifier": 1.0,
		"base_stats": {"pow": 1, "res": 1, "spd": 3, "lck": 2}
	},
	"manx": {
		"name": "Manx",
		"cat_type": "manx",
		"texture_type": "digital",
		"primary_color": Color(0.4, 0.35, 0.3),
		"fur_pattern": "tailless",
		"size_modifier": 1.0,
		"base_stats": {"pow": 2, "res": 2, "spd": 1, "lck": 1}
	},
	"savannah": {
		"name": "Savannah",
		"cat_type": "savannah",
		"texture_type": "biotech",
		"primary_color": Color(0.75, 0.6, 0.3),
		"fur_pattern": "spotted_lean",
		"size_modifier": 1.35,
		"base_stats": {"pow": 4, "res": 1, "spd": 3, "lck": 0}
	}
}

# ═════════════════════════════════════════════════════════════════
# FRAMES (20 classes - light, sound, and ability drivers)
# ═════════════════════════════════════════════════════════════════

const FRAMES = {
	"warrior": {
		"name": "Warrior",
		"description": "Master of melee combat and defense",
		"light_color": Color.GOLD,
		"light_intensity": 1.2,
		"sound_theme": "metallic",
		"class_abilities": ["slash_1", "power_slash", "shield_bash"],
		"stat_bonuses": {"pow": 3, "res": 2}
	},
	"mage": {
		"name": "Mage",
		"description": "Master of elemental and arcane magic",
		"light_color": Color.PURPLE,
		"light_intensity": 1.5,
		"sound_theme": "magical",
		"class_abilities": ["fireball", "frost_bolt", "arcane_mastery"],
		"stat_bonuses": {"pow": 2, "spd": 1}
	},
	"ranger": {
		"name": "Ranger",
		"description": "Master of ranged combat and mobility",
		"light_color": Color.GREEN,
		"light_intensity": 1.3,
		"sound_theme": "nature",
		"class_abilities": ["arrow_shot", "multi_shot", "piercing_shot"],
		"stat_bonuses": {"spd": 3, "res": 1}
	},
	"paladin": {
		"name": "Paladin",
		"description": "Holy warrior with healing powers",
		"light_color": Color.WHITE,
		"light_intensity": 1.4,
		"sound_theme": "holy",
		"class_abilities": ["holy_strike", "divine_shield", "heal"],
		"stat_bonuses": {"pow": 2, "res": 3}
	},
	"rogue": {
		"name": "Rogue",
		"description": "Swift and deadly melee specialist",
		"light_color": Color.DARK_GRAY,
		"light_intensity": 0.8,
		"sound_theme": "stealth",
		"class_abilities": ["backstab", "shadow_clone", "evasion"],
		"stat_bonuses": {"spd": 4, "pow": 1}
	},
	"druid": {
		"name": "Druid",
		"description": "Nature-aligned spellcaster and shapeshifter",
		"light_color": Color.LIME,
		"light_intensity": 1.2,
		"sound_theme": "nature_magic",
		"class_abilities": ["wildshape", "entangle", "heal"],
		"stat_bonuses": {"res": 2, "pow": 1}
	},
	"necromancer": {
		"name": "Necromancer",
		"description": "Controller of death and undeath",
		"light_color": Color.DARK_RED,
		"light_intensity": 0.9,
		"sound_theme": "dark",
		"class_abilities": ["summon_undead", "curse", "drain_life"],
		"stat_bonuses": {"pow": 2, "lck": 1}
	},
	"bard": {
		"name": "Bard",
		"description": "Charismatic support and utility caster",
		"light_color": Color.CYAN,
		"light_intensity": 1.1,
		"sound_theme": "musical",
		"class_abilities": ["inspire", "charm", "song_of_healing"],
		"stat_bonuses": {"lck": 3, "spd": 1}
	},
	"monk": {
		"name": "Monk",
		"description": "Master of unarmed combat and meditation",
		"light_color": Color.ORANGE,
		"light_intensity": 1.0,
		"sound_theme": "martial_arts",
		"class_abilities": ["palm_strike", "meditation", "kick"],
		"stat_bonuses": {"spd": 2, "res": 1}
	},
	"cleric": {
		"name": "Cleric",
		"description": "Divine healer and support specialist",
		"light_color": Color.YELLOW,
		"light_intensity": 1.3,
		"sound_theme": "holy",
		"class_abilities": ["heal", "smite", "protection"],
		"stat_bonuses": {"res": 3, "pow": 1}
	},
	"warlock": {
		"name": "Warlock",
		"description": "Pact-bound caster with eldritch powers",
		"light_color": Color.MAGENTA,
		"light_intensity": 1.2,
		"sound_theme": "eldritch",
		"class_abilities": ["eldritch_blast", "hex", "summon"],
		"stat_bonuses": {"pow": 2, "lck": 1}
	},
	"barbarian": {
		"name": "Barbarian",
		"description": "Rage-fueled melee combatant",
		"light_color": Color.RED,
		"light_intensity": 1.4,
		"sound_theme": "primal",
		"class_abilities": ["rage", "cleave", "charge"],
		"stat_bonuses": {"pow": 4, "res": 1}
	},
	"paladin_shadow": {
		"name": "Shadow Paladin",
		"description": "Dark warrior with unholy abilities",
		"light_color": Color.DARK_MAGENTA,
		"light_intensity": 0.9,
		"sound_theme": "dark_holy",
		"class_abilities": ["shadow_strike", "unholy_shield", "drain"],
		"stat_bonuses": {"pow": 2, "res": 2}
	},
	"alchemist": {
		"name": "Alchemist",
		"description": "Potion master and transmuter",
		"light_color": Color.LIME,
		"light_intensity": 1.1,
		"sound_theme": "chemistry",
		"class_abilities": ["transmute", "create_potion", "elemental_infusion"],
		"stat_bonuses": {"pow": 1, "lck": 2}
	},
	"assassin": {
		"name": "Assassin",
		"description": "Lethal rogue specializing in instant kills",
		"light_color": Color.DARK_GRAY,
		"light_intensity": 0.7,
		"sound_theme": "stealth",
		"class_abilities": ["assassinate", "poison", "invisibility"],
		"stat_bonuses": {"pow": 2, "spd": 3}
	},
	"artificer": {
		"name": "Artificer",
		"description": "Techno-mage crafting magical items",
		"light_color": Color.CYAN,
		"light_intensity": 1.2,
		"sound_theme": "mechanical_magic",
		"class_abilities": ["forge_item", "turret", "enhancement"],
		"stat_bonuses": {"pow": 1, "res": 1}
	},
	"shaman": {
		"name": "Shaman",
		"description": "Spirit-channeler with elemental and healing powers",
		"light_color": Color.ORANGE,
		"light_intensity": 1.3,
		"sound_theme": "spiritual",
		"class_abilities": ["spirit_call", "elemental_surge", "heal"],
		"stat_bonuses": {"res": 2, "spd": 1}
	},
	"knight": {
		"name": "Knight",
		"description": "Armored warrior with heavy melee focus",
		"light_color": Color.SILVER,
		"light_intensity": 1.1,
		"sound_theme": "armor",
		"class_abilities": ["slash", "guard", "charge"],
		"stat_bonuses": {"pow": 3, "res": 2}
	},
	"sorcerer": {
		"name": "Sorcerer",
		"description": "Raw magical power channeler",
		"light_color": Color.BLUE,
		"light_intensity": 1.4,
		"sound_theme": "arcane",
		"class_abilities": ["fireball", "lightning", "spellshield"],
		"stat_bonuses": {"pow": 3, "spd": 1}
	},
	"gunslinger": {
		"name": "Gunslinger",
		"description": "Ranged specialist with rapid-fire combat",
		"light_color": Color.DARK_ORANGE,
		"light_intensity": 1.0,
		"sound_theme": "gunfire",
		"class_abilities": ["quick_draw", "rapid_fire", "headshot"],
		"stat_bonuses": {"spd": 3, "pow": 1}
	}
}

# ═════════════════════════════════════════════════════════════════
# MODS (20 physical modifications - in-game math and mobility)
# ═════════════════════════════════════════════════════════════════

const MODS = {
	"standard": {
		"name": "Standard",
		"description": "Balanced mobility and combat",
		"stat_modifiers": {"pow": 0, "res": 0, "spd": 0},
		"mobility_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"defense_multiplier": 1.0,
		"armor_visual": "none"
	},
	"heavy_armor": {
		"name": "Heavy Armor",
		"description": "Increased defense, reduced speed",
		"stat_modifiers": {"res": 3, "spd": -2},
		"mobility_multiplier": 0.8,
		"damage_multiplier": 0.95,
		"defense_multiplier": 1.3,
		"armor_visual": "full_plate"
	},
	"light_leather": {
		"name": "Light Leather",
		"description": "Balanced armor and speed",
		"stat_modifiers": {"res": 1, "spd": 1},
		"mobility_multiplier": 1.05,
		"damage_multiplier": 1.0,
		"defense_multiplier": 1.1,
		"armor_visual": "leather"
	},
	"robe": {
		"name": "Robe",
		"description": "Minimal armor, maximum mobility",
		"stat_modifiers": {"res": -1, "spd": 2},
		"mobility_multiplier": 1.15,
		"damage_multiplier": 1.05,
		"defense_multiplier": 0.9,
		"armor_visual": "robe"
	},
	"chainmail": {
		"name": "Chainmail",
		"description": "Good protection with moderate speed",
		"stat_modifiers": {"res": 2, "spd": -1},
		"mobility_multiplier": 0.9,
		"damage_multiplier": 0.98,
		"defense_multiplier": 1.2,
		"armor_visual": "chainmail"
	},
	"stealth_gear": {
		"name": "Stealth Gear",
		"description": "Evasion bonus, reduced damage output",
		"stat_modifiers": {"spd": 3, "pow": -1},
		"mobility_multiplier": 1.2,
		"damage_multiplier": 0.9,
		"defense_multiplier": 1.0,
		"armor_visual": "dark_cloak"
	},
	"reinforced": {
		"name": "Reinforced",
		"description": "Extra durability",
		"stat_modifiers": {"res": 2},
		"mobility_multiplier": 0.95,
		"damage_multiplier": 0.97,
		"defense_multiplier": 1.25,
		"armor_visual": "reinforced_plate"
	},
	"agile": {
		"name": "Agile",
		"description": "Prioritizes speed and evasion",
		"stat_modifiers": {"spd": 3, "res": -2},
		"mobility_multiplier": 1.25,
		"damage_multiplier": 1.02,
		"defense_multiplier": 0.8,
		"armor_visual": "light_cloth"
	},
	"battle_hardened": {
		"name": "Battle Hardened",
		"description": "Increased damage output",
		"stat_modifiers": {"pow": 2, "res": 1},
		"mobility_multiplier": 0.95,
		"damage_multiplier": 1.15,
		"defense_multiplier": 1.05,
		"armor_visual": "scarred_armor"
	},
	"crystalline": {
		"name": "Crystalline",
		"description": "Magical protection",
		"stat_modifiers": {"res": 3, "spd": -1},
		"mobility_multiplier": 0.9,
		"damage_multiplier": 1.1,
		"defense_multiplier": 1.3,
		"armor_visual": "crystal_armor"
	},
	"shadow": {
		"name": "Shadow",
		"description": "Dark enhancement with evasion",
		"stat_modifiers": {"pow": 1, "spd": 2},
		"mobility_multiplier": 1.1,
		"damage_multiplier": 1.1,
		"defense_multiplier": 0.95,
		"armor_visual": "shadow_cloak"
	},
	"radiant": {
		"name": "Radiant",
		"description": "Holy enhancement",
		"stat_modifiers": {"res": 2, "pow": 1},
		"mobility_multiplier": 1.0,
		"damage_multiplier": 1.12,
		"defense_multiplier": 1.15,
		"armor_visual": "holy_plate"
	},
	"viral": {
		"name": "Viral",
		"description": "Poison and decay enhancement",
		"stat_modifiers": {"pow": 2, "res": 0},
		"mobility_multiplier": 1.05,
		"damage_multiplier": 1.1,
		"defense_multiplier": 0.95,
		"armor_visual": "corrupted"
	},
	"adaptive": {
		"name": "Adaptive",
		"description": "Adjusts based on situation",
		"stat_modifiers": {"pow": 1, "res": 1, "spd": 1},
		"mobility_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"defense_multiplier": 1.0,
		"armor_visual": "shifting"
	},
	"berserker": {
		"name": "Berserker",
		"description": "Maximum damage, minimal protection",
		"stat_modifiers": {"pow": 4, "res": -2},
		"mobility_multiplier": 1.1,
		"damage_multiplier": 1.3,
		"defense_multiplier": 0.7,
		"armor_visual": "savage"
	},
	"tank": {
		"name": "Tank",
		"description": "Maximum defense",
		"stat_modifiers": {"res": 5, "spd": -3},
		"mobility_multiplier": 0.7,
		"damage_multiplier": 0.85,
		"defense_multiplier": 1.4,
		"armor_visual": "full_plate_enhanced"
	},
	"swiftblade": {
		"name": "Swiftblade",
		"description": "Speed and damage combined",
		"stat_modifiers": {"pow": 2, "spd": 3},
		"mobility_multiplier": 1.2,
		"damage_multiplier": 1.12,
		"defense_multiplier": 0.85,
		"armor_visual": "sleek"
	},
	"mystic": {
		"name": "Mystic",
		"description": "Magic-focused enhancement",
		"stat_modifiers": {"pow": 3, "res": 1, "spd": -1},
		"mobility_multiplier": 0.95,
		"damage_multiplier": 1.2,
		"defense_multiplier": 1.0,
		"armor_visual": "enchanted"
	},
	"venomous": {
		"name": "Venomous",
		"description": "Poison damage enhancement",
		"stat_modifiers": {"pow": 1, "spd": 2},
		"mobility_multiplier": 1.1,
		"damage_multiplier": 1.15,
		"defense_multiplier": 0.9,
		"armor_visual": "toxic"
	},
	"ethereal": {
		"name": "Ethereal",
		"description": "Phase and ghost enhancement",
		"stat_modifiers": {"spd": 4, "res": 1},
		"mobility_multiplier": 1.3,
		"damage_multiplier": 0.95,
		"defense_multiplier": 1.1,
		"armor_visual": "ghostly"
	}
}

# ═════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═════════════════════════════════════════════════════════════════

func get_complete_character(race_id: String, frame_id: String, mod_id: String) -> Dictionary:
	"""Combine race, frame, and mod into complete character data"""
	var race = RACES.get(race_id, {})
	var frame = FRAMES.get(frame_id, {})
	var mod = MODS.get(mod_id, {})

	if race.is_empty() or frame.is_empty() or mod.is_empty():
		return {}

	return {
		"race_id": race_id,
		"frame_id": frame_id,
		"mod_id": mod_id,
		"name": "%s %s %s" % [race.get("name", ""), frame.get("name", ""), mod.get("name", "")],
		# Appearance (from Race)
		"texture_type": race.get("texture_type", ""),
		"primary_color": race.get("primary_color", Color.WHITE),
		"fur_pattern": race.get("fur_pattern", ""),
		"size_modifier": race.get("size_modifier", 1.0),
		# Abilities & Sounds (from Frame)
		"class_abilities": frame.get("class_abilities", []),
		"light_color": frame.get("light_color", Color.WHITE),
		"light_intensity": frame.get("light_intensity", 1.0),
		"sound_theme": frame.get("sound_theme", ""),
		# Math & Mobility (from Mod)
		"stat_modifiers": mod.get("stat_modifiers", {}),
		"mobility_multiplier": mod.get("mobility_multiplier", 1.0),
		"damage_multiplier": mod.get("damage_multiplier", 1.0),
		"defense_multiplier": mod.get("defense_multiplier", 1.0),
		"armor_visual": mod.get("armor_visual", "")
	}

func get_all_races() -> Array[Dictionary]:
	var races = []
	for race_id in RACES.keys():
		races.append(RACES[race_id])
	return races

func get_all_frames() -> Array[Dictionary]:
	var frames = []
	for frame_id in FRAMES.keys():
		frames.append(FRAMES[frame_id])
	return frames

func get_all_mods() -> Array[Dictionary]:
	var mods = []
	for mod_id in MODS.keys():
		mods.append(MODS[mod_id])
	return mods
