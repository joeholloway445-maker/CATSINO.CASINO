class_name HumanIdentity
## Composes a HumanDNA genome from the player's actual game identity —
## race, frame, and mod, the same three choices the character creator
## already collects — instead of (or as a starting point for) the
## Character Studio's freeform sculpting. This is what a citizen looks
## like before anyone opens the Studio: race sets species-level body and
## material traits from lore (HumanRaceArchetypes), frame reshapes build
## along the light/heavy sensorium-frame axis (HumanFrameArchetypes), and
## mod layers small augment tweaks and accent glows on top
## (HumanModArchetypes). Layering order is race -> frame -> mod, so a mod's
## accent always reads on top of the race's material and the frame's build.
##
## race_id is a RaceDataCharacter cat-breed id ("tabby", "savannah", ...);
## it's translated to its canon species (CanonRaces) before archetype
## lookup. frame_id / mod_id are FrameModData ids ("veil", "overclock",
## ...) and may be empty.

static func build(race_id: String, frame_id: String = "", mod_id: String = "", seed_value: int = 0) -> HumanDNA:
	var dna := HumanDNA.random(seed_value)
	if not race_id.is_empty():
		_apply_race(dna, CanonRaces.canon_for_id(race_id), seed_value)
	if not frame_id.is_empty():
		_apply_layer(dna, HumanFrameArchetypes.get_archetype(frame_id))
	if not mod_id.is_empty():
		_apply_layer(dna, HumanModArchetypes.get_archetype(mod_id))
	dna.display_name = _display_name(race_id, frame_id)
	return dna

static func _display_name(race_id: String, frame_id: String) -> String:
	var race := RaceDataCharacter.get_race(race_id)
	var parts := []
	if not race.is_empty():
		parts.append(str(race.get("name", race_id)))
	if not frame_id.is_empty():
		var frame := FrameModData.get_frame(frame_id)
		if not frame.is_empty():
			parts.append(str(frame.get("name", frame_id)))
	return " ".join(parts) if not parts.is_empty() else "New Human"

static func _apply_race(dna: HumanDNA, canon_name: String, seed_value: int) -> void:
	var arch := HumanRaceArchetypes.get_archetype(canon_name)
	if arch.is_empty():
		return
	if arch.get("chaotic", false):
		_apply_chaos(dna, seed_value)
		return
	_apply_layer(dna, arch)

## Chimera: "no two Chimera are alike" — instead of a fixed body, jitter a
## wide spread of genes and pick from a deliberately unusual palette, both
## seeded so the same individual is stable across sessions.
static func _apply_chaos(dna: HumanDNA, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x43484D52  # 'CHMR'
	for gene_id in ["build", "muscle", "head_width", "eye_size", "eye_spacing", "nose_width",
			"jaw_width", "cheekbone_width", "chin_protrusion", "ear_size"]:
		dna.set_gene(gene_id, rng.randf())
	var eyes: Array = HumanRaceArchetypes.CHIMERA_EYE_PALETTE
	var hairs: Array = HumanRaceArchetypes.CHIMERA_HAIR_PALETTE
	dna.eye_color = Color.from_string(str(eyes[rng.randi() % eyes.size()]), dna.eye_color)
	dna.hair_color = Color.from_string(str(hairs[rng.randi() % hairs.size()]), dna.hair_color)

## Applies one archetype layer's genes/colors/material on top of whatever
## the previous layers already set. Later layers override colors/material
## keys outright but only ever nudge (add to) genes.
static func _apply_layer(dna: HumanDNA, arch: Dictionary) -> void:
	if arch.is_empty():
		return
	var gene_deltas: Dictionary = arch.get("genes", {})
	for gene_id in gene_deltas:
		dna.nudge_gene(str(gene_id), float(gene_deltas[gene_id]))
	if arch.has("eye_color"):
		dna.eye_color = Color.from_string(str(arch.eye_color), dna.eye_color)
	if arch.has("hair_color"):
		dna.hair_color = Color.from_string(str(arch.hair_color), dna.hair_color)
	if arch.has("hair_style"):
		dna.hair_style = str(arch.hair_style)
	if arch.has("skin_tint"):
		var t := Color.from_string(str(arch.skin_tint), Color.WHITE)
		dna.skin_tint = Color(t.r, t.g, t.b, 1.0)
	if arch.has("marking_color"):
		var m := Color.from_string(str(arch.marking_color), Color.WHITE)
		dna.marking_color = Color(m.r, m.g, m.b, 1.0)
	var sm: Dictionary = arch.get("skin_material", {})
	for key in sm:
		dna.skin_material[key] = sm[key]
	dna.emissive_boost += float(arch.get("emissive_boost", 0.0))
