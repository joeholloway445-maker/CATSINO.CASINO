class_name MobaMatch
extends Node3D
## Full Paws of the Ancients match: lanes, wave AI, towers/nexus, hero
## auto-attack, and in-match item shop. Owned by ArenaModeController.

signal match_won(score: int)
signal match_lost()
signal score_changed(score: int)

const WAVE_INTERVAL := 18.0
const HERO_BASE_ATTACK_CD := 0.85
const LANE_Z := [-14.0, 0.0, 14.0]

var player: Node3D
var shop := MobaShop.new()
var score := 0
var _running := true
var _wave_timer := 0.0
var _wave := 0
var _hero_attack_cd := 0.0
var _shop_ui: MobaShopUI
var _ally_towers: Array[MobaTower] = []
var _enemy_towers: Array[MobaTower] = []
var _ally_nexus: MobaTower
var _enemy_nexus: MobaTower
var _lane_paths: Array = [] # Array of Array[Vector3]

func start(p_player: Node3D) -> void:
	player = p_player
	_build_field()
	_build_shop_ui()
	shop.grant_gold(120, "start")
	_spawn_wave()
	NotificationUI.notify_info("Paws of the Ancients — push lanes, buy items (B), drop the enemy nexus.")

func _build_field() -> void:
	_lane_paths.clear()
	for i in range(3):
		var z: float = LANE_Z[i]
		var path: Array[Vector3] = [
			Vector3(-26, 0.5, z),
			Vector3(-12, 0.5, z),
			Vector3(0, 0.5, z),
			Vector3(12, 0.5, z),
			Vector3(26, 0.5, z),
		]
		_lane_paths.append(path)
		# Ally outer tower
		var at := MobaTower.new()
		at.name = "AllyTower_%d" % i
		add_child(at)
		at.global_position = Vector3(-16, 0, z)
		at.configure("ally", false)
		at.destroyed.connect(_on_tower_destroyed)
		_ally_towers.append(at)
		# Enemy outer tower
		var et := MobaTower.new()
		et.name = "EnemyTower_%d" % i
		add_child(et)
		et.global_position = Vector3(16, 0, z)
		et.configure("enemy", false)
		et.destroyed.connect(_on_tower_destroyed)
		_enemy_towers.append(et)
	_ally_nexus = MobaTower.new()
	_ally_nexus.name = "AllyNexus"
	add_child(_ally_nexus)
	_ally_nexus.global_position = Vector3(-30, 0, 0)
	_ally_nexus.configure("ally", true)
	_ally_nexus.destroyed.connect(_on_tower_destroyed)
	_enemy_nexus = MobaTower.new()
	_enemy_nexus.name = "EnemyNexus"
	add_child(_enemy_nexus)
	_enemy_nexus.global_position = Vector3(30, 0, 0)
	_enemy_nexus.configure("enemy", true)
	_enemy_nexus.destroyed.connect(_on_tower_destroyed)
	# Lane floor strips for readability
	for i in range(3):
		var strip := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(56, 0.05, 2.2)
		strip.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.18, 0.22, 0.55)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		strip.material_override = mat
		strip.position = Vector3(0, 0.02, LANE_Z[i])
		add_child(strip)

func _build_shop_ui() -> void:
	_shop_ui = MobaShopUI.new()
	_shop_ui.name = "MobaShopUI"
	add_child(_shop_ui)
	_shop_ui.setup(shop)
	var open_btn := Button.new()
	open_btn.text = "Shop (B)"
	open_btn.position = Vector2(24, 52)
	open_btn.pressed.connect(_shop_ui.toggle)
	var layer := CanvasLayer.new()
	layer.layer = 19
	add_child(layer)
	layer.add_child(open_btn)

func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			_shop_ui.toggle()
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if not _running or player == null:
		return
	_wave_timer += delta
	if _wave_timer >= WAVE_INTERVAL:
		_wave_timer = 0.0
		_spawn_wave()
	_hero_attack_cd = maxf(_hero_attack_cd - delta, 0.0)
	if _hero_attack_cd <= 0.0:
		_try_hero_attack()
	# Passive enemy minion / tower pressure already handled by unit AI.
	if int(shop.hero.hp) <= 0:
		_finish(false)

