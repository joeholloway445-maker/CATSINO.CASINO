class_name PerceptionEngine
## The Perception Engine — the formal algorithm behind the lens.
##
## Every entity renders somewhere on the holographic↔distorted axis with a
## CONFIDENCE value 0-100%:
##   100% = solid, true-form, fully readable (high psychology + prestige)
##     0% = pure distortion: static, wrong geometry, unreadable
##
## Inputs:
##   psychology_score  0..100  — from choices, door exploration, gambling
##                               under pressure (Hope's profile compiles it)
##   prestige_level    int     — EconomyManager.influence_level()
##   entity_confidence 0..100  — how "real" the entity itself is (anomalies
##                               have low base confidence; hub NPCs high)
##   group             Array   — prestige levels of present party members;
##                               the HIGHEST prestige dominates the group's
##                               shared perception (everyone sees closer to
##                               what the strongest walker sees).
##
## Output: {confidence: float 0-100, distortion: float 0-1, mode: String}
## mode ∈ solid | holographic | flickering | distorted
##
## Pseudocode:
##   base   = entity_confidence
##   psych  = psychology_score * 0.4          # what you've faced, you see
##   pres   = clamp(prestige_level * 2, 0,30) # rank steadies the image
##   group  = max(own_prestige, max(party)) → use dominant for `pres`
##   conf   = clamp(base*0.4 + psych + pres, 0, 100)
##   distortion = 1.0 - conf/100

static func psychology_score() -> float:
	# Compiled from Hope's live profile: courage (inverse fear/anxiety),
	# curiosity, and composure under gambling pressure.
	var p: Dictionary = Hope.profile
	var courage := 1.0 - (float(p.get("fear", 0.0)) + float(p.get("anxiety", 0.0))) * 0.5
	var curiosity := float(p.get("curiosity", 0.5))
	var composure := 1.0 - absf(float(p.get("greed", 0.5)) - 0.5) * 2.0 # extremes read as pressure cracks
	return clampf((courage * 0.5 + curiosity * 0.3 + composure * 0.2) * 100.0, 0.0, 100.0)

static func perceive_entity(entity_confidence: float, group_prestiges: Array = []) -> Dictionary:
	var pres := EconomyManager.influence_level()
	for g in group_prestiges:
		pres = maxi(pres, int(g)) # highest prestige dominates the group
	var conf := clampf(
		entity_confidence * 0.4 + psychology_score() * 0.4 + clampf(pres * 2.0, 0.0, 30.0),
		0.0, 100.0)
	var distortion := 1.0 - conf / 100.0
	var mode := "solid"
	if conf < 25.0: mode = "distorted"
	elif conf < 50.0: mode = "flickering"
	elif conf < 80.0: mode = "holographic"
	return {"confidence": conf, "distortion": distortion, "mode": mode}

## Apply a perception result to a material: holographic = translucent
## emissive; distorted = scrambled hue + noise-heavy roughness.
static func apply_to_material(mat: StandardMaterial3D, view: Dictionary) -> StandardMaterial3D:
	var d: float = view.distortion
	match view.mode:
		"solid":
			pass
		"holographic":
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = lerpf(0.9, 0.55, d)
			mat.emission_enabled = true
			mat.emission = mat.albedo_color.lightened(0.3)
			mat.emission_energy_multiplier = 0.8
		"flickering":
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.5
			mat.emission_enabled = true
			mat.emission = Color(0.5, 0.8, 1.0)
			mat.emission_energy_multiplier = 1.2
		"distorted":
			# Wrong on purpose: hue-shifted, rough, half-there.
			mat.albedo_color = Color.from_hsv(randf(), 0.9, 0.6, 0.4)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.roughness = 1.0
			mat.emission_enabled = true
			mat.emission = Color(0.8, 0.1, 0.4)
			mat.emission_energy_multiplier = d * 2.0
	return mat

## Procedural seed derivation, per spec: hash(player_race, prestige, x,y,z).
## First discoverer's identity bakes into the chunk forever (DiscoveryManager
## already paints dominant textures from the influence pack; this seed keys
## the geometry/feature roll).
static func generation_seed(race_id: String, prestige: int, x: int, y: int, z: int) -> int:
	return hash("%s|%d|%d|%d|%d" % [race_id, prestige, x, y, z])
