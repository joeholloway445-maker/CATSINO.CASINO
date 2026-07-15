class_name RemotePlayer
extends Node3D
## Another player (or offline ghost) in the world. Default presentation is
## the casino house cat; PVXC PvP phase swaps to a perceived CharacterRig
## (race/frame silhouette) so fights happen as yourselves.

var peer_id := ""
var profile: Dictionary = {}
## "cat" or "identity" — mirrors ThirdPersonController.visual_mode.
var visual_mode := "identity"
var _body_root: Node3D
var _plate: Label3D

func setup(id: String, p: Dictionary, mode: String = "identity") -> void:
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

	var race_id := str(profile.get("race_id", ""))
	var body := MetahumanCharacter.build_npc(visual_mode, race_id)
	# MetahumanCharacter.build_npc's default body is a PeriHumanRig (a whole
	# skeleton+skin hierarchy, not a bare mesh) — `is MeshInstance3D` never
	# matched it, so the perceived material/view-scale style silently never
	# applied to remote PeriHumans. apply_perception() is the fix.
	if body is PeriHumanRig:
		body.apply_perception(seen.view, seen.material)
	elif body is MeshInstance3D:
		body.material_override = seen.material
	_body_root = body
	add_child(body)

	_plate = Label3D.new()
	_plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_plate.position.y = 2.2
	_plate.font_size = 48
	_plate.outline_size = 8
	if seen.view.get("loadout_visible", true):
		_plate.text = peer_id.trim_prefix("ghost_").replace("_", " ")
		_plate.modulate = seen.view.get("aura_color", Color.WHITE)
	else:
		_plate.text = "???" # outclassed: you don't get their name either
		_plate.modulate = Color(0.4, 0.4, 0.45)
	add_child(_plate)

func move_to(pos: Vector3, terrain = null) -> void:
	var target := pos
	if terrain != null and terrain.has_method("height_at"):
		target.y = terrain.height_at(pos.x, pos.z) + 0.1
	# Smooth toward the reported position.
	global_position = global_position.lerp(target, 0.2)
