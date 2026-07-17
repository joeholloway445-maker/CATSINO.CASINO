class_name NpcBody
extends Node3D
## The VISUAL of one generated NPC at the ESO-realistic bar.
##
## Resolves the mesh through MetahumanCharacter.build_npc() (shipped
## PeriHuman GLBs → interim humanoid → CharacterRig last resort) and then
## applies this NPC's generated traits as variation. Players never need
## Unreal/MakeHuman — bodies ship in the build.
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

	# MetahumanCharacter.build_npc tries the peri_human_npc / metahuman_npc /
	# npc_human variant pools itself (in that priority order) when given an
	# rng, so a single call here covers both the MakeHuman-generated
	# "npc_human" pool and any peri_human/metahuman assets dropped in later.
	# Seeded by npc id so the same person always has the same body.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("npc_body_" + str(npc.get("id", npc.get("name", "npc"))))
	_mesh_root = MetahumanCharacter.build_npc("identity", str(npc.get("race_id", "")), rng)
	add_child(_mesh_root)

	_apply_stature(appearance)
	_apply_surface_tints(appearance, str(npc.get("faction", "")))
	_apply_archetype_silhouette(str(npc.get("archetype", "")))

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

## Tint identifiable surfaces on WHATEVER mesh is actually installed.
## MetaHuman exports name surfaces Skin/Face/Body/Hair/Eyelash — those get
## skin/hair tone. The current interim mesh (godot-tps-demo's player robot)
## instead exposes "playerobot" (chassis shell) and "robotemitter" (its
## glow strip); those get archetype-flavored chassis tint + faction-accent
## glow so the crowd reads as individuals instead of 1,000 identical bots.
## Any surface not matched by either family is left alone — textured
## detail (and any future MetaHuman skin work) is never polluted.
func _apply_surface_tints(appearance: Dictionary, faction: String) -> void:
	if _mesh_root == null:
		return
	var skin := Color(str(appearance.get("skin_tone_hex", "d9b08c")))
	var hair := Color(str(appearance.get("hair_color_hex", "3b2a20")))
	var chassis := Color(str(appearance.get("chassis_hex", "888888")))
	var glow: Color = CityData.accent_for(faction)
	for mi in _find_meshes(_mesh_root):
		var mesh := mi.mesh
		if mesh == null:
			continue
		for s in range(mesh.get_surface_count()):
			var mat := mi.get_active_material(s)
			if mat == null or not (mat is BaseMaterial3D):
				continue
			var label := "%s %s" % [mat.resource_name.to_lower(), mi.name.to_lower()]
			var target: Color
			var blend: float
			if "skin" in label or "face" in label:
				target = skin; blend = 0.65
			elif "hair" in label or "brow" in label or "beard" in label:
				target = hair; blend = 0.65
			elif "outfit" in label or "cloth" in label:
				# MakeHuman bodies: fitted outfit colored by archetype (the
				# same palette the robot chassis used — brass barista,
				# gunmetal authority, jewel-red lover, ...).
				target = chassis; blend = 0.75
			elif "emitter" in label or "glow" in label:
				target = glow; blend = 0.85
			elif "robot" in label or "body" in label or "arm" in label:
				target = chassis; blend = 0.55
			else:
				continue
			# Duplicate before touching — materials are shared resources and
			# tinting a shared one would repaint every NPC in the scene.
			var own := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
			# Lerp toward the tone so albedo texture detail (pores, strands,
			# panel lines) survives — a flat assignment would look like plastic.
			own.albedo_color = own.albedo_color.lerp(target, blend)
			if "emitter" in label or "glow" in label:
				own.emission_enabled = true
				own.emission = target
			mi.set_surface_override_material(s, own)

## Archetype-flavored accessory variety: the current chassis has a fixed
## "Cannons" appendage (see godot/assets/models/ATTRIBUTION.md — it's a
## sci-fi TPS-demo robot, not a human). Showing it on a Barista/Archivist/
## Lover/Reflection reads as armed and wrong for the archetype; Authority
## keeps it — a visible weapon actually suits "power-holder." This only
## toggles visibility on an existing named node, no guessed positions.
func _apply_archetype_silhouette(archetype: String) -> void:
	if _mesh_root == null or archetype == "authority":
		return
	for mi in _find_meshes(_mesh_root):
		if "cannon" in mi.name.to_lower():
			mi.visible = false

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
