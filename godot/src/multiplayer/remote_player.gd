class_name RemotePlayer
extends Node3D
## Another player (or offline ghost) in the world. Default presentation is
## the casino house cat; PVXC PvP phase swaps to a perceived CharacterRig
## (race/frame silhouette) so fights happen as yourselves.

var peer_id := ""
var profile: Dictionary = {}
## "cat" or "identity" — mirrors ThirdPersonController.visual_mode.
var visual_mode := "cat"
var _body_root: Node3D
var _plate: Label3D

func setup(id: String, p: Dictionary, mode: String = "cat") -> void:
	peer_id = id
	profile = p
	set_visual_mode(mode)

func set_visual_mode(mode: String) -> void:
	if mode != "cat" and mode != "identity":
		mode = "cat"
	visual_mode = mode
	if _body_root != null and is_instance_valid(_body_root):
		_body_root.queue_free()
	_body_root = null
	if _plate != null and is_instance_valid(_plate):
		_plate.queue_free()
	_plate = null
	_rebuild_body()

func _rebuild_body() -> void:
	var seen: Dictionary = IdentityLens.perceive_being(profile, Color(0.7, 0.6, 0.5))
	scale = Vector3.ONE * float(seen.view.get("apparent_scale", 1.0))

	if visual_mode == "identity":
		var rig := CharacterRig.new()
		rig.perceived = true
		rig.perceived_profile = profile
		# Ghost profiles lack race ids — fall back to a neutral loadout tinted
		# by perception so they still read as "someone," not a house cat.
		var race_id := str(profile.get("race_id", PlayerProfile.selected_race_id))
		var frame_id := str(profile.get("frame_id", "veil"))
		var mod_id := str(profile.get("mod_id", ""))
		var loadout := CharacterCreatorLogic.build_loadout(race_id, frame_id, mod_id)
		rig.build_from_loadout(loadout.race, loadout.frame, loadout.mod)
		_body_root = rig
		add_child(rig)
	else:
		var body: Node3D = AssetLibrary.instance("npc_cat")
		if body == null:
			var mi := MeshInstance3D.new()
			var caps := CapsuleMesh.new()
			caps.radius = 0.4
			caps.height = 1.2
			mi.mesh = caps
			mi.position.y = 0.6
			body = mi
		if body is MeshInstance3D:
			body.material_override = seen.material
		_body_root = body
		add_child(body)

	_plate = Label3D.new()
	_plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_plate.position.y = 2.2 if visual_mode == "identity" else 2.0
	_plate.font_size = 48
	_plate.outline_size = 8
	if seen.view.get("loadout_visible", true):
		_plate.text = peer_id.trim_prefix("ghost_").replace("_", " ")
		_plate.modulate = seen.view.get("aura_color", Color.WHITE)
	else:
		_plate.text = "???" # outclassed: you don't get their name either
		_plate.modulate = Color(0.4, 0.4, 0.45)
	add_child(_plate)

func move_to(pos: Vector3, terrain: ProceduralTerrain = null) -> void:
	var target := pos
	if terrain != null:
		target.y = terrain.height_at(pos.x, pos.z) + 0.1
	# Smooth toward the reported position.
	global_position = global_position.lerp(target, 0.2)
