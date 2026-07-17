class_name BlueprintData
## The blueprint schema: EVERYTHING equipable, castable, or summonable in
## Periliminal.Space is a blueprint — a bag of named parameters a player can
## reshape in the Blueprint Forge. Weapons, armor, skills, and entities all
## share one format so forking/sharing/trading works uniformly.
##
## A blueprint = { id, kind, name, base_id, params:{}, audio:{}, author,
##                 version, locked:[] }. `params` drive geometry + material,
## `audio` drives the synthesized sound signature (where applicable).
## `locked` lists params the base refuses to expose (balance-critical stats
## are NEVER in blueprints — blueprints are FORM, ItemData/SkillData are
## FUNCTION).

const KINDS := ["weapon", "armor", "skill", "entity"]

## Parameter definitions per kind. Each def:
##   {key, label, type:"float"/"color"/"choice", min, max, def, choices}
## The editor renders these generically; the builders consume them.
const PARAM_DEFS := {
	"weapon": [
		{key="silhouette", label="Silhouette", type="choice", def="blade",
			choices=["blade", "hammer", "staff", "claw", "lash", "orbitals"]},
		{key="length", label="Length", type="float", min=0.4, max=2.2, def=1.0},
		{key="width", label="Width", type="float", min=0.05, max=0.6, def=0.15},
		{key="curve", label="Curve", type="float", min=-0.6, max=0.6, def=0.0},
		{key="taper", label="Taper", type="float", min=0.0, max=1.0, def=0.6},
		{key="segments", label="Segments", type="float", min=1.0, max=8.0, def=1.0},
		{key="base_color", label="Base Color", type="color", def=Color(0.75, 0.78, 0.85)},
		{key="edge_color", label="Edge Glow", type="color", def=Color(0.4, 0.8, 1.0)},
		{key="metallic", label="Metallic", type="float", min=0.0, max=1.0, def=0.9},
		{key="roughness", label="Roughness", type="float", min=0.0, max=1.0, def=0.25},
		{key="emission", label="Emission", type="float", min=0.0, max=4.0, def=0.8},
		{key="trail", label="Swing Trail", type="float", min=0.0, max=1.0, def=0.5},
	],
	"armor": [
		{key="silhouette", label="Silhouette", type="choice", def="plate",
			choices=["plate", "scale", "weave", "shell", "aura", "bone"]},
		{key="coverage", label="Coverage", type="float", min=0.2, max=1.0, def=0.7},
		{key="bulk", label="Bulk", type="float", min=0.0, max=1.0, def=0.4},
		{key="spikes", label="Spikes", type="float", min=0.0, max=1.0, def=0.0},
		{key="base_color", label="Base Color", type="color", def=Color(0.35, 0.37, 0.45)},
		{key="accent_color", label="Accent", type="color", def=Color(0.9, 0.7, 0.3)},
		{key="metallic", label="Metallic", type="float", min=0.0, max=1.0, def=0.7},
		{key="roughness", label="Roughness", type="float", min=0.0, max=1.0, def=0.5},
		{key="emission", label="Rune Glow", type="float", min=0.0, max=3.0, def=0.2},
		{key="wear", label="Battle Wear", type="float", min=0.0, max=1.0, def=0.3},
	],
	"skill": [
		{key="shape_style", label="Cast Shape", type="choice", def="ring",
			choices=["ring", "burst", "spiral", "shards", "wave", "sigil"]},
		{key="primary_color", label="Primary Color", type="color", def=Color(0.5, 0.8, 1.0)},
		{key="secondary_color", label="Secondary", type="color", def=Color(1.0, 1.0, 1.0)},
		{key="particle_density", label="Particle Density", type="float", min=0.2, max=3.0, def=1.0},
		{key="scale", label="Visual Scale", type="float", min=0.5, max=2.0, def=1.0},
		{key="turbulence", label="Turbulence", type="float", min=0.0, max=1.0, def=0.3},
		{key="afterglow", label="Afterglow", type="float", min=0.0, max=2.0, def=0.6},
	],
	"entity": [
		{key="body", label="Body Plan", type="choice", def="quadruped",
			choices=["quadruped", "serpent", "avian", "floating", "biped", "swarm"]},
		{key="size", label="Size", type="float", min=0.4, max=2.5, def=1.0},
		{key="limb_length", label="Limb Length", type="float", min=0.5, max=1.8, def=1.0},
		{key="head_scale", label="Head Scale", type="float", min=0.6, max=1.6, def=1.0},
		{key="base_color", label="Hide Color", type="color", def=Color(0.5, 0.4, 0.35)},
		{key="marking_color", label="Markings", type="color", def=Color(0.2, 0.15, 0.1)},
		{key="glow_color", label="Eye/Core Glow", type="color", def=Color(1.0, 0.8, 0.2)},
		{key="fur", label="Fur/Texture", type="float", min=0.0, max=1.0, def=0.5},
		{key="ethereal", label="Ethereality", type="float", min=0.0, max=1.0, def=0.0},
	],
}

