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
## Also checks assets/models/<slot>.gltf and .tscn variants.

const SEARCH_EXTENSIONS := ["glb", "gltf", "tscn"]

static var _cache: Dictionary = {}

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
