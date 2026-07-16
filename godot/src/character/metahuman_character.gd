class_name MetahumanCharacter
extends RefCounted
## PeriHuman visual resolver — characters/NPCs that ship in the build.
## Players never install Unreal, MakeHuman, or any DCC tool. Bodies are
## GLBs under assets/models/; this class just picks the best slot.
##
## Priority (first hit wins):
##   1. Race-specific — peri_human_<race> / metahuman_<race>
##   2. Shipped PeriHuman — peri_human_player|npc / metahuman_player|npc
##   3. Interim humanoid — player_human / npc_human
##   4. House-cat GLB — player_cat / npc_cat (Catsino skin only)
##   5. CharacterRig procedural humanoid (last resort)
##
## Studio-only upgrades (optional): replace those GLBs with MakeHuman /
## MetaHuman / CC4 exports via docs/VISUAL_DIRECTION_ESO.md. Same slots;
## players still just download the game. Skin/eye/hair look-dev shaders
## live under assets/shaders/metahuman/.

const PERI_PLAYER := "peri_human_player"
const PERI_NPC := "peri_human_npc"
const META_PLAYER := "metahuman_player"
const META_NPC := "metahuman_npc"
const HUMAN_PLAYER := "player_human"
const HUMAN_NPC := "npc_human"
const CAT_PLAYER := "player_cat"
const CAT_NPC := "npc_cat"

## Build the local player's body for the given visual mode.
static func build_player(visual_mode: String = "identity") -> Node3D:
	if visual_mode == "cat":
		var cat := AssetLibrary.instance(CAT_PLAYER)
		if cat != null:
			return _as_root(cat)
		# No cat mesh — fall through to PeriHuman (ESO bar wins).
	var race_id := ""
	if PlayerProfile:
		race_id = str(PlayerProfile.selected_race_id)
	var meta := _try_slots([
		"peri_human_%s" % race_id if not race_id.is_empty() else "",
		"metahuman_%s" % race_id if not race_id.is_empty() else "",
		PERI_PLAYER,
		META_PLAYER,
		HUMAN_PLAYER,
	])
	if meta != null:
		_try_apply_metahuman_materials(meta)
		return meta
	return _rig_from_profile(false)

## Build a remote / NPC body.
static func build_npc(visual_mode: String = "identity", race_id: String = "",
		rng: RandomNumberGenerator = null) -> Node3D:
	if visual_mode == "cat":
		var cat := AssetLibrary.instance(CAT_NPC)
		if cat != null:
			return _as_root(cat)
	# Prefer variant pools so NPCs don't all clone the same outfit.
	if rng != null:
		for slot in [PERI_NPC, META_NPC, HUMAN_NPC]:
			var variant := AssetLibrary.instance_variant(slot, rng)
			if variant != null:
				_try_apply_metahuman_materials(variant)
				return _as_root(variant)
	var meta := _try_slots([
		"peri_human_%s" % race_id if not race_id.is_empty() else "",
		"metahuman_%s" % race_id if not race_id.is_empty() else "",
		PERI_NPC,
		META_NPC,
		HUMAN_NPC,
		HUMAN_PLAYER,
	])
	if meta != null:
		_try_apply_metahuman_materials(meta)
		return meta
	return _rig_from_profile(true)

static func _try_slots(slots: Array) -> Node3D:
	for s in slots:
		var slot := str(s)
		if slot.is_empty():
			continue
		var n := AssetLibrary.instance(slot)
		if n != null:
			return _as_root(n)
	return null

static func _as_root(n: Node) -> Node3D:
	if n is Node3D:
		return n as Node3D
	var root := Node3D.new()
	root.add_child(n)
	return root

static func _rig_from_profile(perceived: bool) -> Node3D:
	var rig := CharacterRig.new()
	rig.perceived = perceived
	var race_id := "KETH"
	var frame_id := "VEIL"
	var mod_id := "CATALYST"
	if PlayerProfile:
		if str(PlayerProfile.selected_race_id) != "":
			race_id = str(PlayerProfile.selected_race_id)
		if str(PlayerProfile.selected_frame) != "":
			frame_id = str(PlayerProfile.selected_frame)
		if str(PlayerProfile.selected_mod) != "":
			mod_id = str(PlayerProfile.selected_mod)
	var loadout := CharacterCreatorLogic.build_loadout(race_id, frame_id, mod_id)
	rig.build_from_loadout(loadout.get("race", {}), loadout.get("frame", {}), loadout.get("mod", {}))
	return rig

## Look-dev pass for shipped PeriHumans / future MetaHuman exports.
## On Forward+: try MetaHumanGodot skin shader on Skin* surfaces.
## Everywhere: tune StandardMaterial3D skin/cloth/hair toward soft SSS-like
## reads (lower roughness, slight subsurface / rim) so Blender Studio bases
## don't look plastic under HDRI.
static func _try_apply_metahuman_materials(root: Node3D) -> void:
	root.set_meta("peri_human", true)
	var shader_path := "res://assets/shaders/metahuman/skin_shader_local.gdshader"
	var skin_shader: Shader = null
	if ResourceLoader.exists(shader_path):
		skin_shader = load(shader_path) as Shader
		root.set_meta("metahuman_shader_ready", true)
	_tune_meshes(root, skin_shader)

