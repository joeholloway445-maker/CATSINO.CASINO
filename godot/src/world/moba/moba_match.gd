class_name MobaMatch
extends Node3D
## Full offline Paws of the Ancients match:
## 3 lanes · towers · inhibitors · nexus (backdoor lock) · wave composition
## · hero bots · companion summon · fountain/recall/respawn · XP/levels
## · CS/KDA · base-only shop with sellback · HUD/minimap/kill feed.

signal match_won(score: int)
signal match_lost()
signal score_changed(score: int)

const WAVE_INTERVAL := 18.0
const HERO_BASE_ATTACK_CD := 0.85
const FOUNTAIN_RADIUS := 7.5
const FOUNTAIN_HEAL_PER_SEC := 28.0
const RECALL_CHANNEL := 4.0
const BASE_RESPAWN := 8.0
const LANE_Z := [-14.0, 0.0, 14.0]
const ALLY_FOUNTAIN := Vector3(-32, 0.5, 0)
const ENEMY_FOUNTAIN := Vector3(32, 0.5, 0)

var player: Node3D
var shop := MobaShop.new()
var score := 0
var _running := true
var _elapsed := 0.0
var _wave_timer := 0.0
var _wave := 0
var _hero_attack_cd := 0.0
var _hero_alive := true
var _respawn_left := 0.0
var _recall_left := -1.0
var _recall_origin := Vector3.ZERO
var _shop_ui: MobaShopUI
var _hud: MobaHud
var _feed_cooldown := {}
var _ally_towers: Array = [] # per lane
var _enemy_towers: Array = []
var _ally_inhibs: Array = []
var _enemy_inhibs: Array = []
var _ally_nexus: MobaTower
var _enemy_nexus: MobaTower
var _lane_paths: Array = []
var _super_lanes_enemy: Dictionary = {} # lane_id -> true while inhib down
var _super_lanes_ally: Dictionary = {}

func start(p_player: Node3D) -> void:
	player = p_player
	if player:
		player.global_position = ALLY_FOUNTAIN + Vector3(2, 0, 0)
	_build_field()
	_build_ui()
	_spawn_bots()
	_spawn_companion()
	shop.grant_gold(150, "start")
	_spawn_wave()
	_hud.show_banner("Paws of the Ancients", 2.5)
	NotificationUI.notify_info("B shop (fountain) · R recall · last-hit for gold · drop the nexus")

func hero_is_alive() -> bool:
	return _hero_alive and _running

func lane_tower_alive(team: String, lane_id: int) -> bool:
	var arr: Array = _ally_towers if team == "ally" else _enemy_towers
	if lane_id < 0 or lane_id >= arr.size():
		return false
	var t = arr[lane_id]
	return is_instance_valid(t) and t.is_alive()

func ping_feed(text: String) -> void:
	var key := text
	var now: float = Time.get_ticks_msec() / 1000.0
	if _feed_cooldown.get(key, 0.0) > now:
		return
	_feed_cooldown[key] = now + 2.5
	if _hud:
		_hud.push_feed(text, Color(1.0, 0.85, 0.4))

func grant_xp_near(origin: Vector3, amount: int, dead_team: String) -> void:
	# XP goes to the opposing team of the dead unit.
	var gain_team := "ally" if dead_team == "enemy" else "enemy"
	if gain_team == "ally" and hero_is_alive() and player:
		if player.global_position.distance_to(origin) <= MobaMinion.XP_RADIUS:
			shop.add_xp(amount)

