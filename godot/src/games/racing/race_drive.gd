extends Node3D
## The drivable race. A ring circuit sized from the track's real distance,
## arcade handling (throttle/brake/steer with drift-y grip), AI opponents
## pacing at their frame speeds, live positions, lap counting, and the
## same payout math as the lobby sim (RaceSession.payout). Neon-night
## visuals; "Ridin' Tonight" carries the race via MusicManager.
##
## Controls: W/↑ throttle, S/↓ brake, A/D steer, Shift nitro (drains).

const AI_COUNT := 5
const ROAD_WIDTH := 14.0

var _radius: float
var _laps_total: int
var _player: CharacterBody3D
var _speed := 0.0
var _heading := 0.0
var _nitro := 100.0
var _lap := 0
var _last_angle := 0.0
var _progress := 0.0 # cumulative radians
var _finished := false
var _ai: Array[Dictionary] = []
var _hud: Label

func _ready() -> void:
	if RaceSession.track.is_empty():
		get_tree().change_scene_to_file.call_deferred("res://scenes/games/racing/race_track.tscn")
		return
	_radius = float(RaceSession.track.get("distance", 1200.0)) / TAU
	_laps_total = int(RaceSession.track.get("laps", 3))
	MusicManager.enter_racing()
	_build_world()
	_build_player()
	_build_ai()
	_build_hud()

func _build_world() -> void:
	var sky := DayNightSky.new()
	sky.start_hour = 22.0 # street racing happens at night
	sky.day_length_seconds = 999999.0
	IdentityLens.tune_sky(sky)
	add_child(sky)

	# Road ring.
	var road := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = _radius - ROAD_WIDTH / 2.0
	torus.outer_radius = _radius + ROAD_WIDTH / 2.0
	road.mesh = torus
	road.scale.y = 0.02
	var road_mat := StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.12, 0.12, 0.16)
	road_mat.roughness = 0.6
	road.material_override = road_mat
	add_child(road)

	# Ground plane under everything (lensed).
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(_radius * 3.0, _radius * 3.0)
	ground.mesh = plane
	ground.position.y = -0.3
	ground.material_override = IdentityLens.world_material(Color(0.08, 0.1, 0.14))
	add_child(ground)

	# Neon edge pylons + start line.
	for i in range(48):
		var a := TAU * i / 48.0
		for r_off in [-ROAD_WIDTH / 2.0 - 1.0, ROAD_WIDTH / 2.0 + 1.0]:
			var py := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.4, 2.2, 0.4)
			py.mesh = box
			py.position = Vector3(cos(a) * (_radius + r_off), 1.1, sin(a) * (_radius + r_off))
			var m := StandardMaterial3D.new()
			var neon := Color(0.2, 0.9, 1.0) if i % 2 == 0 else Color(1.0, 0.3, 0.8)
			m.albedo_color = neon
			m.emission_enabled = true
			m.emission = neon
			m.emission_energy_multiplier = 1.6
			py.material_override = m
			add_child(py)

	var start := MeshInstance3D.new()
	var sbox := BoxMesh.new()
	sbox.size = Vector3(ROAD_WIDTH, 0.05, 1.5)
	start.mesh = sbox
	start.position = Vector3(_radius, 0.05, 0)
	start.rotation.y = PI / 2.0
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color.WHITE
	smat.emission_enabled = true
	smat.emission = Color.WHITE
	start.material_override = smat
	add_child(start)

func _build_player() -> void:
	_player = CharacterBody3D.new()
	var body: Node3D = AssetLibrary.instance("player_cat")
	if body == null:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.2, 0.7, 2.2)
		mi.mesh = box
		mi.position.y = 0.5
		mi.material_override = IdentityLens.world_material(
			RaceDataCharacter.get_race(PlayerProfile.selected_race_id).get("primary_color", Color.ORANGE), 0.8)
		body = mi
	_player.add_child(body)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.2, 0.7, 2.2)
	cs.shape = bs
	cs.position.y = 0.5
	_player.add_child(cs)
	_player.position = Vector3(_radius, 0.2, 2.0)
	_heading = -PI / 2.0 # facing along the ring
	add_child(_player)

	var cam := Camera3D.new()
	cam.name = "ChaseCam"
	cam.current = true
	add_child(cam)

