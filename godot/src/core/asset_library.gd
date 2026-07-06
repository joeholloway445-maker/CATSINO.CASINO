class_name AssetLibrary
## The asset upgrade pipeline. Every procedural mesh in the game asks this
## library first: if a real model exists at the documented path, it's used;
## otherwise the procedural fallback builds. This means dropping CC0/paid
## asset packs into assets/models/ upgrades the ENTIRE game's look with
## zero code changes — see docs/SHIPPING.md for the exact packs and the
## file names each slot expects.
##
## Slot -> expected file (first that exists wins):
##   player_cat        assets/models/player_cat.glb
##   npc_cat           assets/models/npc_cat.glb
##   creature          assets/models/creature.glb
##   tree              assets/models/tree.glb
##   crystal           assets/models/crystal.glb
##   ruin_pillar       assets/models/ruin_pillar.glb
##   rock              assets/models/rock.glb
##   extraction_gate   assets/models/extraction_gate.glb
##   harvest_node      assets/models/harvest_node.glb
##   apartment_prop    assets/models/apartment_prop.glb
##
## Mega-city model slots (MegaCityBuilder / BuildingBuilder ask these):
##   city_tower        a downtown skyscraper shell
##   city_lowrise      a mid/low commercial building
##   city_house        a residential structure
##   city_industrial   a warehouse / plant
##   road_segment      a paved road tile
##   sidewalk          a curb/sidewalk tile
##   streetlight       a lamp post (its OmniLight3D is added by us)
##   neon_sign         a signage board (its emissive is driven by us)
##   city_prop         benches/planters/hydrants/bins
##
## Texture slots (for interchangeable PBR on procedural hard mesh — used by
## `material()` below, alongside the per-race IdentityLens tint):
##   assets/textures/<slot>_albedo.png / _normal.png / _rough.png
##   e.g. facade_glass, facade_concrete, asphalt, sidewalk, neon
##
## Sound slots (dependency-injected ambience/one-shots; synth fallback if
## absent) via `sound()`:
##   assets/audio/<slot>.ogg / .wav / .mp3
##   e.g. city_traffic, city_crowd, neon_hum, machine_hum, footstep_concrete
##
## Also checks assets/models/<slot>.gltf and .tscn variants.

const SEARCH_EXTENSIONS := ["glb", "gltf", "tscn"]
const AUDIO_EXTENSIONS := ["ogg", "wav", "mp3"]
const TEXTURE_EXTENSIONS := ["png", "jpg", "webp"]

static var _cache: Dictionary = {}
static var _audio_cache: Dictionary = {}
static var _texture_cache: Dictionary = {}

## Returns an instantiated Node3D for the slot, or null if no real asset
## is installed (caller then builds its procedural fallback).
static func instance(slot: String) -> Node3D:
	if _cache.has(slot):
		var packed: PackedScene = _cache[slot]
		return packed.instantiate() if packed != null else null
	for ext in SEARCH_EXTENSIONS:
		var path := "res://assets/models/%s.%s" % [slot, ext]
		if ResourceLoader.exists(path):
			var res := load(path)
			if res is PackedScene:
				_cache[slot] = res
				return res.instantiate()
	_cache[slot] = null
	return null

## True if a real (non-procedural) asset is installed for the slot.
static func has(slot: String) -> bool:
	return instance(slot) != null

## Convenience: try the slot; if absent, call `fallback` (a Callable that
## returns Node3D). Applies the identity lens material to real assets'
## mesh surfaces too, so imported models still obey the race lens.
static func instance_or(slot: String, fallback: Callable, lens_color: Color = Color.WHITE, lens_strength: float = 0.2) -> Node3D:
	var node := instance(slot)
	if node == null:
		return fallback.call()
	if lens_strength > 0.0:
		_apply_lens(node, lens_color, lens_strength)
	return node

static func _apply_lens(node: Node, color: Color, strength: float) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mat := IdentityLens.world_material(color, strength)
		# Keep the imported albedo texture; only pull physics/hue.
		var existing := mi.get_active_material(0)
		if existing is StandardMaterial3D and existing.albedo_texture:
			mat.albedo_texture = existing.albedo_texture
		mi.material_override = mat
	for child in node.get_children():
		_apply_lens(child, color, strength)

# ---------------------------------------------------------------- sounds

## Returns the AudioStream installed for a sound slot, or null if none is
## present (caller then synthesizes or stays silent). Looped ambience beds
## should ship as .ogg with loop enabled in their import; we also force the
## loop flag on for .ogg/.wav we load here so drop-in packs "just work".
static func sound(slot: String) -> AudioStream:
	if _audio_cache.has(slot):
		return _audio_cache[slot]
	for ext in AUDIO_EXTENSIONS:
		var path := "res://assets/audio/%s.%s" % [slot, ext]
		if ResourceLoader.exists(path):
			var res := load(path)
			if res is AudioStream:
				if res is AudioStreamOggVorbis:
					res.loop = true
				elif res is AudioStreamWAV:
					res.loop_mode = AudioStreamWAV.LOOP_FORWARD
				_audio_cache[slot] = res
				return res
	_audio_cache[slot] = null
	return null

static func has_sound(slot: String) -> bool:
	return sound(slot) != null

# ---------------------------------------------------------------- textures

## Builds a PBR material for a procedural hard-mesh part. If a texture pack
## is installed for `slot` (assets/textures/<slot>_albedo.png etc.), those
## maps are used; either way the per-race IdentityLens tint/physics is
## folded in, so the SAME wall is a different material on every player's
## client. This is the "interchangeable textures on all hard mesh" contract.
static func material(slot: String, base_color: Color, lens_strength: float = 0.25,
		metallic: float = 0.0, roughness: float = 0.8) -> StandardMaterial3D:
	var mat := IdentityLens.world_material(base_color, lens_strength) if IdentityLens else StandardMaterial3D.new()
	mat.metallic = metallic
	mat.roughness = roughness
	var maps := _texture_maps(slot)
	if maps.has("albedo"):
		mat.albedo_texture = maps["albedo"]
	if maps.has("normal"):
		mat.normal_enabled = true
		mat.normal_texture = maps["normal"]
	if maps.has("rough"):
		mat.roughness_texture = maps["rough"]
	if maps.has("metal"):
		mat.metallic_texture = maps["metal"]
	if maps.has("emis"):
		mat.emission_enabled = true
		mat.emission_texture = maps["emis"]
		mat.emission_energy_multiplier = 1.0
	return mat

static func _texture_maps(slot: String) -> Dictionary:
	if _texture_cache.has(slot):
		return _texture_cache[slot]
	var maps: Dictionary = {}
	var suffixes := {"albedo": "_albedo", "normal": "_normal", "rough": "_rough",
		"metal": "_metallic", "emis": "_emissive"}
	for key in suffixes:
		for ext in TEXTURE_EXTENSIONS:
			var path := "res://assets/textures/%s%s.%s" % [slot, suffixes[key], ext]
			if ResourceLoader.exists(path):
				maps[key] = load(path)
				break
	_texture_cache[slot] = maps
	return maps

static func has_texture(slot: String) -> bool:
	return not _texture_maps(slot).is_empty()
