class_name AssetLibrary
## The asset upgrade pipeline. Every procedural mesh in the game asks this
## library first: if a real model exists at the documented path, it's used;
## otherwise the procedural fallback builds. This means dropping CC0/paid
## asset packs into assets/models/ upgrades the ENTIRE game's look with
## zero code changes — see docs/SHIPPING.md for the exact packs and the
## file names each slot expects.
##
## Slot -> expected file (first that exists wins):
##   metahuman_player   MetaHuman GLB export (identity — preferred)
##   metahuman_npc      MetaHuman GLB for NPCs / peers
##   metahuman_<race>   optional per-race MetaHuman variant
##   player_human       interim humanoid (TPS demo) until MetaHuman lands
##   npc_human          interim NPC humanoid
##   player_cat         optional Catsino house skin
##   npc_cat            optional Catsino NPC skin
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
## Variant pools (multiple models per slot — see instance_variant() below):
## res://data/asset_variants.json lists slot -> [filenames], resolved from
## res://assets/models/variants/<slot>/<file>. city_tower/city_lowrise/
## city_house/city_industrial/city_prop all have several real options; the
## single-file slots above remain the fallback when no manifest entry exists.
##
##   vehicle_car_body   land vehicles
##   vehicle_boat_body  water vehicles
##   vehicle_aircraft_body  air vehicles (empty until CC0 pack lands)
##   vehicle_spacecraft_body  space craft
##
## Structure / liminal builds (persistent env + procedural worlds):
##   city_* / road_* / sidewalk / streetlight / city_prop — Kenney city kits
##   apartment_prop    hideout furniture
##   ruin_pillar / extraction_gate / harvest_node / crystal — layer props
##
## Drop photoreal humans/creatures/structures from Sketchfab CC0, MetaHuman,
## MakeHuman, or AI gens (Meshy/Tripo/Luma) into these slots after Blender→GLB.
## Non-redistributable downloads go in assets/private/ — see docs/ASSET_PIPELINE.md.
##
## See docs/VISUAL_DIRECTION_ESO.md for MetaHuman + Terrain3D pipeline.

const SEARCH_EXTENSIONS := ["glb", "gltf", "tscn"]
const AUDIO_EXTENSIONS := ["ogg", "wav", "mp3"]
const TEXTURE_EXTENSIONS := ["png", "jpg", "webp"]
const VARIANTS_MANIFEST := "res://data/asset_variants.json"

static var _cache: Dictionary = {}
static var _audio_cache: Dictionary = {}
static var _texture_cache: Dictionary = {}
static var _variants_manifest: Dictionary = {}
static var _variants_loaded := false
static var _variant_scene_cache: Dictionary = {}  # "slot/file" -> PackedScene or null

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

## True if a real (non-procedural) asset file exists for the slot (no instantiate).
static func has_asset(slot: String) -> bool:
	for ext in SEARCH_EXTENSIONS:
		if ResourceLoader.exists("res://assets/models/%s.%s" % [slot, ext]):
			return true
	return false

## True if a real (non-procedural) asset is installed for the slot.
static func has(slot: String) -> bool:
	return has_asset(slot)

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

# ---------------------------------------------------------------- variants

## Multi-model slots: res://data/asset_variants.json maps a slot name to an
## array of filenames under res://assets/models/variants/<slot>/. This is
## additive to (never a replacement for) the single-file slot convention —
## a bare instance(slot) call still works if a variants list doesn't exist.
## JSON-manifest driven (not a runtime DirAccess directory listing) so it
## behaves identically in the editor and in exported/Web builds.
static func _load_variants_manifest() -> void:
	if _variants_loaded:
		return
	_variants_loaded = true
	if not FileAccess.file_exists(VARIANTS_MANIFEST):
		return
	var f := FileAccess.open(VARIANTS_MANIFEST, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_variants_manifest = parsed

## Deterministic pick from a slot's variant pool using an RNG the caller
## already advances in a fixed order (e.g. the per-city `rng` every
## MegaCityBuilder/BuildingBuilder call already threads through) — this
## keeps "the same city rebuilds identically" true with zero extra seeding.
## Falls back to the single-file slot, then to null (caller's procedural
## fallback), exactly like instance().
static func instance_variant(slot: String, rng: RandomNumberGenerator) -> Node3D:
	_load_variants_manifest()
	var files: Array = _variants_manifest.get(slot, [])
	if files.is_empty():
		return instance(slot)
	var pick := str(files[rng.randi() % files.size()])
	var cache_key := "%s/%s" % [slot, pick]
	if _variant_scene_cache.has(cache_key):
		var packed: PackedScene = _variant_scene_cache[cache_key]
		return packed.instantiate() if packed != null else instance(slot)
	var path := "res://assets/models/variants/%s/%s" % [slot, pick]
	if ResourceLoader.exists(path):
		var res := load(path)
		if res is PackedScene:
			_variant_scene_cache[cache_key] = res
			return res.instantiate()
	_variant_scene_cache[cache_key] = null
	return instance(slot)

## instance_or's variant-aware sibling: tries the variant pool, then the
## single-file slot, then calls `fallback`. Applies the identity lens like
## instance_or does.
static func instance_variant_or(slot: String, rng: RandomNumberGenerator,
		fallback: Callable, lens_color: Color = Color.WHITE, lens_strength: float = 0.2) -> Node3D:
	var node := instance_variant(slot, rng)
	if node == null:
		return fallback.call()
	if lens_strength > 0.0:
		_apply_lens(node, lens_color, lens_strength)
	return node

# ---------------------------------------------------------------- sounds

## Returns the AudioStream installed for a sound slot, or null if none is
## present (caller then synthesizes or stays silent). Pass looped=true for
## ambience beds so drop-in packs loop; one-shot SFX (ui_*, door_*, etc.)
## stay non-looping so NotificationUI / interactables don't drone.
static func sound(slot: String, looped: bool = false) -> AudioStream:
	var cache_key := "%s|%s" % [slot, "loop" if looped else "once"]
	if _audio_cache.has(cache_key):
		return _audio_cache[cache_key]
	for ext in AUDIO_EXTENSIONS:
		var path := "res://assets/audio/%s.%s" % [slot, ext]
		if ResourceLoader.exists(path):
			var res := load(path)
			if res is AudioStream:
				# Duplicate before mutating import defaults so one-shot and
				# looped callers can share the same source file.
				var stream: AudioStream = res.duplicate() if res.has_method("duplicate") else res
				if stream is AudioStreamOggVorbis:
					(stream as AudioStreamOggVorbis).loop = looped
				elif stream is AudioStreamWAV:
					(stream as AudioStreamWAV).loop_mode = (
						AudioStreamWAV.LOOP_FORWARD if looped else AudioStreamWAV.LOOP_DISABLED)
				_audio_cache[cache_key] = stream
				return stream
	_audio_cache[cache_key] = null
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
