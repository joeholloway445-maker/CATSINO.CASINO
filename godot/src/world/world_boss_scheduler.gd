extends Node
## Autoloaded as "WorldBossScheduler". Gate 6/8 — one Stage-3+ world boss.
## Offline: local 20-minute cadence. Online (Gate 8): Nakama shared schedule
## via get_world_boss_state / claim_world_boss_spawn / report_world_boss_kill.

signal boss_spawned(boss_id: String, pos: Vector3)
signal boss_defeated(boss_id: String)

const BOSS_INTERVAL_SEC := 20 * 60 # 20 minutes offline cadence
const BOSS_MAX_LIFETIME_SEC := 8 * 60 # despawn if ignored
const ONLINE_POLL_SEC := 8.0

var _active_boss: WorldEntity = null
var _boss_id := ""
var _zone_kills: Dictionary = {} # hub_id -> count
var _elapsed := 0.0
var _next_spawn_in := 90.0 # first spawn soon for playability
var _boss_alive_for := 0.0
var _online_poll_in := 2.0
var _online_mode := false
var _pending_rpc := false
var _online_soft_fails := 0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	_online_mode = NetworkManager != null and NetworkManager.is_connected_to_server()
	if _online_mode and _online_soft_fails < 3:
		_process_online(delta)
	else:
		_process_offline(delta)

func _process_offline(delta: float) -> void:
	if _active_boss != null:
		if not is_instance_valid(_active_boss):
			_active_boss = null
			_boss_id = ""
			_boss_alive_for = 0.0
			return
		_boss_alive_for += delta
		if _boss_alive_for >= BOSS_MAX_LIFETIME_SEC:
			NotificationUI.notify_info("The Metroplex Titan fades back into the skyline.")
			_active_boss.queue_free()
			_active_boss = null
			_boss_id = ""
			_boss_alive_for = 0.0
			_next_spawn_in = BOSS_INTERVAL_SEC
		return
	_elapsed += delta
	_next_spawn_in -= delta
	if _next_spawn_in <= 0.0:
		_spawn_world_boss({})
		_next_spawn_in = BOSS_INTERVAL_SEC

func _process_online(delta: float) -> void:
	if _active_boss != null and not is_instance_valid(_active_boss):
		_active_boss = null
		_boss_id = ""
		_boss_alive_for = 0.0
	if _active_boss != null:
		_boss_alive_for += delta
		if _boss_alive_for >= BOSS_MAX_LIFETIME_SEC:
			# Server will expire on next poll; clear local.
			NotificationUI.notify_info("The Metroplex Titan fades back into the skyline.")
			_active_boss.queue_free()
			_active_boss = null
			_boss_id = ""
			_boss_alive_for = 0.0
		return
	_online_poll_in -= delta
	if _online_poll_in > 0.0 or _pending_rpc:
		return
	_online_poll_in = ONLINE_POLL_SEC
	_poll_server_state()

func _poll_server_state() -> void:
	if NetworkManager == null or not NetworkManager.has_method("call_rpc"):
		return
	_pending_rpc = true
	NetworkManager.call("call_rpc", "get_world_boss_state", {}, func(result: Dictionary):
		_pending_rpc = false
		_on_server_state(result))

func _on_server_state(result: Dictionary) -> void:
	if not bool(result.get("ok", result.get("success", false))):
		# Module missing / soft-fail — after a few misses use offline cadence.
		_online_soft_fails += 1
		return
	_online_soft_fails = 0
	var active: Variant = result.get("active", null)
	if active is Dictionary and not (active as Dictionary).is_empty():
		var ad: Dictionary = active
		var bid := str(ad.get("boss_id", ""))
		if bid != "" and (_active_boss == null or _boss_id != bid):
			_spawn_world_boss(ad)
		return
	# No active — claim if due.
	var seconds_until := int(result.get("seconds_until_spawn", 999999))
	if seconds_until <= 0:
		_claim_spawn()

func _claim_spawn() -> void:
	if _pending_rpc:
		return
	var ctx := _spawn_context()
	if ctx.is_empty():
		_online_poll_in = 5.0
		return
	_pending_rpc = true
	var payload := {
		"boss_id": "world_%d" % Time.get_unix_time_from_system(),
		"line_id": str(ctx.line.get("id", "world_boss")),
		"faction": str(ctx.line.get("faction", "Factionless")),
		"category": str(ctx.line.get("category", "Gravity")),
		"stage": 4,
		"x": ctx.pos.x,
		"y": ctx.pos.y,
		"z": ctx.pos.z,
	}
	NetworkManager.call("call_rpc", "claim_world_boss_spawn", payload, func(result: Dictionary):
		_pending_rpc = false
		if bool(result.get("claimed", false)) and result.get("active") is Dictionary:
			_spawn_world_boss(result.active)
		elif result.get("active") is Dictionary and not (result.active as Dictionary).is_empty():
			_spawn_world_boss(result.active)
	)

