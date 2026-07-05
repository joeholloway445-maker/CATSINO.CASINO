extends Node
## Autoloaded as "PresenceManager". Other players in the world.
##
## Online path: one Nakama match per reality layer ("layer_<id>"); position
## broadcast at 10Hz over the socket, remote states fanned out as signals.
## Written against the NakamaSocket API (connect_async / join_match_async /
## send_match_state_async / received_match_state) — the bundled addon is a
## stub, so the moment the official nakama-godot addon replaces it and
## AccountManager authenticates, this goes live with no changes here.
##
## Offline path: ghost players — wandering stand-ins built from the entity
## roster so layers never feel empty. They render through the perception
## lens like real players and are replaced 1:1 by real presences online.

signal peer_joined(peer_id: String, profile: Dictionary)
signal peer_updated(peer_id: String, pos: Vector3)
signal peer_left(peer_id: String)

const OP_POSITION := 1
const BROADCAST_HZ := 10.0
const GHOST_COUNT := 4

var _socket = null
var _match_id := ""
var _accum := 0.0
var _my_pos := Vector3.ZERO
var _ghosts: Dictionary = {} # id -> {pos, dir, profile, retarget}

func _ready() -> void:
	LayerManager.layer_changed.connect(func(_f, to): join_layer(to))

func join_layer(layer_id: String) -> void:
	# Tear down previous room.
	for gid in _ghosts.keys():
		peer_left.emit(gid)
	_ghosts.clear()
	_match_id = ""

	if _try_connect_socket():
		var result = await _socket.join_match_async("layer_%s" % layer_id)
		_match_id = str(result.get("match_id", "layer_%s" % layer_id))
	else:
		_spawn_ghosts(layer_id)

func _try_connect_socket() -> bool:
	if not NetworkManager.is_connected_to_server():
		return false
	if _socket == null:
		var client = AccountManager.get_nakama_client()
		if client == null or not client.has_method("create_socket"):
			return false
		_socket = client.create_socket()
		_socket.received_match_state.connect(_on_match_state)
		var result = await _socket.connect_async(AccountManager.get_nakama_session())
		if result.is_exception():
			push_warning("PresenceManager: socket connect failed: %s" % result.get_exception().message)
			_socket = null
			return false
	return _socket.is_connected_to_host()

## Layer scenes call this every frame with the local player's position.
func report_position(pos: Vector3) -> void:
	_my_pos = pos

func _physics_process(delta: float) -> void:
	# Broadcast upstream.
	if _match_id != "" and _socket != null and _socket.is_connected_to_host():
		_accum += delta
		if _accum >= 1.0 / BROADCAST_HZ:
			_accum = 0.0
			_socket.send_match_state_async(_match_id, OP_POSITION, JSON.stringify({
				"id": PlayerProfile.username,
				"pos": [_my_pos.x, _my_pos.y, _my_pos.z],
				"profile": PerceptionSystem.local_profile(),
			}))
	# Drive ghosts.
	for gid in _ghosts.keys():
		var g: Dictionary = _ghosts[gid]
		g.retarget -= delta
		if g.retarget <= 0.0:
			g.retarget = randf_range(3.0, 8.0)
			g.dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		g.pos += g.dir * 3.0 * delta
		peer_updated.emit(gid, g.pos)

func _on_match_state(state) -> void:
	if int(state.get("op_code", 0)) != OP_POSITION:
		return
	var data = JSON.parse_string(str(state.get("data", "{}")))
	if not data is Dictionary:
		return
	var pid := str(data.get("id", ""))
	if pid == "" or pid == PlayerProfile.username:
		return
	var arr: Array = data.get("pos", [0, 0, 0])
	peer_updated.emit(pid, Vector3(arr[0], arr[1], arr[2]))

## Offline stand-ins: named from the roster, profiled so perception works.
func _spawn_ghosts(layer_id: String) -> void:
	if layer_id in ["hyperliminal", "subliminal"]:
		return # menus and your apartment stay yours
	for i in range(GHOST_COUNT):
		var e := CompanionRegistry.get_random()
		var gid := "ghost_%s_%d" % [str(e.get("name", "wanderer")).replace(" ", "_"), i]
		var profile := {
			"level": randi_range(1, 60),
			"faction": CompanionRegistry.normalize_faction(str(e.get("faction", ""))),
			"alignment": ["radiant", "neutral", "umbral", "feral"][randi() % 4],
			"stats": {"pow": e.get("pow", 40), "spd": e.get("spd", 40)},
		}
		_ghosts[gid] = {
			"pos": Vector3(randf_range(-60, 60), 0, randf_range(-60, 60)),
			"dir": Vector3.FORWARD, "retarget": 0.0, "profile": profile,
		}
		peer_joined.emit(gid, profile)

func peer_profile(peer_id: String) -> Dictionary:
	return _ghosts.get(peer_id, {}).get("profile", {})
