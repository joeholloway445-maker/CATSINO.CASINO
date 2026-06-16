class_name RaceLoreExtended
# Extended lore, abilities, and race-specific game variants for all 20 races

const RACE_GAME_BONUSES: Dictionary = {
	"Nyx": {
		slot_mult=1.15, race_spd_bonus=5, combat_crit=0.08,
		signature_move="Void Phase", signature_desc="Phases through the first attack of each combat round",
		hometown_district="arcade_galaxy", unlock_cost_coins=0,
	},
	"Ember": {
		slot_mult=1.0, race_spd_bonus=0, combat_crit=0.12,
		signature_move="Combustion Strike", signature_desc="Next attack deals 1.4x damage if opponent used Heavy type",
		hometown_district="cat_coliseum", unlock_cost_coins=500,
	},
	"Glacial": {
		slot_mult=1.0, race_spd_bonus=-5, combat_crit=0.05,
		signature_move="Frost Armor", signature_desc="Reduces incoming damage by 20% for 3 turns",
		hometown_district="cat_forest", unlock_cost_coins=500,
	},
	"Tempest": {
		slot_mult=1.05, race_spd_bonus=10, combat_crit=0.10,
		signature_move="Thunderclap", signature_desc="Stuns opponent for 1 turn on crit",
		hometown_district="neon_alley", unlock_cost_coins=750,
	},
	"Void": {
		slot_mult=1.25, race_spd_bonus=0, combat_crit=0.06,
		signature_move="Entropy Wave", signature_desc="+25% slot multiplier when active, but -15 RES",
		hometown_district="arcade_galaxy", unlock_cost_coins=0,
	},
	"Photon": {
		slot_mult=1.10, race_spd_bonus=8, combat_crit=0.09,
		signature_move="Light Speed", signature_desc="Guaranteed first strike advantage, SPD check bypassed",
		hometown_district="neon_alley", unlock_cost_coins=750,
	},
	"Bloom": {
		slot_mult=1.05, race_spd_bonus=0, combat_crit=0.07,
		signature_move="Petal Heal", signature_desc="Restores 10 RES points after each combat win",
		hometown_district="cat_forest", unlock_cost_coins=500,
	},
	"Aqua": {
		slot_mult=1.0, race_spd_bonus=12, combat_crit=0.08,
		signature_move="Tidal Surge", signature_desc="+12 SPD bonus in water/river track segments",
		hometown_district="neon_alley", unlock_cost_coins=500,
	},
	"Aether": {
		slot_mult=1.15, race_spd_bonus=6, combat_crit=0.11,
		signature_move="Aether Step", signature_desc="50% chance to dodge Tech-type attacks entirely",
		hometown_district="paw_vegas", unlock_cost_coins=1000,
	},
	"Shadow": {
		slot_mult=1.10, race_spd_bonus=5, combat_crit=0.15,
		signature_move="Umbral Strike", signature_desc="Crit chance doubles if attacking from behind (flanking)",
		hometown_district="paw_vegas", unlock_cost_coins=1000,
	},
	"Crimson": {
		slot_mult=1.0, race_spd_bonus=0, combat_crit=0.10,
		signature_move="Bloodrush", signature_desc="+5 POW stacking for each consecutive win (max +25)",
		hometown_district="cat_coliseum", unlock_cost_coins=750,
	},
	"Bolt": {
		slot_mult=1.05, race_spd_bonus=15, combat_crit=0.09,
		signature_move="Arc Dash", signature_desc="Teleports to end of race track on winning the last lap",
		hometown_district="neon_alley", unlock_cost_coins=1000,
	},
	"Prism": {
		slot_mult=1.20, race_spd_bonus=2, combat_crit=0.08,
		signature_move="Refraction", signature_desc="Splits into 3 afterimages; 1 is real; opponent must guess",
		hometown_district="arcade_galaxy", unlock_cost_coins=1250,
	},
	"Verdant": {
		slot_mult=1.05, race_spd_bonus=0, combat_crit=0.06,
		signature_move="Root Grip", signature_desc="Prevents opponent escape/flee for 2 turns",
		hometown_district="cat_forest", unlock_cost_coins=500,
	},
	"Flame": {
		slot_mult=1.0, race_spd_bonus=3, combat_crit=0.14,
		signature_move="Inferno Burst", signature_desc="Every 3rd attack deals 2x fire damage",
		hometown_district="cat_coliseum", unlock_cost_coins=750,
	},
	"Storm": {
		slot_mult=1.10, race_spd_bonus=8, combat_crit=0.12,
		signature_move="Cyclone Claw", signature_desc="AoE attack hits all opponents in team battles",
		hometown_district="cat_coliseum", unlock_cost_coins=1000,
	},
	"Lunar": {
		slot_mult=1.15, race_spd_bonus=4, combat_crit=0.10,
		signature_move="Moonrise Fury", signature_desc="All stats +15% during the in-game night cycle",
		hometown_district="paw_vegas", unlock_cost_coins=1000,
	},
	"Obsidian": {
		slot_mult=1.0, race_spd_bonus=0, combat_crit=0.07,
		signature_move="Stone Skin", signature_desc="Absorbs first 30 damage of every combat, no exceptions",
		hometown_district="cat_forest", unlock_cost_coins=500,
	},
	"Radiant": {
		slot_mult=1.20, race_spd_bonus=3, combat_crit=0.09,
		signature_move="Solar Flare", signature_desc="Blinds all opponents for 1 turn; they miss their attacks",
		hometown_district="paw_vegas", unlock_cost_coins=1500,
	},
	"Quantum": {
		slot_mult=1.30, race_spd_bonus=7, combat_crit=0.13,
		signature_move="Superposition", signature_desc="Exists in win/lose state until observed; 60% collapses to win",
		hometown_district="arcade_galaxy", unlock_cost_coins=2000,
	},
}

static func get_game_bonus(race_name: String) -> Dictionary:
	return RACE_GAME_BONUSES.get(race_name, {})

static func get_signature_move(race_name: String) -> Dictionary:
	var bonus = get_game_bonus(race_name)
	if bonus.is_empty(): return {}
	return {
		"name": bonus.get("signature_move", ""),
		"desc": bonus.get("signature_desc", ""),
	}

static func get_best_races_for(game_type: String) -> Array[String]:
	var ranked: Array[Dictionary] = []
	for race_name in RACE_GAME_BONUSES.keys():
		var b = RACE_GAME_BONUSES[race_name]
		var score := 0.0
		match game_type:
			"slots": score = b.get("slot_mult", 1.0)
			"racing": score = float(b.get("race_spd_bonus", 0))
			"combat": score = b.get("combat_crit", 0.0)
		ranked.append({"race": race_name, "score": score})
	ranked.sort_custom(func(a, b): return a.score > b.score)
	return ranked.map(func(r): return r["race"]) as Array[String]