func hud_line() -> String:
	var et := _count_alive(_enemy_towers) + (1 if _enemy_nexus and _enemy_nexus.is_alive() else 0)
	var at := _count_alive(_ally_towers) + (1 if _ally_nexus and _ally_nexus.is_alive() else 0)
	return "wave %d · gold %d · HP %d/%d · towers E%d/A%d · dmg %d" % [
		_wave, shop.gold, int(shop.hero.hp), int(shop.hero.max_hp),
		et, at, int(shop.hero.damage),
	]

func hero_take_hit(amount: int, _attacker: Node = null) -> void:
	if not _running:
		return
	var mitigated := maxi(1, amount - int(shop.hero.armor))
	shop.hero.hp = maxi(0, int(shop.hero.hp) - mitigated)
	if int(shop.hero.hp) <= 0:
		_finish(false)

func _try_hero_attack() -> void:
	var target: Node3D = _nearest_enemy(float(shop.hero.get("attack_range", 3.2)))
	if target == null:
		return
	var cd: float = HERO_BASE_ATTACK_CD / maxf(float(shop.hero.get("attack_speed", 1.0)), 0.2)
	_hero_attack_cd = cd
	var dmg: int = int(shop.hero.get("damage", 14))
	if target.is_in_group("moba_tower"):
		dmg = int(round(float(dmg) * (1.0 + float(shop.hero.get("tower_mult", 0.0)))))
	if target.has_method("take_hit"):
		target.take_hit(dmg, player)

func _nearest_enemy(within: float) -> Node3D:
	var best: Node3D = null
	var best_d := within
	for n in get_tree().get_nodes_in_group("moba_unit"):
		if not is_instance_valid(n):
			continue
		if str(n.get("team")) == "ally":
			continue
		if n.has_method("is_alive") and not n.is_alive():
			continue
		var d := player.global_position.distance_to((n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n as Node3D
	return best

func _spawn_wave() -> void:
	_wave += 1
	for lane in range(3):
		var path: Array[Vector3] = []
		for p in _lane_paths[lane]:
			path.append(p as Vector3)
		for k in range(3):
			var ally := MobaMinion.new()
			add_child(ally)
			ally.global_position = Vector3(-26 - k * 1.4, 0.5, LANE_Z[lane] + randf_range(-0.6, 0.6))
			ally.configure("ally", lane, path)
			ally.died.connect(_on_minion_died)
			var enemy := MobaMinion.new()
			add_child(enemy)
			enemy.global_position = Vector3(26 + k * 1.4, 0.5, LANE_Z[lane] + randf_range(-0.6, 0.6))
			enemy.configure("enemy", lane, path)
			enemy.died.connect(_on_minion_died)
	NotificationUI.notify_info("Wave %d marching." % _wave)

func _on_minion_died(minion: MobaMinion, bounty: int) -> void:
	if not _running:
		return
	if minion.team == "enemy" and bounty > 0:
		shop.grant_gold(bounty, "minion")
		score += 5
		score_changed.emit(score)

func _on_tower_destroyed(tower: MobaTower) -> void:
	if not _running:
		return
	if tower.team == "enemy":
		var bounty := 120 if tower.is_nexus else 70
		shop.grant_gold(bounty, "tower")
		score += 50 if tower.is_nexus else 25
		score_changed.emit(score)
		NotificationUI.notify_win("%s down!" % ("Enemy nexus" if tower.is_nexus else "Tower"))
		if tower.is_nexus:
			_finish(true)
			return
	else:
		NotificationUI.notify_error("%s fell!" % ("Ally nexus" if tower.is_nexus else "Ally tower"))
		if tower.is_nexus:
			_finish(false)

func _count_alive(towers: Array[MobaTower]) -> int:
	var n := 0
	for t in towers:
		if is_instance_valid(t) and t.is_alive():
			n += 1
	return n

func _finish(won: bool) -> void:
	if not _running:
		return
	_running = false
	if _shop_ui:
		_shop_ui.close()
	if won:
		match_won.emit(score)
	else:
		match_lost.emit()
