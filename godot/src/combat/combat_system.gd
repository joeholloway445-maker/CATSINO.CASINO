extends Node

# ── Signals ────────────────────────────────────────────────────────────────────
signal combat_started(attacker_id: String, defender_id: String)
signal combat_resolved(result: CombatResult)
signal burst_triggered(character_name: String, bonus_damage: int)

# ── Inner Classes ──────────────────────────────────────────────────────────────
class CombatResult:
	var attacker_name:  String
	var defender_name:  String
	var damage:         int
	var outcome:        String   # "win", "lose", "draw"
	var burst_triggered: bool
	var burst_damage:   int
	var frame_clash:    String   # e.g. "Light > Heavy"
	var log:            Array[String]

	func _init() -> void:
		log = []

	func to_dict() -> Dictionary:
		return {
			"attacker":        attacker_name,
			"defender":        defender_name,
			"damage":          damage,
			"outcome":         outcome,
			"burst_triggered": burst_triggered,
			"burst_damage":    burst_damage,
			"frame_clash":     frame_clash,
			"log":             log,
		}

# ── Constants ──────────────────────────────────────────────────────────────────
# RPS: Light > Heavy > Tech(Glitch) > Light
# We map FrameClass to combat type; Mods that are "tech" shift resolution
const TECH_MODS := [
	CharacterData.Mod.VOID_CORE, CharacterData.Mod.NULL,
	CharacterData.Mod.ENTROPY, CharacterData.Mod.PHASE,
	CharacterData.Mod.SINGULARITY,
]
const BURST_LCK_THRESHOLD   := 80
const BURST_SYNERGY_THRESHOLD := 0.20
const BASE_DAMAGE_SCALE      := 12.0

# ── Public API ─────────────────────────────────────────────────────────────────
func resolve_encounter(attacker: CharacterData, defender: CharacterData) -> CombatResult:
	var result := CombatResult.new()
	result.attacker_name = attacker.character_name
	result.defender_name = defender.character_name

	emit_signal("combat_started", attacker.character_name, defender.character_name)

	var atk_stats := attacker.compute_total_stats()
	var def_stats := defender.compute_total_stats()

	# ── Frame clash (RPS) ─────────────────────────────────────────────────────
	var atk_type := _combat_type(attacker)
	var def_type := _combat_type(defender)
	var clash_mult := _rps_multiplier(atk_type, def_type)
	result.frame_clash = "%s vs %s (x%.2f)" % [atk_type, def_type, clash_mult]
	result.log.append("Frame clash: %s" % result.frame_clash)

	# ── Base damage formula ───────────────────────────────────────────────────
	# Damage = (Pow * clash_mult) - (Res * 0.5) + (Spd * 0.2 * speed_advantage)
	var speed_adv := 1.0 + clampf((atk_stats["spd"] - def_stats["spd"]) / 100.0, -0.5, 0.5)
	var raw_damage: float = (float(atk_stats["pow"]) * clash_mult * BASE_DAMAGE_SCALE) \
	               - (float(def_stats["res"]) * 0.5 * BASE_DAMAGE_SCALE) \
	               + (float(atk_stats["spd"]) * 0.2 * speed_adv * BASE_DAMAGE_SCALE)
	raw_damage = maxf(raw_damage, 1.0)

	# Synergy multiplier
	raw_damage *= (1.0 + attacker.compute_synergy_bonus() * 0.5)
	result.log.append("Raw damage before burst: %.1f" % raw_damage)

	# ── Burst / Sleeper mechanic ──────────────────────────────────────────────
	result.burst_triggered = false
	result.burst_damage    = 0
	if atk_stats["lck"] > BURST_LCK_THRESHOLD and \
	   attacker.compute_synergy_bonus() > BURST_SYNERGY_THRESHOLD:
		var burst_chance := clampf(
			(atk_stats["lck"] - BURST_LCK_THRESHOLD) / 100.0 + attacker.compute_synergy_bonus(),
			0.0, 0.75
		)
		if randf() < burst_chance:
			result.burst_triggered = true
			result.burst_damage    = int(raw_damage * 0.5)
			raw_damage            += result.burst_damage
			result.log.append("BURST TRIGGERED! +%d damage" % result.burst_damage)
			emit_signal("burst_triggered", attacker.character_name, result.burst_damage)

	result.damage = int(raw_damage)

	# ── Outcome ───────────────────────────────────────────────────────────────
	var defender_hp: int = int(def_stats["res"]) * 10
	if result.damage >= defender_hp:
		result.outcome = "win"
	elif result.damage <= 0:
		result.outcome = "lose"
	else:
		# Close call — compare damage to defender max HP
		var pct := float(result.damage) / float(defender_hp)
		result.outcome = "win" if pct > 0.5 else "lose"
	result.log.append("Outcome: %s (damage %d vs HP %d)" % [result.outcome, result.damage, defender_hp])

	emit_signal("combat_resolved", result)
	return result

# ── Private ────────────────────────────────────────────────────────────────────
func _combat_type(character: CharacterData) -> String:
	if character.mod in TECH_MODS:
		return "Tech"
	return "Light" if character.get_frame_class() == CharacterData.FrameClass.LIGHT else "Heavy"

func _rps_multiplier(atk_type: String, def_type: String) -> float:
	# Light > Heavy > Tech > Light
	const WIN_MULT  := 1.35
	const LOSE_MULT := 0.70
	const DRAW_MULT := 1.00
	if   atk_type == "Light"  and def_type == "Heavy": return WIN_MULT
	elif atk_type == "Heavy"  and def_type == "Tech":  return WIN_MULT
	elif atk_type == "Tech"   and def_type == "Light": return WIN_MULT
	elif atk_type == "Heavy"  and def_type == "Light": return LOSE_MULT
	elif atk_type == "Tech"   and def_type == "Heavy": return LOSE_MULT
	elif atk_type == "Light"  and def_type == "Tech":  return LOSE_MULT
	else: return DRAW_MULT
