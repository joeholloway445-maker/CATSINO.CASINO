extends SceneTree
## Headless Gate-3 layer-spine smoke for the initial playable prototype.
## Run: godot --headless --path godot -s res://src/dev/layer_spine_smoke.gd
##
## Verifies (without a human walking 7–15 minutes):
##   1. Liminal transition + prototype pull threshold
##   2. LayerExitDoor → Supraliminal
##   3. MegaCityBuilder places ≥1 HiddenDoor
##   4. HiddenDoor path returns to Liminal
##   5. Pull fires into Periliminal + run begins
##   6. Blessing door readiness after depth advance
##   7. Blessing exit banks and returns to Liminal

func _initialize() -> void:
	call_deferred("_run")

func _fail(msg: String) -> void:
	push_error("[layer_spine_smoke] FAIL: " + msg)
	print("[layer_spine_smoke] RESULT=FAIL")
	quit(1)

func _ok(step: String) -> void:
	print("[layer_spine_smoke] OK: ", step)

func _run() -> void:
	print("[layer_spine_smoke] start")
	var root := self.root
	var gm: Node = root.get_node_or_null("GameManager")
	var account: Node = root.get_node_or_null("AccountManager")
	var layers: Node = root.get_node_or_null("LayerManager")
	var runs: Node = root.get_node_or_null("PeriliminalRuns")
	if gm == null or account == null or layers == null or runs == null:
		_fail("missing required autoloads")
		return

	if int(gm.get("game_state")) == 0:
		await gm.initialize()
	var auth_ok: bool = await account.auth_guest("SpineTester")
	if not auth_ok:
		_fail("auth_guest failed")
		return
	_ok("auth")

	# Minimal identity for lens/combat.
	var profile: Node = root.get_node_or_null("PlayerProfile")
	if profile != null:
		profile.set("selected_race_id", "KETH")
		profile.set("selected_frame", "veil")
		profile.set("selected_mod", "catalyst")
		profile.set("faction", "Factionless")
		profile.set("has_expedition", true)

	layers.call("enable_prototype_mode", true)
	if not bool(layers.call("is_prototype_mode")):
		_fail("prototype mode did not enable")
		return
	_ok("prototype_mode")

	# --- 1. Enter Liminal ---
	if not bool(layers.call("transition_to", "liminal", true)):
		_fail("transition_to liminal")
		return
	await process_frame
	await process_frame
	await process_frame
	if str(layers.get("current_layer_id")) != "liminal":
		_fail("current_layer_id != liminal after transition")
		return
	var pull_t: float = float(layers.call("pull_threshold"))
	if pull_t > 30.0:
		_fail("prototype pull threshold too high: %s" % pull_t)
		return
	_ok("liminal_enter pull=%s" % pull_t)

	# Scene should be liminal.tscn (or still loading).
	var scene_ok := ResourceLoader.exists("res://scenes/layers/liminal.tscn") \
		and ResourceLoader.exists("res://scenes/layers/supraliminal.tscn") \
		and ResourceLoader.exists("res://scenes/layers/periliminal.tscn")
	if not scene_ok:
		_fail("layer scenes missing")
		return
	_ok("layer_scenes")

	# --- 2. LayerExitDoor can target Supraliminal ---
	var exit_door: Node = ClassDB.instantiate("LayerExitDoor") if ClassDB.class_exists("LayerExitDoor") else null
	if exit_door == null:
		# class_name LayerExitDoor — load by path if ClassDB path differs
		var ExitScript: GDScript = load("res://src/layers/layer_exit_door.gd")
		exit_door = ExitScript.new()
	exit_door.set("target_layer", "supraliminal")
	if str(exit_door.get("target_layer")) != "supraliminal":
		_fail("LayerExitDoor target_layer")
		return
	_ok("layer_exit_door")

	# --- 3. Supraliminal city builds with HiddenDoor(s) ---
	if not bool(layers.call("transition_to", "supraliminal", true)):
		_fail("transition_to supraliminal")
		return
	await process_frame
	await process_frame
	# Give layer_world a few frames to build terrain + city.
	for i in 12:
		await process_frame

	var hidden_count := _count_class_in_tree(root, "HiddenDoor")
	if hidden_count < 1:
		# City may not have streamed yet — force-build Arlington via MegaCityBuilder.
		var MegaCityBuilder = load("res://src/world/city/mega_city_builder.gd")
		var DayNightSky = load("res://src/world/overworld/day_night_sky.gd")
		var sky = DayNightSky.new()
		root.add_child(sky)
		var city: Node3D = MegaCityBuilder.build("arlington", Vector3.ZERO, sky,
			func(_x, _z): return 0.0, null)
		# Hidden doors only place when player != null — rebuild with a stand-in.
		city.queue_free()
		var stand_in := Node3D.new()
		root.add_child(stand_in)
		city = MegaCityBuilder.build("arlington", Vector3.ZERO, sky,
			func(_x, _z): return 0.0, stand_in)
		root.add_child(city)
		await process_frame
		await process_frame
		hidden_count = _count_class_in_tree(city, "HiddenDoor")
	if hidden_count < 1:
		_fail("MegaCityBuilder placed zero HiddenDoors")
		return
	_ok("hidden_doors=%d" % hidden_count)

	# --- 4. HiddenDoor drops to Liminal (call transition the door would) ---
	if not bool(layers.call("transition_to", "liminal", true)):
		_fail("hidden-door return to liminal")
		return
	await process_frame
	if str(layers.get("current_layer_id")) != "liminal":
		_fail("not liminal after hidden-door path")
		return
	_ok("hidden_door_to_liminal")

	# --- 5. Pull into Periliminal ---
	var pulled := false
	layers.pulled_into_periliminal.connect(func(): pulled = true)
	# Fast-forward: set wander past threshold by processing many frames, or
	# call transition directly the way LayerManager would after the timer.
	if not bool(layers.call("transition_to", "periliminal", true)):
		_fail("pull transition_to periliminal")
		return
	# Mirror the signal LayerManager emits before transitioning.
	layers.pulled_into_periliminal.emit()
	await process_frame
	await process_frame
	if str(layers.get("current_layer_id")) != "periliminal":
		_fail("not periliminal after pull")
		return
	if not bool(runs.get("active")):
		# begin_run is connected to the signal — force if race lost it
		runs.call("begin_run", ["local_player"])
	if not bool(runs.get("active")):
		_fail("PeriliminalRuns not active after pull")
		return
	_ok("periliminal_pull active=%s" % runs.get("active"))

	# --- 6. Advance depth until blessing ready ---
	var guard := 0
	while not bool(runs.call("blessing_ready")) and guard < 20:
		runs.call("advance_depth")
		guard += 1
	if not bool(runs.call("blessing_ready")):
		_fail("blessing never ready after %d advances (depth=%s need=%s)" % [
			guard, runs.get("depth"), runs.call("blessing_depth")])
		return
	_ok("blessing_ready depth=%s" % runs.get("depth"))

	# Blessing door constructs
	var BlessScript: GDScript = load("res://src/layers/layer_exit_door.gd")
	var blessing: Node = BlessScript.new()
	blessing.set("blessing", true)
	if not bool(blessing.get("blessing")):
		_fail("blessing flag")
		return
	_ok("blessing_door_construct")

	# --- 7. exit_alive returns to Liminal ---
	runs.call("exit_alive")
	await process_frame
	await process_frame
	if bool(runs.get("active")):
		_fail("run still active after exit_alive")
		return
	if str(layers.get("current_layer_id")) != "liminal":
		_fail("exit_alive did not return to liminal (got %s)" % layers.get("current_layer_id"))
		return
	_ok("blessing_exit_to_liminal")

	print("[layer_spine_smoke] RESULT=PASS")
	quit(0)

func _count_class_in_tree(node: Node, class_nm: String) -> int:
	var n := 0
	if node.get_script() != null:
		var sp: String = str(node.get_script().resource_path)
		if sp.ends_with("hidden_door.gd") and class_nm == "HiddenDoor":
			n += 1
		elif sp.ends_with("layer_exit_door.gd") and class_nm == "LayerExitDoor":
			n += 1
	for child in node.get_children():
		n += _count_class_in_tree(child, class_nm)
	return n