func _build_ai() -> void:
	var frame_speed := {
		"bolt": 1.15, "veil": 1.05, "zephyr": 1.0, "phantom": 0.95, "flux": 0.95,
		"cinder": 0.9, "crimson": 0.9, "soul": 0.9, "tremor": 0.85, "surge": 0.85,
		"bastion": 0.8, "glacial": 0.8,
	}
	for i in range(AI_COUNT):
		var fid: String = RaceAI.AI_FRAMES[i % RaceAI.AI_FRAMES.size()]
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.2, 0.7, 2.2)
		mi.mesh = box
		var m := StandardMaterial3D.new()
		m.albedo_color = Color.from_hsv(float(i) / AI_COUNT, 0.7, 0.9)
		m.emission_enabled = true
		m.emission = m.albedo_color
		m.emission_energy_multiplier = 0.4
		mi.material_override = m
		add_child(mi)
		_ai.append({
			"node": mi, "name": RaceAI.AI_NAMES[i],
			"angle": -0.02 * (i + 1), "lane": randf_range(-4.0, 4.0),
			"speed": (26.0 + i * 1.5) * frame_speed.get(fid, 0.9), # rad-independent m/s
			"progress": -0.02 * (i + 1),
		})

func _physics_process(delta: float) -> void:
	if _finished or _player == null:
		return
	# Arcade handling.
	var accel := 24.0 if Input.is_action_pressed("ui_up") else 0.0
	if Input.is_key_pressed(KEY_W): accel = 24.0
	var brake := 30.0 if (Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S)) else 0.0
	if Input.is_key_pressed(KEY_SHIFT) and _nitro > 0.0:
		accel += 20.0
		_nitro = maxf(_nitro - 25.0 * delta, 0.0)
	else:
		_nitro = minf(_nitro + 8.0 * delta, 100.0)
	var top := 42.0
	_speed = clampf(_speed + (accel - brake - 4.0) * delta, 0.0, top)
	var steer := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A): steer -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D): steer += 1.0
	_heading += steer * delta * lerpf(2.4, 1.1, _speed / top)

	_player.velocity = Vector3(sin(_heading), 0, cos(_heading)) * _speed
	_player.move_and_slide()
	_player.rotation.y = _heading

	# Off-road drag.
	var dist := Vector2(_player.position.x, _player.position.z).length()
	if absf(dist - _radius) > ROAD_WIDTH / 2.0:
		_speed *= 0.96

	# Progress / laps (angular, unwrapped).
	var ang := atan2(_player.position.z, _player.position.x)
	var d_ang := wrapf(ang - _last_angle, -PI, PI)
	_last_angle = ang
	_progress += -d_ang # clockwise = forward
	if _progress >= TAU * (_lap + 1):
		_lap += 1
		NotificationUI.notify_info("Lap %d / %d" % [_lap, _laps_total])
		if _lap >= _laps_total:
			_finish()

	# AI pace.
	for a in _ai:
		a.progress += (a.speed / _radius) * delta * randf_range(0.97, 1.03)
		var aa: float = -a.progress
		var r: float = _radius + a.lane
		a.node.position = Vector3(cos(aa) * r, 0.4, sin(aa) * r)
		a.node.rotation.y = -aa + PI

	# Chase cam.
	var cam: Camera3D = get_node_or_null("ChaseCam")
	if cam:
		var back := _player.position - Vector3(sin(_heading), 0, cos(_heading)) * 7.0 + Vector3(0, 3.2, 0)
		cam.position = cam.position.lerp(back, 0.15)
		cam.look_at(_player.position + Vector3(0, 1, 0))

	_update_hud()

func _position_now() -> int:
	var ahead := 0
	for a in _ai:
		if a.progress * _radius > _progress * _radius:
			ahead += 1
	return ahead + 1

func _update_hud() -> void:
	if _hud:
		_hud.text = "P%d/%d   Lap %d/%d   %d km/h   Nitro %d%%" % [
			_position_now(), AI_COUNT + 1, mini(_lap + 1, _laps_total), _laps_total,
			int(_speed * 3.6), int(_nitro)]

func _finish() -> void:
	_finished = true
	var place := _position_now()
	var prize := RaceSession.payout(place, RaceSession.bet, RaceSession.track)
	if prize > 0:
		EconomyManager.add_coins(prize, "race_drive_win")
	# Same quest/crown/achievement hooks as simulated races.
	QuestManager.update_progress("race_neon")
	QuestManager.update_progress("race_3")
	QuestManager.update_progress("race_1")
	if place == 1:
		QuestManager.update_progress("first_place")
		QuestManager.update_progress("win_race")
		MusicManager.play_context("victory", false)
	NotificationUI.notify_win("🏁 P%d! %s" % [place, ("+%d 🪙" % prize) if prize > 0 else "No payout."])
	EconomyManager.earn_prestige(10 if place <= 3 else 4, "race_drive")
	await get_tree().create_timer(3.0).timeout
	MusicManager.exit_racing()
	get_tree().change_scene_to_file("res://scenes/games/racing/race_track.tscn")

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(10, 10)
	_hud.add_theme_font_size_override("font_size", 20)
	layer.add_child(_hud)
	var hint := Label.new()
	hint.text = "W throttle • S brake • A/D steer • Shift nitro"
	hint.position = Vector2(10, 44)
	hint.modulate = Color(1, 1, 1, 0.5)
	layer.add_child(hint)
