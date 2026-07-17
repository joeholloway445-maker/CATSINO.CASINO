extends SceneTree
## Assert PeriHuman ship slots are upright ~1.8m (not giant / laying down).
## Run: godot --headless --path godot -s res://src/dev/humanoid_pose_smoke.gd

func _initialize() -> void:
	call_deferred("_run")

func _fail(msg: String) -> void:
	push_error("[humanoid_pose_smoke] FAIL: " + msg)
	print("[humanoid_pose_smoke] RESULT=FAIL")
	quit(1)

func _ok(step: String) -> void:
	print("[humanoid_pose_smoke] OK: ", step)

func _aabb(root: Node3D) -> AABB:
	var merged := AABB()
	var any := false
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			if mi.mesh != null:
				var local := mi.get_aabb()
				var xf := Transform3D.IDENTITY
				var cur: Node = mi
				while cur != null and cur != root:
					if cur is Node3D:
						xf = (cur as Node3D).transform * xf
					cur = cur.get_parent()
				for i in 8:
					var corner := local.position + Vector3(
						local.size.x if (i & 1) else 0.0,
						local.size.y if (i & 2) else 0.0,
						local.size.z if (i & 4) else 0.0)
					var p: Vector3 = xf * corner
					if not any:
						merged = AABB(p, Vector3.ZERO)
						any = true
					else:
						merged = merged.expand(p)
		for child in node.get_children():
			stack.append(child)
	return merged

func _check(label: String, root: Node3D) -> bool:
	var aabb := _aabb(root)
	var sx := aabb.size.x
	var sy := aabb.size.y
	var sz := aabb.size.z
	print("[humanoid_pose_smoke] %s aabb=%.2f,%.2f,%.2f min_y=%.2f" % [label, sx, sy, sz, aabb.position.y])
	if sy < 1.4 or sy > 2.2:
		_fail("%s height on Y is %.2f (want ~1.5–2.1)" % [label, sy])
		return false
	if sy < maxf(sx, sz) * 0.9:
		_fail("%s not upright — Y=%.2f not tallest (x=%.2f z=%.2f)" % [label, sy, sx, sz])
		return false
	if maxf(sx, maxf(sy, sz)) > 3.0:
		_fail("%s still giant (tallest=%.2f)" % [label, maxf(sx, maxf(sy, sz))])
		return false
	_ok(label)
	return true

func _run() -> void:
	print("[humanoid_pose_smoke] start")
	var player := MetahumanCharacter.build_player("identity")
	if player == null:
		_fail("build_player null")
		return
	if not _check("build_player", player):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var npc := MetahumanCharacter.build_npc("identity", "", rng)
	if npc == null:
		_fail("build_npc null")
		return
	if not _check("build_npc_variant", npc):
		return
	var npc_ship := MetahumanCharacter.build_npc("identity", "", null)
	if npc_ship == null:
		_fail("build_npc ship null")
		return
	if not _check("build_npc_ship", npc_ship):
		return
	print("[humanoid_pose_smoke] RESULT=PASS")
	quit(0)
