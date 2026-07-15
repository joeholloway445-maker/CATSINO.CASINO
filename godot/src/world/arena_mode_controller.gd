class_name ArenaModeController
extends Node3D
## Mode-specific arena rules for playtest_arena / combat_zone entry points.
## survival → shrinking safe zone · zombies → feral waves · ctf → yarn deliver
## duel / duel_2v2 → staged entity opponents. Rewards tokens + prestige on win.

signal mode_won(mode_id: String, score: int)
signal mode_lost(mode_id: String)

var mode_id: String = ""
var player: Node3D
var _hud: Label
var _elapsed := 0.0
var _score := 0
var _alive: Array[Node] = []
var _wave := 0
var _zone_radius := 42.0
var _zone_visual: MeshInstance3D
var _yarn: Area3D
var _yarn_held := false
var _goal: Area3D
var _running := true

func setup(p_mode: String, p_player: Node3D) -> void:
	mode_id = p_mode
	player = p_player
	_build_hud()
	match mode_id:
		"survival":
			_setup_survival()
		"zombies":
			_setup_zombies()
		"ctf":
			_setup_ctf()
		"duel", "duel_2v2":
			_setup_duel()
		_:
			NotificationUI.notify_info("Arena: free roam (%s)" % mode_id)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(24, 24)
	_hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(_hud)
	_refresh_hud("Ready")

func _refresh_hud(extra: String = "") -> void:
	if _hud == null:
		return
	_hud.text = "%s | score %d | %s" % [mode_id.to_upper(), _score, extra]

func _process(delta: float) -> void:
	if not _running or player == null:
		return
	_elapsed += delta
	match mode_id:
		"survival":
			_tick_survival(delta)
		"zombies":
			_tick_zombies(delta)
		"ctf":
			_tick_ctf()
		"duel", "duel_2v2":
			_tick_duel()

# ── Survival (shrinking zone) ──────────────────────────────────────────────
func _setup_survival() -> void:
	_zone_visual = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = _zone_radius
	cyl.bottom_radius = _zone_radius
	cyl.height = 0.2
	_zone_visual.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0, 0.18)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_zone_visual.material_override = mat
	_zone_visual.position = Vector3(0, 0.05, 0)
	add_child(_zone_visual)
	_spawn_ferals(4, 1)
	NotificationUI.notify_info("Last Cat Standing — stay inside the ring.")

func _tick_survival(delta: float) -> void:
	_zone_radius = maxf(8.0, 42.0 - _elapsed * 0.55)
	if _zone_visual and _zone_visual.mesh is CylinderMesh:
		var cyl := _zone_visual.mesh as CylinderMesh
		cyl.top_radius = _zone_radius
		cyl.bottom_radius = _zone_radius
	var flat := Vector2(player.global_position.x, player.global_position.z)
	if flat.length() > _zone_radius:
		_score = maxi(0, _score - int(delta * 8))
		_refresh_hud("OUTSIDE ZONE")
	else:
		_score += int(delta * 2)
		_refresh_hud("safe r=%.0f" % _zone_radius)
	_prune_dead()
	if _elapsed >= 90.0:
		_finish(true)
	elif _alive.is_empty() and _elapsed > 5.0:
		_spawn_ferals(3 + int(_elapsed / 30.0), mini(3, 1 + int(_elapsed / 40.0)))

# ── Zombies / feral waves ──────────────────────────────────────────────────
func _setup_zombies() -> void:
	_wave = 0
	_next_wave()
	NotificationUI.notify_info("Feral Horde — clear the waves.")

func _tick_zombies(_delta: float) -> void:
	_prune_dead()
	_refresh_hud("wave %d · left %d" % [_wave, _alive.size()])
	if _alive.is_empty() and _wave > 0:
		if _wave >= 5:
			_finish(true)
		else:
			_next_wave()

func _next_wave() -> void:
	_wave += 1
	var count := 3 + _wave * 2
	var stage := mini(3, 1 + int((_wave - 1) / 2))
	_spawn_ferals(count, stage)
	NotificationUI.notify_info("Wave %d — %d ferals (stage %d)" % [_wave, count, stage])