static func _tune_meshes(node: Node, skin_shader: Shader) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for si in range(mi.mesh.get_surface_count()):
				var mat := mi.get_active_material(si)
				if mat == null:
					continue
				var sname := _surface_name(mi, si).to_lower()
				var tuned := _tune_surface_material(mat, sname, skin_shader)
				if tuned != null:
					mi.set_surface_override_material(si, tuned)
	for child in node.get_children():
		_tune_meshes(child, skin_shader)

static func _surface_name(mi: MeshInstance3D, si: int) -> String:
	var mesh := mi.mesh
	if mesh != null and mesh is ArrayMesh:
		var am := mesh as ArrayMesh
		var n := am.surface_get_name(si)
		if not n.is_empty():
			return n
	var mat := mi.get_active_material(si)
	if mat != null and not mat.resource_name.is_empty():
		return mat.resource_name
	return mi.name

static func _tune_surface_material(mat: Material, sname: String, skin_shader: Shader) -> Material:
	var is_skin := (
		sname.contains("skin") or sname.contains("body") or sname.contains("head")
		or sname.contains("face") or sname.contains("arm") or sname.contains("leg")
	)
	var is_eye := sname.contains("eye") or sname.contains("cornea") or sname.contains("sclera")
	var is_hair := (
		sname.contains("hair") or sname.contains("brow") or sname.contains("lash")
		or sname.contains("scalp")
	)
	var is_cloth := (
		sname.contains("cloth") or sname.contains("shirt") or sname.contains("pant")
		or sname.contains("shoe") or sname.contains("boot") or sname.contains("outfit")
		or sname.contains("dress") or sname.contains("jacket")
	)
	# Forward+ only: full skin shader (too heavy / incomplete on compat).
	if is_skin and skin_shader != null and not RenderCaps.is_compatibility():
		var sm := ShaderMaterial.new()
		sm.shader = skin_shader
		if mat is BaseMaterial3D:
			var bm := mat as BaseMaterial3D
			sm.set_shader_parameter("albedo", bm.albedo_color)
			if bm.albedo_texture != null:
				sm.set_shader_parameter("texture_albedo", bm.albedo_texture)
			sm.set_shader_parameter("roughness", clampf(bm.roughness * 0.85, 0.25, 0.65))
		else:
			sm.set_shader_parameter("albedo", Color(0.82, 0.62, 0.52))
			sm.set_shader_parameter("roughness", 0.45)
		return sm
	if mat is StandardMaterial3D:
		var std := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
		if is_skin:
			std.roughness = clampf(std.roughness * 0.75, 0.28, 0.62)
			std.metallic = 0.0
			std.specular = 0.45
			if not RenderCaps.is_compatibility():
				# Property names differ slightly across 4.x — set only if present.
				if "subsurf_scatter_enabled" in std:
					std.subsurf_scatter_enabled = true
					std.subsurf_scatter_strength = 0.35
				if "rim_enabled" in std:
					std.rim_enabled = true
					std.rim = 0.08
					std.rim_tint = 0.6
		elif is_eye:
			std.roughness = 0.08
			std.metallic = 0.0
			std.specular = 0.7
		elif is_hair:
			std.roughness = clampf(std.roughness, 0.35, 0.7)
			std.specular = 0.55
		elif is_cloth:
			std.roughness = maxf(std.roughness, 0.7)
			std.metallic = minf(std.metallic, 0.05)
		else:
			# Generic body/cloth on Blender Studio bake — soft matte.
			std.roughness = clampf(std.roughness, 0.4, 0.85)
		return std
	return null

## Which visual tier would win for the local player right now?
## Returns one of: peri_human_race | peri_human_player | metahuman_race |
## metahuman_player | player_human | player_cat | procedural_rig
static func resolve_tier(visual_mode: String = "identity") -> String:
	if visual_mode == "cat" and AssetLibrary.has_asset("player_cat"):
		return "player_cat"
	var race_id := ""
	if PlayerProfile:
		race_id = str(PlayerProfile.selected_race_id)
	if not race_id.is_empty() and AssetLibrary.has_asset("peri_human_%s" % race_id):
		return "peri_human_race"
	if not race_id.is_empty() and AssetLibrary.has_asset("metahuman_%s" % race_id):
		return "metahuman_race"
	if AssetLibrary.has_asset(PERI_PLAYER) or AssetLibrary.has_asset(META_PLAYER):
		return "peri_human_player"
	if AssetLibrary.has_asset(HUMAN_PLAYER):
		return "player_human"
	return "procedural_rig"
