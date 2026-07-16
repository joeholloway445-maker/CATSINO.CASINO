class_name ArenaModeController
extends Node3D
## Mode-specific arena rules for playtest_arena.
## survival / zombies / ctf / duel / duel_2v2 / conflict / moba.
## Shared hero HP + auto-attack so every mode is win/lose playable offline.

signal mode_won(mode_id: String, score: int)
signal mode_lost(mode_id: String)

var mode_id: String = ""
var player: Node3D
var _hud: Label
var _elapsed := 0.0
var _score := 0
var _alive: Array[Node] = []
var _allies: Array[Node] = []
var _wave := 0
var _zone_radius := 42.0
var _zone_visual: MeshInstance3D
var _yarn: Area3D
var _yarn_held := false
var _goal: Area3D
var _running := true
var _hero_hp := 120
var _hero_max_hp := 120
var _zone_dmg_acc := 0.0
var _attack_cd := 0.0
var _enemy_score := 0
var _moba: Node

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
		"conflict":
			_setup_conflict()
		"moba":
			_setup_moba()
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
	_hud.text = "%s | HP %d/%d | score %d | %s" % [
		mode_id.to_upper(), _hero_hp, _hero_max_hp, _score, extra]

func _process(delta: float) -> void:
	if not _running or player == null:
		return
	_elapsed += delta
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	if mode_id != "moba":
		_tick_hero_combat(delta)
	match mode_id:
		"survival":
			_tick_survival(delta)
		"zombies":
			_tick_zombies(delta)
		"ctf":
			_tick_ctf(delta)
		"duel", "duel_2v2":
			_tick_duel(delta)
		"conflict":
			_tick_conflict(delta)
		"moba":
			_tick_moba(delta)

func _tick_hero_combat(_delta: float) -> void:
	# Auto-attack nearest feral in range; take bites via WorldEntity signal.
	if _attack_cd <= 0.0:
		var target := _nearest_feral(3.4)
		if target != null and target.has_method("take_hit"):
			target.take_hit(14)
			_attack_cd = 0.75