# ── CTF yarn rush ──────────────────────────────────────────────────────────
func _setup_ctf() -> void:
	_yarn = _make_pickup(Vector3(18, 1, 0), Color(1.0, 0.85, 0.2), "YarnBall")
	_goal = _make_pickup(Vector3(-18, 1, 0), Color(0.3, 1.0, 0.45), "Goal")
	_yarn.body_entered.connect(_on_yarn_entered)
	_goal.body_entered.connect(_on_goal_entered)
	_spawn_ferals(3, 1)
	NotificationUI.notify_info("Yarn Rush — grab the yarn, deliver to the green pad.")

func _tick_ctf() -> void:
	_prune_dead()
	_refresh_hud("yarn %s · delivers %d/3" % ["HELD" if _yarn_held else "loose", _score])
	if _score >= 3:
		_finish(true)

func _on_yarn_entered(body: Node) -> void:
	if body == player or (body is Node and body.is_in_group("player")):
		_yarn_held = true
		if _yarn:
			_yarn.visible = false
		NotificationUI.notify_info("Yarn secured — run it home.")

func _on_goal_entered(body: Node) -> void:
	if not _yarn_held:
		return
	if body == player or (body is Node and body.is_in_group("player")):
		_yarn_held = false
		_score += 1
		if _yarn:
			_yarn.visible = true
			_yarn.global_position = Vector3(18, 1, randf_range(-8, 8))
		NotificationUI.notify_win("Delivered! (%d/3)" % _score)

# ── Duel / 2v2 ─────────────────────────────────────────────────────────────
func _setup_duel() -> void:
	var foes := 1 if mode_id == "duel" else 2
	_spawn_ferals(foes, 2)
	if mode_id == "duel_2v2":
		# Ally marker — decorative companion stand-in near the player.
		var ally := _make_marker(player.global_position + Vector3(-2, 0, 0), Color(0.4, 0.7, 1.0), "Ally")
		add_child(ally)
	NotificationUI.notify_info("Duel — defeat the staged opponent(s).")

func _tick_duel() -> void:
	_prune_dead()
	_refresh_hud("foes left %d" % _alive.size())
	if _alive.is_empty() and _elapsed > 1.0:
		_score = 100
		_finish(true)

# ── Shared helpers ─────────────────────────────────────────────────────────
func _spawn_ferals(count: int, stage: int) -> void:
	for i in range(count):
		var line := EntityDexData.random_line("Factionless")
		if line.is_empty():
			line = {"id": "feral_%d" % i, "faction": "Factionless", "category": "Entropy", "stages": [{"name": "Feral", "desc": ""}]}
		var ent := WorldEntity.new()
		add_child(ent)
		var angle := TAU * float(i) / float(maxi(count, 1))
		var radius := 12.0 + randf() * 10.0
		ent.global_position = Vector3(cos(angle) * radius, 0.5, sin(angle) * radius)
		ent.setup(line, stage, player)
		if not ent.died.is_connected(_on_feral_died):
			ent.died.connect(_on_feral_died)
		_alive.append(ent)

func _on_feral_died(ent: WorldEntity) -> void:
	_alive.erase(ent)
	_score += 10 * ent.stage_num

func _prune_dead() -> void:
	var keep: Array[Node] = []
	for n in _alive:
		if is_instance_valid(n):
			keep.append(n)
	_alive = keep

func _make_pickup(pos: Vector3, color: Color, node_name: String) -> Area3D:
	var area := Area3D.new()
	area.name = node_name
	area.monitoring = true
	area.monitorable = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.4
	shape.shape = sphere
	area.add_child(shape)
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.7
	mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mesh.material_override = mat
	area.add_child(mesh)
	area.position = pos
	add_child(area)
	return area

func _make_marker(pos: Vector3, color: Color, node_name: String) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = pos
	var mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.4
	mesh.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	root.add_child(mesh)
	return root

func _finish(won: bool) -> void:
	if not _running:
		return
	_running = false
	_refresh_hud("FINISHED")
	if won:
		var payout := 40 + _score / 2
		EconomyManager.earn_currency("tokens", payout, "arena_%s" % mode_id)
		CrownManager.add_score("Top Arena Victories", "local_player", 1, PlayerProfile.faction)
		EconomyManager.earn_prestige(10, "arena_win")
		NotificationUI.notify_win("%s cleared — +%d ⚔️ tokens" % [mode_id, payout])
		mode_won.emit(mode_id, _score)
	else:
		EconomyManager.earn_prestige(3, "arena_loss")
		NotificationUI.notify_error("%s failed — the arena remembers (+3 🌟)." % mode_id)
		mode_lost.emit(mode_id)
