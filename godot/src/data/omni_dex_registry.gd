class_name OmniDexRegistry
## Master OmniDex registry — canonical naming for races, frames, mods,
## entities, and companions.
##
## Identity frames are EXACTLY 20 (Periliminal morphology). A prior typo
## treated shop cosmetics (chrome/neon/storm/wind, …) as frames and
## inflated the count to 24. Cosmetics are excluded here.
##
## Hyperliminal / sensorium frame ids (veil…ossian) remain the gameplay
## keys used by FrameModData + FrameSensorium; OmniDex display names for
## identity come from the Periliminal set below. Use `frame_display_name`
## / `race_display_name` / `mod_display_name` anywhere UI shows a name.

const FRAME_COUNT := 20
const RACE_COUNT := 20
const MOD_COUNT := 20

## Canonical OmniDex identity frames (mirrors Frames.gs / frames.ts).
const FRAMES: Array[Dictionary] = [
	{id="skirmisher", name="Skirmisher", type="light", role="Duelist"},
	{id="strider", name="Strider", type="light", role="Scout"},
	{id="skybound", name="Skybound", type="light", role="Aerialist"},
	{id="flicker", name="Flicker", type="light", role="Blink Duelist"},
	{id="marshal", name="Marshal", type="light", role="Tactician"},
	{id="bloom", name="Bloom", type="light", role="Adaptive Combatant"},
	{id="rewind", name="Rewind", type="light", role="Time Controller"},
	{id="conduit", name="Conduit", type="light", role="Energy Caster"},
	{id="shade", name="Shade", type="light", role="Assassin"},
	{id="fabricator", name="Fabricator", type="light", role="Engineer"},
	{id="bastion", name="Bastion", type="heavy", role="Defender"},
	{id="juggernaut", name="Juggernaut", type="heavy", role="Bruiser"},
	{id="gravemind", name="Gravemind", type="heavy", role="Controller"},
	{id="riftbreaker", name="Riftbreaker", type="heavy", role="Disruptor"},
	{id="sovereign", name="Sovereign", type="heavy", role="Territory Holder"},
	{id="worldroot", name="Worldroot", type="heavy", role="Terraformer"},
	{id="epoch", name="Epoch", type="heavy", role="Time Warden"},
	{id="overlord", name="Overlord", type="heavy", role="Detonator"},
	{id="obscura", name="Obscura", type="heavy", role="Veilkeeper"},
	{id="architect", name="Architect", type="heavy", role="Fortifier"},
]

## Hyperliminal sensorium frame ids (FrameModData / FrameSensorium).
## Exactly 20 — never merge with cosmetics.
const SENSORIUM_FRAME_IDS: Array[String] = [
	"veil", "zephyr", "viper", "phantom", "crimson",
	"glacial", "bolt", "soul", "cinder", "flux",
	"bastion", "tremor", "behemoth", "bulwark", "ignis",
	"glaci", "surge", "siege", "blight", "ossian",
]

## Shop / profile cosmetics — NOT OmniDex identity frames.
const COSMETIC_FRAME_IDS: Array[String] = [
	"chrome_frame", "neon_frame", "gold_frame", "shadow_frame", "battle_frame",
	"storm", "wind", "basic", "ghost", "titan", "royal", "iron", "void",
	"ember", "atlas", "silk", "nova", "frost", "blaze", "rock", "prism", "mirage",
]

static func assert_invariants() -> void:
	assert(FRAMES.size() == FRAME_COUNT, "OmniDex frames must be exactly 20 (not 24)")
	assert(SENSORIUM_FRAME_IDS.size() == FRAME_COUNT, "Sensorium frames must be exactly 20")
	assert(MorphRigData.RIGS.size() == MOD_COUNT, "OmniDex mods must be exactly 20")
	assert(RaceDataCharacter.RACES.size() == RACE_COUNT, "Playable races must be exactly 20")
	assert(CanonRaces.RACES.size() == RACE_COUNT, "Canon race names must be exactly 20")

static func is_identity_frame(frame_id: String) -> bool:
	for f in FRAMES:
		if f.id == frame_id:
			return true
	return frame_id in SENSORIUM_FRAME_IDS

static func is_cosmetic_frame(frame_id: String) -> bool:
	return frame_id in COSMETIC_FRAME_IDS

static func frame_by_id(frame_id: String) -> Dictionary:
	for f in FRAMES:
		if f.id == frame_id:
			return f.duplicate()
	# Fall back to sensorium / FrameModData for Hyperliminal ids.
	var sensorium := FrameModData.get_frame(frame_id)
	if not sensorium.is_empty():
		return {
			"id": sensorium.id,
			"name": str(sensorium.name).replace(" Frame", ""),
			"type": sensorium.get("type", ""),
			"role": sensorium.get("desc", ""),
		}
	return {}

static func frame_display_name(frame_id: String) -> String:
	var f := frame_by_id(frame_id)
	if f.is_empty():
		return frame_id
	return str(f.get("name", frame_id))

static func race_display_name(race_id: String) -> String:
	## Prefer canon Periliminal name; fall back to casino breed label.
	var canon := CanonRaces.canon_for_id(race_id)
	if canon != "":
		return canon
	var r := RaceDataCharacter.get_race(race_id)
	return str(r.get("name", race_id)) if not r.is_empty() else race_id

static func mod_display_name(mod_id: String) -> String:
	var rig := MorphRigData.by_id(mod_id)
	if not rig.is_empty():
		return str(rig.get("name", mod_id))
	var legacy := FrameModData.get_mod(mod_id)
	if not legacy.is_empty():
		return str(legacy.get("name", mod_id))
	return mod_id

static func entity_display_name(entity_id: String) -> String:
	## EntityDex line ids (SC-EN1) or companion-style ids.
	for line in EntityDexData.LINES:
		if line.get("id", "") == entity_id:
			var apex: Dictionary = EntityDexData.stage_for(line, 3)
			if apex.is_empty():
				apex = EntityDexData.stage_for(line, 1)
			return str(apex.get("name", entity_id))
	for line in EntityDexData.FACTIONLESS_LINES:
		if line.get("id", "") == entity_id:
			var apex2: Dictionary = EntityDexData.stage_for(line, 3)
			if apex2.is_empty():
				apex2 = EntityDexData.stage_for(line, 1)
			return str(apex2.get("name", entity_id))
	var companion := CompanionRegistry.get_by_id(entity_id)
	if not companion.is_empty():
		return str(companion.get("name", entity_id))
	return entity_id

static func companion_display_name(companion_id: String) -> String:
	var c := CompanionRegistry.get_by_id(companion_id)
	return str(c.get("name", companion_id)) if not c.is_empty() else companion_id

static func all_frame_names() -> Array[String]:
	var out: Array[String] = []
	for f in FRAMES:
		out.append(str(f.name))
	return out

static func all_race_names() -> Array[String]:
	var out: Array[String] = []
	for n in CanonRaces.RACES:
		out.append(str(n))
	return out

static func all_mod_names() -> Array[String]:
	var out: Array[String] = []
	for r in MorphRigData.RIGS:
		out.append(str(r.name))
	return out
