class_name ModMechanics
## Turns FrameModData's flat stat_bonus dicts into concrete gameplay hooks:
## how a mod actually feels to move with, and how it actually weighs on a
## hit. Previously a mod's stat_bonus only ever fed the character-sheet
## totals (CharacterCreatorLogic.build_starting_stats) — nothing translated
## "spd +15" into an actual faster sprint, or "pow +18" into actually
## harder hits. This is that translation layer, derived straight from the
## existing stat_bonus numbers (one source of truth — no hand-authored
## second table to drift out of sync when a mod's stats change).
##
## Consumers: ThirdPersonController (mobility), CombatSystemRealtime
## (combat). Both cache the result and refresh on PlayerProfile.profile_updated.

## Stat swing beyond which more of it stops buying more effect — keeps a
## +22 pow berserker chip potent without a runaway mod turning into a
## must-pick outlier.
const SPD_CAP := 20.0
const POW_CAP := 25.0
const RES_CAP := 25.0
const LCK_CAP := 25.0

static func _stat_bonus(mod_id: String) -> Dictionary:
	if mod_id.is_empty():
		return {}
	return FrameModData.get_mod(mod_id).get("stat_bonus", {})

## move_mult/accel_mult/jump_mult: multipliers on the base movement
## constants. A mod that only touches pow/res/lck (shield_matrix aside,
## whose spd penalty is itself the tradeoff) leaves movement untouched.
static func mobility_for(mod_id: String) -> Dictionary:
	var s := _stat_bonus(mod_id)
	var spd := clampf(float(s.get("spd", 0)), -SPD_CAP, SPD_CAP)
	return {
		"move_mult": 1.0 + spd / 100.0,
		"accel_mult": 1.0 + spd / 130.0,
		"jump_mult": 1.0 + spd / 150.0,
	}

## damage_mult: outgoing damage. defense_mult: damage TAKEN (res reduces
## it, so a positive res bonus produces a multiplier below 1.0).
## crit_chance_bonus: added straight onto whatever an ability already rolls.
static func combat_for(mod_id: String) -> Dictionary:
	var s := _stat_bonus(mod_id)
	var pow_bonus := clampf(float(s.get("pow", 0)), -POW_CAP, POW_CAP)
	var res_bonus := clampf(float(s.get("res", 0)), -RES_CAP, RES_CAP)
	var lck_bonus := clampf(float(s.get("lck", 0)), -LCK_CAP, LCK_CAP)
	return {
		"damage_mult": 1.0 + pow_bonus / 100.0,
		"defense_mult": 1.0 - res_bonus / 150.0,
		"crit_chance_bonus": lck_bonus / 100.0 * 0.25,
	}