func on_hero_bot_killed(bot: MobaHeroBot, killer: Node) -> void:
	if not _running:
		return
	if bot.team == "enemy":
		var player_kill: bool = killer != null and (killer == player or killer.is_in_group("player"))
		var near: bool = player != null and hero_is_alive() and player.global_position.distance_to(bot.global_position) <= 14.0
		if player_kill:
			shop.grant_gold(bot.gold_bounty, "hero")
			shop.hero.kills = int(shop.hero.kills) + 1
			shop.add_xp(bot.xp_bounty)
			score += 40
			score_changed.emit(score)
			MobaFx.gold_float(self, bot.global_position, bot.gold_bounty)
			if _hud:
				_hud.push_feed("You slew %s (+%dg)" % [bot.display_name, bot.gold_bounty], Color(1.0, 0.75, 0.3))
		elif near:
			var assist_gold: int = maxi(10, bot.gold_bounty / 3)
			shop.grant_gold(assist_gold, "assist")
			shop.hero.assists = int(shop.hero.assists) + 1
			shop.add_xp(maxi(10, bot.xp_bounty / 3))
			if _hud:
				_hud.push_feed("Assist on %s (+%dg)" % [bot.display_name, assist_gold], Color(0.75, 0.9, 1.0))
	elif bot.team == "ally" and not bot.is_companion:
		if _hud:
			_hud.push_feed("%s fell" % bot.display_name, Color(0.7, 0.8, 1.0))
	# Respawn bots after a delay
	if not bot.is_companion:
		var lane := bot.lane_id
		var team := bot.team
		var nm := bot.display_name
		get_tree().create_timer(12.0).timeout.connect(func():
			if _running:
				_spawn_one_bot(team, lane, nm))

func hud_line() -> String:
	return "W%d · %s · R recall · B shop" % [_wave, "LIVE" if _hero_alive else "DEAD"]

# ── Build ──────────────────────────────────────────────────────────────────

func _build_field() -> void:
	_lane_paths.clear()
	_ally_towers.clear()
	_enemy_towers.clear()
	_ally_inhibs.clear()
	_enemy_inhibs.clear()
	# Fountains
	_make_fountain(ALLY_FOUNTAIN, Color(0.3, 0.7, 1.0), "AllyFountain")
	_make_fountain(ENEMY_FOUNTAIN, Color(1.0, 0.35, 0.35), "EnemyFountain")
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
		# Outer towers
		var at := MobaTower.new()
		at.name = "AllyTower_%d" % i
		add_child(at)
		at.global_position = Vector3(-16, 0, z)
		at.configure("ally", MobaTower.Kind.TOWER, i, self)
		at.destroyed.connect(_on_tower_destroyed)
		_ally_towers.append(at)
		var et := MobaTower.new()
		et.name = "EnemyTower_%d" % i
		add_child(et)
		et.global_position = Vector3(16, 0, z)
		et.configure("enemy", MobaTower.Kind.TOWER, i, self)
		et.destroyed.connect(_on_tower_destroyed)
		_enemy_towers.append(et)
		# Inhibitors
		var ai := MobaTower.new()
		ai.name = "AllyInhib_%d" % i
		add_child(ai)
		ai.global_position = Vector3(-24, 0, z)
		ai.configure("ally", MobaTower.Kind.INHIBITOR, i, self)
		ai.destroyed.connect(_on_tower_destroyed)
		_ally_inhibs.append(ai)
		var ei := MobaTower.new()
		ei.name = "EnemyInhib_%d" % i
		add_child(ei)
		ei.global_position = Vector3(24, 0, z)
		ei.configure("enemy", MobaTower.Kind.INHIBITOR, i, self)
		ei.destroyed.connect(_on_tower_destroyed)
		_enemy_inhibs.append(ei)
		# Lane paint
		var strip := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(58, 0.05, 2.2)
		strip.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.18, 0.22, 0.55)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		strip.material_override = mat
		strip.position = Vector3(0, 0.02, z)
		add_child(strip)
	_ally_nexus = MobaTower.new()
	_ally_nexus.name = "AllyNexus"
	add_child(_ally_nexus)
	_ally_nexus.global_position = Vector3(-30, 0, 0)
	_ally_nexus.configure("ally", MobaTower.Kind.NEXUS, -1, self)
	_ally_nexus.destroyed.connect(_on_tower_destroyed)
	_enemy_nexus = MobaTower.new()
	_enemy_nexus.name = "EnemyNexus"
	add_child(_enemy_nexus)
	_enemy_nexus.global_position = Vector3(30, 0, 0)
	_enemy_nexus.configure("enemy", MobaTower.Kind.NEXUS, -1, self)
	_enemy_nexus.destroyed.connect(_on_tower_destroyed)
	_refresh_nexus_lock()

func _make_fountain(pos: Vector3, color: Color, node_name: String) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var cyl := CylinderMesh.new()
	cyl.top_radius = FOUNTAIN_RADIUS
	cyl.bottom_radius = FOUNTAIN_RADIUS
	cyl.height = 0.15
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.8
	mesh.material_override = mat
	mesh.position = pos
	add_child(mesh)