func _nearest_feral(within: float) -> Node:
	var best: Node = null
	var best_d: float = within
	for n in _alive:
		if not is_instance_valid(n):
			continue
		var d: float = player.global_position.distance_to((n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n
	return best

func _on_bit(amount: int) -> void:
	if not _running:
		return
	_hero_hp = maxi(0, _hero_hp - amount)
	if _hero_hp <= 0:
		_finish(false)

# ── Survival ───────────────────────────────────────────────────────────────
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
	NotificationUI.notify_info("Last Cat Standing — stay in the ring. Survive 90s.")

func _tick_survival(delta: float) -> void:
	_zone_radius = maxf(8.0, 42.0 - _elapsed * 0.55)
	if _zone_visual and _zone_visual.mesh is CylinderMesh:
		var cyl := _zone_visual.mesh as CylinderMesh
		cyl.top_radius = _zone_radius
		cyl.bottom_radius = _zone_radius
	var flat := Vector2(player.global_position.x, player.global_position.z)
	if flat.length() > _zone_radius:
		_zone_dmg_acc += delta * 18.0
		while _zone_dmg_acc >= 1.0:
			_zone_dmg_acc -= 1.0
			_hero_hp = maxi(0, _hero_hp - 1)
		_refresh_hud("OUTSIDE ZONE")
		if _hero_hp <= 0:
			_finish(false)
			return
	else:
		_score += int(delta * 2)
		_refresh_hud("safe r=%.0f" % _zone_radius)
	_prune_dead()
	if _elapsed >= 90.0:
		_finish(true)
	elif _alive.is_empty() and _elapsed > 5.0:
		_spawn_ferals(3 + int(_elapsed / 30.0), mini(3, 1 + int(_elapsed / 40.0)))

# ── Zombies ────────────────────────────────────────────────────────────────
func _setup_zombies() -> void:
	_wave = 0
	_hero_max_hp = 140
	_hero_hp = 140
	# Ally bots for "co-op of 4"
	for i in range(3):
		_spawn_ally_bot(player.global_position + Vector3(-2.0 + i, 0, -2.0))
	_next_wave()
	NotificationUI.notify_info("Feral Horde — clear 5 waves with your squad.")

func _tick_zombies(delta: float) -> void:
	_prune_dead()
	_drive_allies(delta)
	_refresh_hud("wave %d · left %d · allies %d" % [_wave, _alive.size(), _count_valid(_allies)])
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

# ── CTF ────────────────────────────────────────────────────────────────────
func _setup_ctf() -> void:
	_yarn = _make_pickup(Vector3(18, 1, 0), Color(1.0, 0.85, 0.2), "YarnBall")
	_goal = _make_pickup(Vector3(-18, 1, 0), Color(0.3, 1.0, 0.45), "Goal")
	_yarn.body_entered.connect(_on_yarn_entered)
	_goal.body_entered.connect(_on_goal_entered)
	_spawn_ferals(4, 1)
	_spawn_ally_bot(player.global_position + Vector3(-2, 0, 1))
	NotificationUI.notify_info("Yarn Rush — deliver 3 before foes score 3. 120s clock.")

func _tick_ctf(delta: float) -> void:
	_prune_dead()
	_drive_allies(delta)
	# Distance-based pickup/deliver — works even if Area3D layers miss the player.
	if not _yarn_held and _yarn and is_instance_valid(_yarn):
		if player.global_position.distance_to(_yarn.global_position) < 2.0:
			_on_yarn_entered(player)
		else:
			for n in _alive:
				if not is_instance_valid(n):
					continue
				if (n as Node3D).global_position.distance_to(_yarn.global_position) < 1.8:
					_enemy_score += 1
					_yarn.global_position = Vector3(18, 1, randf_range(-8, 8))
					NotificationUI.notify_error("Feral stole a delivery! (%d/3)" % _enemy_score)
					break
	elif _yarn_held and _goal and is_instance_valid(_goal):
		if player.global_position.distance_to(_goal.global_position) < 2.2:
			_on_goal_entered(player)
	_refresh_hud("you %d · foes %d · %s · t=%.0f" % [
		_score, _enemy_score, "HELD" if _yarn_held else "loose", 120.0 - _elapsed])
	if _score >= 3:
		_finish(true)
	elif _enemy_score >= 3 or _elapsed >= 120.0:
		_finish(false)

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

# ── Duel ───────────────────────────────────────────────────────────────────
func _setup_duel() -> void:
	var foes := 1 if mode_id == "duel" else 2
	_spawn_ferals(foes, 2)
	if mode_id == "duel_2v2":
		_spawn_ally_bot(player.global_position + Vector3(-2, 0, 0))
	NotificationUI.notify_info("Duel — defeat the opponent(s). Don't die.")

func _tick_duel(delta: float) -> void:
	_prune_dead()
	_drive_allies(delta)
	_refresh_hud("foes left %d" % _alive.size())
	if _alive.is_empty() and _elapsed > 1.0:
		_score = 100
		_finish(true)

# ── Conflict (faction war warm-up) ─────────────────────────────────────────
func _setup_conflict() -> void:
	_hero_max_hp = 160
	_hero_hp = 160
	# 4 allies vs 8 enemies — scaled warm-up for team_size 12
	for i in range(4):
		_spawn_ally_bot(Vector3(-8 + i * 2.0, 0.5, -4 + (i % 2)))
	_spawn_ferals(8, 2)
	NotificationUI.notify_info("Faction Conflict — wipe the rival pack with your alliance.")

func _tick_conflict(delta: float) -> void:
	_prune_dead()
	_drive_allies(delta)
	_refresh_hud("rivals %d · allies %d" % [_alive.size(), _count_valid(_allies)])
	if _alive.is_empty() and _elapsed > 2.0:
		_score = 200
		_finish(true)
	elif _count_valid(_allies) == 0 and _hero_hp <= 0:
		_finish(false)

# ── MOBA ───────────────────────────────────────────────────────────────────
func _setup_moba() -> void:
	var online_id := ""
	if Engine.has_meta("moba_online_match_id"):
		online_id = str(Engine.get_meta("moba_online_match_id"))
		Engine.remove_meta("moba_online_match_id")
	if online_id != "":
		var online := MobaOnlineClient.new()
		online.name = "MobaOnlineClient"
		add_child(online)
		online.match_won.connect(func(s: int):
			_score = maxi(_score, s)
			_finish(true))
		online.match_lost.connect(func(): _finish(false))
		online.score_changed.connect(func(s: int): _score = s)
		_moba = online
		online.start(player, online_id)
		return
	var local := MobaMatch.new()
	local.name = "MobaMatch"
	add_child(local)
	local.match_won.connect(func(s: int):
		_score = maxi(_score, s)
		_finish(true))
	local.match_lost.connect(func(): _finish(false))
	local.score_changed.connect(func(s: int): _score = s)
	_moba = local
	local.start(player)

func _tick_moba(_delta: float) -> void:
	if _moba != null and _moba.has_method("hud_line"):
		_refresh_hud(_moba.hud_line())

# ── Allies / ferals ────────────────────────────────────────────────────────
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
		if not ent.bit_player.is_connected(_on_bit):
			ent.bit_player.connect(_on_bit)
		_alive.append(ent)

func _spawn_ally_bot(pos: Vector3) -> void:
	var bot := Node3D.new()
	bot.name = "AllyBot"
	add_child(bot)
	bot.global_position = pos
	var mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.4
	cap.height = 1.3
	mesh.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.75, 1.0)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mesh.material_override = mat
	mesh.position.y = 0.8
	bot.add_child(mesh)
	var hp_lbl := Label3D.new()
	hp_lbl.name = "HpLabel"
	hp_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_lbl.position.y = 1.9
	hp_lbl.font_size = 28
	hp_lbl.outline_size = 4
	hp_lbl.modulate = Color(0.55, 0.9, 1.0)
	hp_lbl.text = "ALLY 80/80"
	bot.add_child(hp_lbl)
	bot.set_meta("hp", 80)
	bot.set_meta("max_hp", 80)
	bot.set_meta("atk_cd", 0.0)
	_allies.append(bot)

func _drive_allies(delta: float) -> void:
	for bot in _allies:
		if not is_instance_valid(bot):
			continue
		var hp: int = int(bot.get_meta("hp", 0))
		var max_hp: int = int(bot.get_meta("max_hp", 80))
		if hp <= 0:
			bot.queue_free()
			continue
		var cd: float = float(bot.get_meta("atk_cd", 0.0))
		cd = maxf(cd - delta, 0.0)
		bot.set_meta("atk_cd", cd)
		var hp_lbl := bot.get_node_or_null("HpLabel") as Label3D
		if hp_lbl:
			hp_lbl.text = "ALLY %d/%d" % [hp, max_hp]
		var target := _weakest_in_range(bot as Node3D, _alive, 14.0)
		if target == null:
			# Stick with the player when no foe is in range.
			if player != null and is_instance_valid(player):
				var to_p: Vector3 = player.global_position - (bot as Node3D).global_position
				to_p.y = 0.0
				if to_p.length() > 3.0:
					(bot as Node3D).global_position += to_p.normalized() * 4.2 * delta
			continue
		var to: Vector3 = (target as Node3D).global_position - (bot as Node3D).global_position
		to.y = 0.0
		var d: float = to.length()
		if d > 2.4:
			(bot as Node3D).global_position += to.normalized() * 3.8 * delta
		elif cd <= 0.0 and target.has_method("take_hit"):
			target.take_hit(10)
			SkillVFX.hit_spark(self, (target as Node3D).global_position)
			bot.set_meta("atk_cd", 0.9)
		# Feral proximity damages allies lightly
		if d < 2.2:
			bot.set_meta("hp", hp - int(ceil(6.0 * delta)))

func _nearest_to(from: Node3D, pool: Array[Node], within: float) -> Node:
	var best: Node = null
	var best_d: float = within
	for n in pool:
		if not is_instance_valid(n):
			continue
		var d: float = from.global_position.distance_to((n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n
	return best

## Prefer the wounded feral so 2v2 focus-fire finishes kills.
func _weakest_in_range(from: Node3D, pool: Array[Node], within: float) -> Node:
	var best: Node = null
	var best_hp := 1_000_000
	var best_d := within
	for n in pool:
		if not is_instance_valid(n):
			continue
		var d: float = from.global_position.distance_to((n as Node3D).global_position)
		if d > within:
			continue
		var nhp := 9999
		if n is WorldEntity:
			nhp = (n as WorldEntity).hp
		elif n.has_method("get") and n.get("hp") != null:
			nhp = int(n.get("hp"))
		if nhp < best_hp or (nhp == best_hp and d < best_d):
			best_hp = nhp
			best_d = d
			best = n
	return best

func _on_feral_died(ent: WorldEntity) -> void:
	_alive.erase(ent)
	_score += 10 * ent.stage_num

func _prune_dead() -> void:
	var keep: Array[Node] = []
	for n in _alive:
		if is_instance_valid(n):
			keep.append(n)
	_alive = keep
	var allies: Array[Node] = []
	for n in _allies:
		if is_instance_valid(n) and int(n.get_meta("hp", 0)) > 0:
			allies.append(n)
	_allies = allies

func _count_valid(arr: Array[Node]) -> int:
	var n := 0
	for x in arr:
		if is_instance_valid(x):
			n += 1
	return n

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
	# CharacterBody3D players need collision layers — also poll distance each tick for CTF
	return area

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
	_sync_online_result(won)

func _sync_online_result(won: bool) -> void:
	## When queued via find_match, push a leaderboard score so online play is recorded.
	if not Engine.has_meta("arena_online_match_id"):
		return
	if not NetworkManager or not NetworkManager.is_connected_to_server():
		return
	var match_id := str(Engine.get_meta("arena_online_match_id"))
	var score_val := _score + (1000 if won else 0)
	NetworkManager.call_rpc("submit_score", {
		"leaderboard": "all_time_wins",
		"score": score_val,
		"subscore": 1 if won else 0,
		"match_id": match_id,
		"mode": mode_id,
	}, func(r: Dictionary):
		if r.get("success", false) or r.get("ok", false):
			NotificationUI.notify_info("Online result synced.")
		if Engine.has_meta("arena_online_match_id"):
			Engine.remove_meta("arena_online_match_id")
	)
