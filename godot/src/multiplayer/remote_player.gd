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
	var race_id := str(profile.get("race_id", ""))
	# Seeded RNG so remotes get upright variant pools, not the broken ship slots.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("remote_body_" + peer_id + "_" + race_id)
	var body := MetahumanCharacter.build_npc(visual_mode, race_id, rng)
	if body is MeshInstance3D:
		body.material_override = seen.material
	_body_root = body
	add_child(body)
	_force_upright_remote(body)
	# Clamp perception scale so lens never recreates "giant" bots.
	var s := clampf(float(seen.view.get("apparent_scale", 1.0)), 0.7, 1.5)
	scale = Vector3.ONE * s

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

func _force_upright_remote(root: Node3D) -> void:
	if root == null:
		return
	root.rotation = Vector3.ZERO
	var aabb := AABB()
	var any := false
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var mi := n as MeshInstance3D
			for i in 8:
				var c: Vector3 = root.to_local(mi.to_global(mi.get_aabb().get_endpoint(i)))
				if not any:
					aabb = AABB(c, Vector3.ZERO)
					any = true
				else:
					aabb = aabb.expand(c)
		for c in n.get_children():
			stack.append(c)
	if not any:
		return
	var tallest := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if aabb.size.y < tallest * 0.55:
		if aabb.size.z >= aabb.size.x:
			root.rotate_object_local(Vector3.RIGHT, -PI * 0.5)
		else:
			root.rotate_object_local(Vector3.FORWARD, PI * 0.5)
		# Recompute after rotate
		aabb = AABB()
		any = false
		stack = [root]
		while not stack.is_empty():
			var n2: Node = stack.pop_back()
			if n2 is MeshInstance3D and (n2 as MeshInstance3D).mesh != null:
				var mi2 := n2 as MeshInstance3D
				for i in 8:
					var c2: Vector3 = root.to_local(mi2.to_global(mi2.get_aabb().get_endpoint(i)))
					if not any:
						aabb = AABB(c2, Vector3.ZERO)
						any = true
					else:
						aabb = aabb.expand(c2)
			for c in n2.get_children():
				stack.append(c)
	if aabb.size.y > 2.5:
		root.scale *= 1.80 / maxf(aabb.size.y, 0.01)
		aabb.size.y = 1.80
	if absf(aabb.position.y) > 0.02:
		root.position.y -= aabb.position.y

func move_to(pos: Vector3, terrain = null) -> void:
	var target := pos
	if terrain != null and terrain.has_method("height_at"):
		target.y = terrain.height_at(pos.x, pos.z) + 0.1
	# Smooth toward the reported position.
	global_position = global_position.lerp(target, 0.2)