func note_zone_kill(hub_id: String) -> void:
	_zone_kills[hub_id] = int(_zone_kills.get(hub_id, 0)) + 1
	# Accelerate the next world boss after enough zone kills.
	if int(_zone_kills.get(hub_id, 0)) >= 2:
		_next_spawn_in = mini(_next_spawn_in, 30.0)
	if _online_mode and NetworkManager != null and NetworkManager.has_method("call_rpc"):
		NetworkManager.call("call_rpc", "note_zone_boss_kill", {"hub_id": hub_id}, func(_r: Dictionary): pass)

func clear_active() -> void:
	if _active_boss != null and is_instance_valid(_active_boss):
		_active_boss.queue_free()
	_active_boss = null
	_boss_id = ""
	_boss_alive_for = 0.0

func _spawn_context() -> Dictionary:
	var tree := get_tree()
	if tree == null:
		return {}
	var world := tree.get_first_node_in_group("layer_world")
	if world == null:
		return {}
	var player: Node3D = null
	if world.has_method("get_local_player"):
		player = world.get_local_player()
	if player == null:
		for n in tree.get_nodes_in_group("player"):
			if n is Node3D:
				player = n
				break
	if player == null:
		return {}
	var faction := CompanionRegistry.normalize_faction(PlayerProfile.faction)
	var line := EntityDexData.random_line(faction)
	if line.is_empty():
		line = {"id": "world_boss", "faction": "Factionless", "category": "Gravity",
			"stages": [{"name": "Metroplex Titan", "desc": "The skyline itself fights back."}]}
	var pos := player.global_position + Vector3(28, 0, 18)
	return {"world": world, "player": player, "line": line, "pos": pos}

func _spawn_world_boss(server_active: Dictionary) -> void:
	if _active_boss != null and is_instance_valid(_active_boss):
		return
	var ctx := _spawn_context()
	if ctx.is_empty():
		_next_spawn_in = 45.0
		_online_poll_in = 5.0
		return
	var world: Node = ctx.world
	var player: Node3D = ctx.player
	var line: Dictionary = ctx.line
	var pos: Vector3 = ctx.pos
	var stage := 4
	if not server_active.is_empty():
		_boss_id = str(server_active.get("boss_id", _boss_id))
		stage = int(server_active.get("stage", 4))
		pos = Vector3(
			float(server_active.get("x", pos.x)),
			float(server_active.get("y", pos.y)),
			float(server_active.get("z", pos.z)))
		# Prefer server-declared line identity when present.
		if str(server_active.get("line_id", "")) != "":
			line = {
				"id": str(server_active.get("line_id", "world_boss")),
				"faction": str(server_active.get("faction", "Factionless")),
				"category": str(server_active.get("category", "Gravity")),
				"stages": line.get("stages", [{"name": "Metroplex Titan", "desc": ""}]),
			}
	else:
		_boss_id = "world_%d" % Time.get_unix_time_from_system()
	var ent := WorldEntity.new()
	ent.name = "WorldBoss"
	world.add_child(ent)
	ent.global_position = pos
	ent.setup_boss(line, stage, player)
	ent.died.connect(_on_boss_died)
	_active_boss = ent
	_boss_alive_for = 0.0
	NotificationUI.notify_win("🌋 WORLD BOSS — Metroplex Titan has manifested nearby.")
	boss_spawned.emit(_boss_id, pos)

func _on_boss_died(ent: WorldEntity) -> void:
	var killed_id := _boss_id
	_active_boss = null
	_boss_alive_for = 0.0
	var bounty := ent.bounty() * 5
	EconomyManager.earn_currency_local("fragments", bounty, "world_boss_kill")
	EconomyManager.earn_prestige_local(50, "world_boss_kill")
	CrownManager.add_score("Top Territory Captures", "local_player", 8, PlayerProfile.faction)
	QuestManager.update_progress("defeat_world_boss")
	NotificationUI.notify_win("World boss down — +%d fragments. The Metroplex breathes." % bounty)
	boss_defeated.emit(killed_id)
	if _online_mode and NetworkManager != null and NetworkManager.has_method("call_rpc"):
		NetworkManager.call("call_rpc", "report_world_boss_kill", {"boss_id": killed_id},
			func(_r: Dictionary): pass)
	_boss_id = ""
