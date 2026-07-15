class_name NpcBody
extends Node3D
## The VISUAL of one generated NPC at the ESO-realistic bar.
##
## Resolves the mesh through MetahumanCharacter.build_npc() (MetaHuman GLB →
## interim humanoid GLB → CharacterRig last resort) and then applies this
## NPC's generated traits as SUBTLE, natural variation — height, build width,
## skin/hair tint on named surfaces only. No cartoon scaling, no whole-body
## tints: if a surface can't be identified as skin or hair, it is left alone
## so the photoreal texture work is never polluted.
##
## LOD contract (driven by NPCManager.update_lod → NPCSpawner):
##   0  full mesh, shadows, nameplate           (< ~30 m)
##   1  full mesh, no shadows, no nameplate     (30–100 m)
##   2  impostor silhouette, no shadows         (> 100 m / over crowd budget)

const IMPOSTOR_COLOR := Color(0.13, 0.12, 0.14)

## Natural adult stature range (meters). Variation stays believable.
const HEIGHT_MIN := 1.55
const HEIGHT_MAX := 1.93
## The interim/MetaHuman exports are authored at roughly this height.
const AUTHORED_HEIGHT := 1.80

const BUILD_WIDTH := {
	"slim": 0.96,
	"average": 1.0,
	"athletic": 1.035,
	"muscular": 1.08,
}

var _mesh_root: Node3D = null
var _impostor: MeshInstance3D = null
var _nameplate: Label3D = null
var _lod := 0

## Build the body from a generated NPC dict (NPCGenerator output).
func build(npc: Dictionary) -> void:
	_clear()
	var appearance: Dictionary = npc.get("appearance", {})

	_mesh_root = MetahumanCharacter.build_npc("identity", str(npc.get("race_id", "")))
	add_child(_mesh_root)

	_apply_stature(appearance)
	_apply_surface_tints(appearance)

	_impostor = _build_impostor()
	_impostor.visible = false
	add_child(_impostor)

	_nameplate = _build_nameplate(str(npc.get("name", "")))
	add_child(_nameplate)

	update_lod(0)

## ── LOD ───────────────────────────────────────────────────────────────────
func update_lod(level: int) -> void:
	if level == _lod:
		return
	_lod = level
	var full := level < 2
	if _mesh_root:
		_mesh_root.visible = full
		_set_shadows(_mesh_root, level == 0)
	if _impostor:
		_impostor.visible = not full
	if _nameplate:
		_nameplate.visible = level == 0
	# Impostors don't wander: pause the AmbientNpc day-to-day loop beyond
	# LOD 1 so 1,000 NPCs never tick 1,000 _process loops.
	var p := get_parent()
	if p is AmbientNpc:
		p.set_process(full)

func lod() -> int:
	return _lod

## ── Trait application ─────────────────────────────────────────────────────
func _apply_stature(appearance: Dictionary) -> void:
	if _mesh_root == null:
		return
	var height := clampf(float(appearance.get("height_m", 1.72)), HEIGHT_MIN, HEIGHT_MAX)
	var h_scale := height / AUTHORED_HEIGHT
	var width: float = BUILD_WIDTH.get(str(appearance.get("build", "average")), 1.0)
	# Natural posture variation only — never balloon or squash a human.
	_mesh_root.scale = Vector3(h_scale * width, h_scale, h_scale * width)

## Tint ONLY surfaces that are identifiably skin or hair. MetaHuman exports
## name their surfaces (Skin/Face/Body/Hair/Eyelash); the interim TPS mesh
## mostly won't match, and is intentionally left untouched.
func _apply_surface_tints(appearance: Dictionary) -> void:
	if _mesh_root == null:
		return
	var skin := Color(str(appearance.get("skin_tone_hex", "d9b08c")))
	var hair := Color(str(appearance.get("hair_color_hex", "3b2a20")))
	for mi in _find_meshes(_mesh_root):
		var mesh := mi.mesh
		if mesh == null:
			continue
		for s in range(mesh.get_surface_count()):
			var mat := mi.get_active_material(s)
			if mat == null or not (mat is BaseMaterial3D):
				continue
			var label := "%s %s" % [mat.resource_name.to_lower(), mi.name.to_lower()]
			var target := Color.WHITE
			var is_skin := "skin" in label or "face" in label or "body" in label
			var is_hair := "hair" in label or "brow" in label or "beard" in label
			if not (is_skin or is_hair):
				continue
			target = skin if is_skin else hair
			# Duplicate before touching — materials are shared resources and
			# tinting a shared one would repaint every NPC in the scene.
			var own := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
			# Lerp toward the tone so albedo texture detail (pores, strands)
			# survives — a flat color assignment would look like plastic.
			own.albedo_color = own.albedo_color.lerp(target, 0.65)
			mi.set_surface_override_material(s, own)

func _find_meshes(root: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			out.append(n)
		for c in n.get_children():
			stack.append(c)
	return out

func _set_shadows(root: Node, on: bool) -> void:
	for mi in _find_meshes(root):
		mi.cast_shadow = (
			GeometryInstance3D.SHADOW_CASTING_SETTING_ON if on
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)

## ── Impostor ──────────────────────────────────────────────────────────────
## A distant person reads as a dark upright figure; one matte capsule at
## human proportions sells a crowd at a fraction of the cost. Never used
## inside interaction range.
func _build_impostor() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.22
	capsule.height = 1.75
	capsule.radial_segments = 8
	capsule.rings = 4
	mi.mesh = capsule
	mi.position.y = 0.9
	var mat := StandardMaterial3D.new()
	mat.albedo_color = IMPOSTOR_COLOR
	mat.roughness = 1.0
	mat.metallic = 0.0
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

func _build_nameplate(display_name: String) -> Label3D:
	var label := Label3D.new()
	label.text = display_name
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.004
	label.position = Vector3(0, 2.05, 0)
	label.modulate = Color(0.92, 0.92, 0.95, 0.85)
	label.outline_render_priority = 0
	label.no_depth_test = false
	return label

func _clear() -> void:
	for c in get_children():
		c.queue_free()
	_mesh_root = null
	_impostor = null
	_nameplate = null