func _build_ui() -> void:
	_hud = MobaHud.new()
	_hud.name = "MobaHud"
	add_child(_hud)
	_hud.setup(shop, self)
	_shop_ui = MobaShopUI.new()
	_shop_ui.name = "MobaShopUI"
	add_child(_shop_ui)
	_shop_ui.setup(shop, Callable(self, "at_fountain"))
	var open_btn := Button.new()
	open_btn.text = "Shop (B)"
	open_btn.position = Vector2(24, 52)
	open_btn.pressed.connect(_shop_ui.toggle)
	var layer := CanvasLayer.new()
	layer.layer = 19
	add_child(layer)
	layer.add_child(open_btn)

func at_fountain() -> bool:
	if player == null or not _hero_alive:
		return false
	return player.global_position.distance_to(ALLY_FOUNTAIN) <= FOUNTAIN_RADIUS + 1.5

# ── Bots / companion ───────────────────────────────────────────────────────

func _spawn_bots() -> void:
	# 2 ally lane bots + 2 enemy lane bots (player fills mid carry).
	_spawn_one_bot("ally", 0, "Ally Top")
	_spawn_one_bot("ally", 2, "Ally Bot")
	_spawn_one_bot("enemy", 0, "Enemy Top")
	_spawn_one_bot("enemy", 1, "Enemy Mid")
	_spawn_one_bot("enemy", 2, "Enemy Bot")

func _spawn_one_bot(team: String, lane: int, nm: String) -> void:
	if lane < 0 or lane >= _lane_paths.size():
		return
	var path: Array[Vector3] = []
	for p in _lane_paths[lane]:
		path.append(p as Vector3)
	var bot := MobaHeroBot.new()
	add_child(bot)
	var start: Vector3 = ALLY_FOUNTAIN if team == "ally" else ENEMY_FOUNTAIN
	bot.global_position = start + Vector3(0, 0, LANE_Z[lane] * 0.15)
	bot.configure(team, lane, path, nm, self, false)

func _spawn_companion() -> void:
	var companion_name := "Hopebound"
	if PlayerProfile and not PlayerProfile.active_companion_ids.is_empty():
		var cid := str(PlayerProfile.active_companion_ids[0])
		var entry: Dictionary = CompanionRegistry.get_by_id(cid)
		companion_name = str(entry.get("name", cid)) if not entry.is_empty() else cid
	var path: Array[Vector3] = []
	for p in _lane_paths[1]:
		path.append(p as Vector3)
	var bot := MobaHeroBot.new()
	add_child(bot)
	bot.global_position = ALLY_FOUNTAIN + Vector3(3, 0, 2)
	bot.configure("ally", 1, path, companion_name, self, true)
	if _hud:
		_hud.push_feed("Companion %s joins the fray" % companion_name, Color(0.55, 0.95, 0.7))

# ── Input / ticks ──────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			_shop_ui.toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			_begin_recall()
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if not _running:
		return
	_elapsed += delta
	shop.tick_passive(delta)
	_wave_timer += delta
	if _wave_timer >= WAVE_INTERVAL:
		_wave_timer = 0.0
		_spawn_wave()
	if not _hero_alive:
		_respawn_left -= delta
		if _hud:
			_hud.set_respawn(_respawn_left)
		if _respawn_left <= 0.0:
			_do_respawn()
		return
	if player == null:
		return
	# Fountain heal
	if at_fountain():
		shop.hero.hp = mini(int(shop.hero.max_hp), int(shop.hero.hp) + int(ceil(FOUNTAIN_HEAL_PER_SEC * delta)))
	# Recall channel
	if _recall_left >= 0.0:
		_tick_recall(delta)
	_hero_attack_cd = maxf(_hero_attack_cd - delta, 0.0)
	if _hero_attack_cd <= 0.0:
		_try_hero_attack()

func _begin_recall() -> void:
	if not _hero_alive or at_fountain():
		return
	_recall_left = RECALL_CHANNEL
	_recall_origin = player.global_position
	if _hud:
		_hud.set_recall(0.0)

