class_name PerceptionSystem
## Asymmetric perception: how a viewer sees a target is computed per-pair —
## you and I can look at the same player and see something different. Three
## inputs shape the render: relative strength, type (faction) advantage, and
## alignment. The result feeds CharacterRig/materials as scale, aura color
## and emission — this is a data contract, not a renderer.
##
## Design intent: a player much stronger than you LOOMS (scaled up, heavy
## aura); one you counter looks diminished; alignment tints the aura so a
## "friendly" silhouette reads warm even when it's dangerous.

## Faction wheel: each entry's `beats` is the faction it has advantage over.
const TYPE_WHEEL := {
	"SovereignCrown":     {beats="WildlandsAscendant"},
	"WildlandsAscendant": {beats="VeiledCurrent"},
	"VeiledCurrent":      {beats="SovereignCrown"},
	"Factionless":        {beats=""},
}

const ALIGNMENT_AURAS := {
	"radiant":  Color(1.0, 0.9, 0.5),
	"neutral":  Color(0.7, 0.7, 0.8),
	"umbral":   Color(0.5, 0.2, 0.7),
	"feral":    Color(0.9, 0.3, 0.2),
}

## total stat weight of a loadout (race + frame + mod bonuses + level).
static func strength_of(profile: Dictionary) -> float:
	var stats: Dictionary = profile.get("stats", {})
	var total := 0.0
	for v in stats.values():
		total += float(v)
	return total + float(profile.get("level", 1)) * 5.0

static func type_advantage(viewer_faction: String, target_faction: String) -> float:
	if TYPE_WHEEL.get(viewer_faction, {}).get("beats", "") == target_faction:
		return 1.0   # viewer counters target → target looks diminished
	if TYPE_WHEEL.get(target_faction, {}).get("beats", "") == viewer_faction:
		return -1.0  # target counters viewer → target looms
	return 0.0

## The contract: returns how `target` should be RENDERED ON `viewer`'s
## client. Symmetric calls give different answers by design.
static func perceive(viewer: Dictionary, target: Dictionary) -> Dictionary:
	var vs := strength_of(viewer)
	var ts := strength_of(target)
	var ratio := ts / maxf(vs, 1.0)
	var advantage := type_advantage(
		str(viewer.get("faction", "Factionless")), str(target.get("faction", "Factionless")))

	# Scale: 0.85 (you counter them, weaker) up to 1.35 (they loom).
	var apparent_scale := clampf(0.85 + (ratio - 1.0) * 0.25 - advantage * 0.08, 0.7, 1.5)
	# Aura strength: relative threat, boosted when they have type advantage.
	var menace := clampf((ratio - 0.8) * 0.6 + maxf(-advantage, 0.0) * 0.4, 0.0, 1.0)
	var aura: Color = ALIGNMENT_AURAS.get(str(target.get("alignment", "neutral")), ALIGNMENT_AURAS["neutral"])

	return {
		"apparent_scale": apparent_scale,
		"aura_color": aura,
		"aura_intensity": menace,
		"outline": "threat" if menace > 0.66 else ("rival" if advantage < 0.0 else "even"),
		# Detail hides with distance in power: much weaker viewers can't
		# read a strong player's exact loadout, only the silhouette.
		"loadout_visible": ratio < 1.5,
	}

## Convenience for the local player's profile dict.
static func local_profile() -> Dictionary:
	return {
		"level": PlayerProfile.level,
		"faction": PlayerProfile.faction,
		"alignment": "neutral",
		"stats": CharacterCreatorLogic.build_starting_stats(
			PlayerProfile.selected_race_id, PlayerProfile.faction,
			PlayerProfile.selected_frame, PlayerProfile.selected_mod),
	}
