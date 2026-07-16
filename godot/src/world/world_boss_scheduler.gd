extends Node
## Autoloaded as "WorldBossScheduler". Gate 6 — one Stage-3+ world boss on a
## local cadence. Online: Nakama can drive the same schedule later.

signal boss_spawned(boss_id: String, pos: Vector3)
signal boss_defeated(boss_id: String)

const BOSS_INTERVAL_SEC := 20 * 60 # 20 minutes offline cadence
const BOSS_MAX_LIFETIME_SEC := 8 * 60 # despawn if ignored

var _active_boss: WorldEntity = null
var _boss_id := ""
var _zone_kills: Dictionary = {} # hub_id -> count
var _elapsed := 0.0
var _next_spawn_in := 90.0 # first spawn soon for playability
var _boss_alive_for := 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
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
		_spawn_world_boss()
		_next_spawn_in = BOSS_INTERVAL_SEC

func note_zone_kill(hub_id: String) -> void:
	_zone_kills[hub_id] = int(_zone_kills.get(hub_id, 0)) + 1
	# Accelerate the next world boss after enough zone kills.
	if int(_zone_kills.get(hub_id, 0)) >= 2:
		_next_spawn_in = mini(_next_spawn_in, 30.0)

func clear_active() -> void:
	if _active_boss != null and is_instance_valid(_active_boss):
		_active_boss.queue_free()
	_active_boss = null
	_boss_id = ""
	_boss_alive_for = 0.0

func _spawn_world_boss() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var world := tree.get_first_node_in_group("layer_world")
	if world == null:
		# Retry soon — player may not be in a layer yet.
		_next_spawn_in = 45.0
		return
	var player: Node3D = null
	if world.has_method("get_local_player"):
		player = world.get_local_player()
	if player == null:
		for n in tree.get_nodes_in_group("player"):
			if n is Node3D:
				player = n
				break
	if player == null:
		_next_spawn_in = 45.0
		return
	var faction := CompanionRegistry.normalize_faction(PlayerProfile.faction)
	var line := EntityDexData.random_line(faction)
	if line.is_empty():
		line = {"id": "world_boss", "faction": "Factionless", "category": "Gravity",
			"stages": [{"name": "Metroplex Titan", "desc": "The skyline itself fights back."}]}
	_boss_id = "world_%d" % Time.get_unix_time_from_system()
	var ent := WorldEntity.new()
	ent.name = "WorldBoss"
	world.add_child(ent)
	var pos := player.global_position + Vector3(28, 0, 18)
	ent.global_position = pos
	ent.setup_boss(line, 4, player)
	ent.died.connect(_on_boss_died)
	_active_boss = ent
	_boss_alive_for = 0.0
	NotificationUI.notify_win("🌋 WORLD BOSS — Metroplex Titan has manifested nearby.")
	boss_spawned.emit(_boss_id, pos)

func _on_boss_died(ent: WorldEntity) -> void:
	_active_boss = null
	_boss_alive_for = 0.0
	var bounty := ent.bounty() * 5
	EconomyManager.earn_currency_local("fragments", bounty, "world_boss_kill")
	EconomyManager.earn_prestige_local(50, "world_boss_kill")
	CrownManager.add_score("Top Territory Captures", "local_player", 8, PlayerProfile.faction)
	QuestManager.update_progress("defeat_world_boss")
	NotificationUI.notify_win("World boss down — +%d fragments. The Metroplex breathes." % bounty)
	boss_defeated.emit(_boss_id)
	_boss_id = ""
