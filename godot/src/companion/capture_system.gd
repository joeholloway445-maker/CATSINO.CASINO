extends Node
## Autoloaded as "CaptureSystem". The rule Joe set: you don't catch
## entities by tossing a ball at a wild one — you catch them by
## DEFEATING them. Solo, or with Hope's help. The harder the fight, the
## more special the bond, and rare stages stay rare instead of flooding
## the world.
##
## The catch is NOT automatic. When a player-triggered defeat happens,
## roll a chance that scales with:
##   - How much of your own HP you brought to the end of the fight
##     (a clean win reads as "you earned this one").
##   - Hope's bond (a more-Kindled Hope helps you land the moment).
##   - Rarity/stage of the entity (higher = harder = rarer catch).
##   - Personal difficulty (Hope profile + word of mouth) via Periliminal.
## The player is told, either way — the whole point is that the moment
## feels like a moment, not a silent inventory increment.

signal entity_captured(entity_id: String, name: String, stage: int)
signal entity_lost(entity_id: String, name: String, stage: int)

## Call at the exact instant a WorldEntity dies to a player-driven cause.
## `player_hp_ratio` in [0..1] describes how healthy the player finished.
func on_defeated(entity: WorldEntity, player_hp_ratio: float) -> void:
	if entity == null or entity.line.is_empty():
		return
	var entity_id := str(entity.line.get("id", ""))
	if entity_id == "":
		return
	var stage_name := str(entity.stage_info.get("name", "the entity"))
	var stage_num := int(entity.stage_num)

	# Category → base chance. Some kinds are more bond-inclined than others.
	var cat := str(entity.line.get("category", "Matter"))
	var base := {
		"Matter": 0.55, "Gravity": 0.50, "Energy": 0.45,
		"Entropy": 0.35, "Psyche": 0.30, "Quantum": 0.25,
	}.get(cat, 0.4)

	# Bigger fights are rarer catches. Stage 3 caps around 15% before help.
	var stage_penalty := 0.15 * (stage_num - 1)
	var health_bonus := clampf(player_hp_ratio, 0.0, 1.0) * 0.20
	var hope_bonus := clampf(float(Hope.bond) / 3000.0, 0.0, 0.25)
	# Periliminal difficulty reads WHO you've been — a cruel or reckless
	# player has to work harder to earn a bond, too.
	var diff_penalty := 0.0
	if LayerManager.current_layer_id == "periliminal":
		diff_penalty = clampf((PeriliminalRuns.difficulty() - 1.0) * 0.12, 0.0, 0.24)

	var chance := clampf(base - stage_penalty + health_bonus + hope_bonus - diff_penalty, 0.05, 0.85)
	if randf() < chance:
		CompanionSystem.unlock_companion(entity_id)
		EconomyManager.earn_currency("charges", 1 + stage_num, "entity_bonded")
		NotificationUI.notify_win("✧ %s (Stage %d) bonds to you. It followed you home." % [stage_name, stage_num])
		entity_captured.emit(entity_id, stage_name, stage_num)
		Hope.record("entity_bonded", {"id": entity_id, "stage": stage_num, "chance": chance})
	else:
		NotificationUI.notify_info("The %s falls — but the bond didn't take. It's gone." % stage_name)
		entity_lost.emit(entity_id, stage_name, stage_num)
		Hope.record("entity_defeated_no_bond", {"id": entity_id, "stage": stage_num})