## Audio signature defs — skills, weapons and entities can be HEARD. Armor
## gets footstep timbre only. Synthesized live via BlueprintAudio.
const AUDIO_DEFS := {
	"weapon": [
		{key="waveform", label="Timbre", type="choice", def="metal",
			choices=["metal", "glass", "wood", "void", "chime"]},
		{key="pitch", label="Pitch", type="float", min=0.4, max=2.5, def=1.0},
		{key="ring", label="Ring-out", type="float", min=0.05, max=1.2, def=0.4},
	],
	"armor": [
		{key="waveform", label="Step Timbre", type="choice", def="metal",
			choices=["metal", "leather", "cloth", "chitin", "silence"]},
		{key="pitch", label="Pitch", type="float", min=0.4, max=2.0, def=0.8},
	],
	"skill": [
		{key="waveform", label="Waveform", type="choice", def="sine",
			choices=["sine", "square", "saw", "noise", "choir"]},
		{key="pitch", label="Pitch", type="float", min=0.3, max=3.0, def=1.0},
		{key="attack", label="Attack", type="float", min=0.01, max=0.5, def=0.05},
		{key="decay", label="Decay", type="float", min=0.1, max=2.0, def=0.6},
		{key="wobble", label="Wobble", type="float", min=0.0, max=1.0, def=0.1},
	],
	"entity": [
		{key="waveform", label="Voice", type="choice", def="choir",
			choices=["sine", "square", "saw", "noise", "choir"]},
		{key="pitch", label="Voice Pitch", type="float", min=0.3, max=2.5, def=0.9},
		{key="decay", label="Call Length", type="float", min=0.2, max=2.0, def=0.8},
	],
}

static func defs_for(kind: String) -> Array:
	return PARAM_DEFS.get(kind, [])

static func audio_defs_for(kind: String) -> Array:
	return AUDIO_DEFS.get(kind, [])

## A fresh blueprint of `kind` with every param at its default. `base_id`
## ties it back to the functional item/skill it re-skins.
static func fresh(kind: String, base_id: String, display_name: String) -> Dictionary:
	var params := {}
	for d in defs_for(kind):
		params[d.key] = d.def
	var audio := {}
	for d in audio_defs_for(kind):
		audio[d.key] = d.def
	return {
		"id": "%s_%s_%d" % [kind, base_id, Time.get_ticks_msec()],
		"kind": kind,
		"name": display_name,
		"base_id": base_id,
		"params": params,
		"audio": audio,
		"author": _author_name(),
		"version": 1,
		"locked": [],
		# UGC governance (see docs/UGC_POLICY.md):
		#   private     — usable ONLY inside your own Subliminal
		#   mod_review  — submitted; Discord mod team balance check
		#   dev_review  — mods passed it; dev team canon check
		#   canon       — in-game lore; property of Holloway's Own
		#                 Providential Enterprise Apex Holdings Inc.,
		#                 creator keeps the blueprint + name + sole crafting
		#   rejected    — back to Subliminal-only, resubmit after edits
		"status": "private",
		"allow_forks": false, # NEVER forkable without the creator's opt-in
		"for_sale": false,
		"price": 0,
		"copies_sold": 0,
	}

static func _author_name() -> String:
	var profile := AutoloadGate.get_node("PlayerProfile")
	if profile == null:
		return "unknown"
	return str(profile.get("username")) if str(profile.get("username")) != "" else "unknown"

## Deterministic seed so procedural detail (scratches, rune layout, particle
## phase) is stable per blueprint but unique across them.
static func seed_of(bp: Dictionary) -> int:
	return hash(str(bp.get("id", "")) + str(bp.get("version", 1)))

static func clamp_params(bp: Dictionary) -> Dictionary:
	# Sanitize an imported blueprint: unknown keys dropped, floats clamped,
	# choices validated. Share codes come from other players — trust nothing.
	var kind: String = str(bp.get("kind", ""))
	if kind not in KINDS:
		return {}
	var clean := fresh(kind, str(bp.get("base_id", "custom")), str(bp.get("name", "Imported")))
	clean["author"] = str(bp.get("author", "unknown"))
	# Imports NEVER arrive canon or forkable — status is server-granted, not
	# something a share code can claim. An import is a fresh private design.
	clean["status"] = "private"
	clean["allow_forks"] = false
	var src: Dictionary = bp.get("params", {})
	for d in defs_for(kind):
		if not src.has(d.key):
			continue
		match d.type:
			"float":
				clean.params[d.key] = clampf(float(src[d.key]), d.min, d.max)
			"color":
				var c = src[d.key]
				if c is String:
					clean.params[d.key] = Color.from_string(c, d.def)
				elif c is Color:
					clean.params[d.key] = c
			"choice":
				if str(src[d.key]) in d.choices:
					clean.params[d.key] = str(src[d.key])
	var asrc: Dictionary = bp.get("audio", {})
	for d in audio_defs_for(kind):
		if not asrc.has(d.key):
			continue
		match d.type:
			"float":
				clean.audio[d.key] = clampf(float(asrc[d.key]), d.min, d.max)
			"choice":
				if str(asrc[d.key]) in d.choices:
					clean.audio[d.key] = str(asrc[d.key])
	return clean
