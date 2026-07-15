extends Node
## Autoloaded as "IdentityLens". The system that guarantees no two players
## ever see or hear the same game:
##
##  - Your RACE is the material of reality: every hard mesh — terrain,
##    props, NPCs, entities, other players — renders through your race's
##    texture lens (texture_type + primary_color via TextureMaterials),
##    folded with the RPS perception model (PerceptionSystem) for how
##    OTHER beings read through it.
##  - Your FRAME is your senses: it decides the light your client renders
##    and the soundscape it plays (FrameSensorium). At Champion ascension
##    you take a SECOND frame and the two blend.
##  - Race x frame x mod = 8,000 builds at creation. Ascension frame x20 =
##    160,000. Faction x3 = 480,000. Quest-reward titles keep multiplying
##    from there. The build signature seeds all of it deterministically.

signal lens_changed()

const TextureMaterials = preload("res://src/character/texture_materials.gd")

const BASE_BUILDS := 20 * 20 * 20      # race x frame x mod = 8,000
const ASCENSION_MULT := 20             # second frame
const FACTION_MULT := 3                # the three factions

func _ready() -> void:
	PlayerProfile.profile_updated.connect(func(): lens_changed.emit())

# ── Build signature & rarity ──────────────────────────────────────────────────
func signature() -> Dictionary:
	return {
		"race": PlayerProfile.selected_race_id,
		"frame": PlayerProfile.selected_frame,
		"ascended_frame": PlayerProfile.ascended_frame,
		"mod": PlayerProfile.selected_mod,
		"faction": PlayerProfile.faction,
		"titles": PlayerProfile.titles.duplicate(),
	}

## Deterministic per-build seed — the same build always bends the world the
## same way; any change to it re-tunes everything.
func identity_seed() -> int:
	var sig := signature()
	return hash("%s|%s|%s|%s|%s|%s" % [
		sig.race, sig.frame, sig.ascended_frame, sig.mod, sig.faction, "|".join(sig.titles)])

## "You are 1 in N": 8,000 at creation; x20 once ascended; x3 once
## factioned; every earned title doubles it (quest-reward titles are the
## late-game multiplier).
func rarity_denominator() -> int:
	var n := BASE_BUILDS
	if PlayerProfile.ascended_frame != "":
		n *= ASCENSION_MULT
	if PlayerProfile.faction != "Factionless":
		n *= FACTION_MULT
	for _t in PlayerProfile.titles:
		n *= 2
	return n

func rarity_text() -> String:
	return "You are 1 in %s." % _grouped(rarity_denominator())

func _grouped(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

# ── The race lens: what reality is made of ────────────────────────────────────
## Route ANY hard-mesh material through this. base_color is the mesh's own
## color (biome, NPC palette, entity tint); the player's race decides the
## surface physics (roughness/metalness/emission via texture_type) and pulls
## the hue toward their primary_color. Strength: how far reality bends.
func world_material(base_color: Color, strength: float = 0.35) -> StandardMaterial3D:
	var race := RaceDataCharacter.get_race(PlayerProfile.selected_race_id)
	var lens_color: Color = race.get("primary_color", Color.WHITE)
	var mat := TextureMaterials.build_material(
		race.get("texture_type", "morphic"), base_color.lerp(lens_color, strength))
	return mat

## How SOMEONE ELSE's mesh renders on YOUR client: their base look, pulled
## through your race lens, scaled/aura'd by the RPS perception model, and
## finished with your view-scale style (glitchy/holographic/shadowy/off —
## see ViewScale; PerceptionSystem.perceive already resolved which style
## actually applies, honoring their opt-out over yours if they have one).
func perceive_being(their_profile: Dictionary, their_color: Color) -> Dictionary:
	var view := PerceptionSystem.perceive(PerceptionSystem.local_profile(), their_profile)
	var mat := world_material(their_color, 0.25)
	if view.aura_intensity > 0.0:
		mat.emission_enabled = true
		mat.emission = view.aura_color
		mat.emission_energy_multiplier = view.aura_intensity
	match str(view.get("style", "")):
		"holographic":
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.82
			mat.emission_enabled = true
			if view.aura_intensity <= 0.0:
				mat.emission = Color(0.5, 0.95, 1.0)
			mat.emission_energy_multiplier = maxf(mat.emission_energy_multiplier, 0.35)
		"shadowy":
			mat.albedo_color = mat.albedo_color.darkened(0.55)
			mat.roughness = 1.0
			mat.metallic = 0.0
			mat.emission_enabled = false
	return {"material": mat, "scale": view.apparent_scale, "view": view}

# ── The frame sensorium: how reality is lit and sounds ────────────────────────
func sensorium() -> Dictionary:
	return FrameSensorium.blend(PlayerProfile.selected_frame, PlayerProfile.ascended_frame)

## Apply the frame's light signature to a DayNightSky (call after creating
## one). The frame tint multiplies the sky's palette; fog/energy follow.
func tune_sky(sky: DayNightSky) -> void:
	var s := sensorium()
	sky.frame_tint = s.light
	sky.frame_energy_mult = s.energy

## Sound contract for the audio layer: mode/tempo/timbre drive ambient
## generation, and the identity seed picks the exact voicing — two players
## with the same frame still get different phrasings.
func sound_profile() -> Dictionary:
	var s := sensorium()
	return {
		"mode": s.mode, "tempo": s.tempo, "timbre": s.timbre,
		"voicing_seed": identity_seed(),
		"desc": s.desc,
	}