func _tick_recall(delta: float) -> void:
	# Cancel if moved or damaged recently (movement check).
	if player.global_position.distance_to(_recall_origin) > 0.6:
		_recall_left = -1.0
		if _hud:
			_hud.set_recall(-1.0)
		NotificationUI.notify_error("Recall cancelled — movement")
		return
	_recall_left -= delta
	if _hud:
		_hud.set_recall(1.0 - (_recall_left / RECALL_CHANNEL))
	if _recall_left <= 0.0:
		_recall_left = -1.0
		player.global_position = ALLY_FOUNTAIN + Vector3(1, 0, 0)
		if _hud:
			_hud.set_recall(-1.0)
			_hud.show_banner("Recalled", 1.2)
		NotificationUI.notify_info("Back at fountain.")

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
	# Lifesteal
	var ls: float = float(shop.hero.get("lifesteal", 0.0))
	if ls > 0.0:
		shop.hero.hp = mini(int(shop.hero.max_hp), int(shop.hero.hp) + int(round(float(dmg) * ls)))

func _nearest_enemy(within: float) -> Node3D:
	var best: Node3D = null
	var best_d: float = within
	for n in get_tree().get_nodes_in_group("moba_unit"):
		if not is_instance_valid(n):
			continue
		if str(n.get("team")) == "ally":
			continue
		if n.has_method("is_alive") and not n.is_alive():
			continue
		var d: float = player.global_position.distance_to((n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n as Node3D
	return best

func hero_take_hit(amount: int, _attacker: Node = null) -> void:
	if not _running or not _hero_alive:
		return
	# Cancel recall on damage
	if _recall_left >= 0.0:
		_recall_left = -1.0
		if _hud:
			_hud.set_recall(-1.0)
		NotificationUI.notify_error("Recall cancelled — damage")
	var mitigated: int = maxi(1, amount - int(shop.hero.armor))
	shop.hero.hp = maxi(0, int(shop.hero.hp) - mitigated)
	MobaFx.damage_float(self, player.global_position, mitigated, false)
	if int(shop.hero.hp) <= 0:
		_on_hero_death()

func _on_hero_death() -> void:
	_hero_alive = false
	shop.hero.deaths = int(shop.hero.deaths) + 1
	_respawn_left = BASE_RESPAWN + float(int(shop.hero.level)) * 1.5
	if player:
		player.visible = false
	if _shop_ui and _shop_ui.is_open():
		_shop_ui.close()
	if _hud:
		_hud.push_feed("You died", Color(1.0, 0.4, 0.4))
		_hud.set_respawn(_respawn_left)

func _do_respawn() -> void:
	_hero_alive = true
	shop.hero.hp = int(shop.hero.max_hp)
	if player:
		player.visible = true
		player.global_position = ALLY_FOUNTAIN + Vector3(2, 0, 0)
	if _hud:
		_hud.set_respawn(0.0)
		_hud.show_banner("Respawned", 1.2)

# ── Waves ──────────────────────────────────────────────────────────────────

func _spawn_wave() -> void:
	_wave += 1
	var siege_wave: bool = (_wave % 3) == 0
	for lane in range(3):
		var path: Array[Vector3] = []
		for p in _lane_paths[lane]:
			path.append(p as Vector3)
		_spawn_lane_wave("ally", lane, path, siege_wave, _super_lanes_ally.get(lane, false))
		_spawn_lane_wave("enemy", lane, path, siege_wave, _super_lanes_enemy.get(lane, false))
	if _hud:
		_hud.push_feed("Wave %d" % _wave, Color(0.8, 0.85, 1.0))

func _spawn_lane_wave(team: String, lane: int, path: Array[Vector3], siege: bool, supers: bool) -> void:
	var kinds: Array = [MobaMinion.Kind.MELEE, MobaMinion.Kind.MELEE, MobaMinion.Kind.CASTER]
	if siege:
		kinds.append(MobaMinion.Kind.SIEGE)
	if supers:
		kinds.append(MobaMinion.Kind.SUPER)
	var base_x: float = -26.0 if team == "ally" else 26.0
	var dir: float = -1.0 if team == "ally" else 1.0
	for k in kinds.size():
		var m := MobaMinion.new()
		add_child(m)
		m.global_position = Vector3(base_x + dir * float(k) * 1.35, 0.5, LANE_Z[lane] + randf_range(-0.5, 0.5))
		m.configure(team, lane, path, kinds[k], self)
		m.died.connect(_on_minion_died)

func _on_minion_died(minion: MobaMinion, bounty: int, last_hit_by: Node) -> void:
	if not _running:
		return
	if minion.team != "enemy":
		return
	var player_last: bool = last_hit_by != null and (last_hit_by == player or last_hit_by.is_in_group("player"))
	if player_last:
		shop.grant_gold(bounty, "cs")
		shop.hero.cs = int(shop.hero.cs) + 1
		score += 5
		score_changed.emit(score)
		MobaFx.gold_float(self, minion.global_position, bounty)
	elif last_hit_by != null and last_hit_by.is_in_group("moba_hero") and str(last_hit_by.get("team")) == "ally":
		# Assist gold for being nearby
		if player and hero_is_alive() and player.global_position.distance_to(minion.global_position) < 12.0:
			var share: int = maxi(1, bounty / 4)
			shop.grant_gold(share, "assist_cs")
			shop.hero.assists = int(shop.hero.assists) + 0 # CS assist doesn't bump KDA
	else:
		# Participation gold if nearby even without last hit
		if player and hero_is_alive() and player.global_position.distance_to(minion.global_position) < 10.0:
			shop.grant_gold(maxi(1, bounty / 5), "proximity")

func _on_tower_destroyed(tower: MobaTower) -> void:
	if not _running:
		return
	if tower.team == "enemy":
		var bounty: int = 70
		match tower.kind:
			MobaTower.Kind.INHIBITOR:
				bounty = 100
				_super_lanes_enemy[tower.lane_id] = true
				if _hud:
					_hud.push_feed("Enemy inhibitor down — supers inbound!", Color(1.0, 0.7, 0.3))
			MobaTower.Kind.NEXUS:
				bounty = 200
			_:
				bounty = 70
		shop.grant_gold(bounty, "structure")
		score += 25 if tower.kind == MobaTower.Kind.TOWER else 50
		score_changed.emit(score)
		MobaFx.gold_float(self, tower.global_position, bounty)
		if _hud:
			_hud.push_feed("Structure down (+%dg)" % bounty, Color(1.0, 0.85, 0.4))
		if tower.kind == MobaTower.Kind.NEXUS:
			_finish(true)
			return
	else:
		if tower.kind == MobaTower.Kind.INHIBITOR:
			_super_lanes_ally[tower.lane_id] = true
			if _hud:
				_hud.push_feed("Our inhibitor fell!", Color(1.0, 0.45, 0.45))
		elif tower.kind == MobaTower.Kind.NEXUS:
			_finish(false)
			return
		elif _hud:
			_hud.push_feed("Ally tower lost", Color(1.0, 0.55, 0.55))
	_refresh_nexus_lock()

func _refresh_nexus_lock() -> void:
	var enemy_towers_live: int = 0
	for t in _enemy_towers:
		if is_instance_valid(t) and t.is_alive():
			enemy_towers_live += 1
	var ally_towers_live: int = 0
	for t in _ally_towers:
		if is_instance_valid(t) and t.is_alive():
			ally_towers_live += 1
	if _enemy_nexus and is_instance_valid(_enemy_nexus):
		_enemy_nexus.set_invulnerable(enemy_towers_live > 0)
	if _ally_nexus and is_instance_valid(_ally_nexus):
		_ally_nexus.set_invulnerable(ally_towers_live > 0)

func _finish(won: bool) -> void:
	if not _running:
		return
	_running = false
	if _shop_ui:
		_shop_ui.close()
	var summary := "Lv%d  %d/%d/%d  CS %d  Gold %d  Time %.0fs" % [
		int(shop.hero.level), int(shop.hero.kills), int(shop.hero.deaths),
		int(shop.hero.assists), int(shop.hero.cs), shop.gold, _elapsed,
	]
	if _hud:
		_hud.show_banner(("VICTORY\n" if won else "DEFEAT\n") + summary, 5.0)
		_hud.push_feed(summary, Color(1, 1, 1))
	if won:
		match_won.emit(score)
	else:
		match_lost.emit()
