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
## Offline path: ghost bots — stand-ins built from the entity roster so
## layers never feel empty, and PvP zones never feel like an empty gym.
## Tiered like CoD skirmish bots, low-key mapped to Knoll:
##   STATIC   (60%) — dumb wander, ignores the player, occasional misfire
##                     (attacks the wrong direction, whiffs, stands still).
##   REACTIVE (30%) — notices proximity, approaches/flees by a fixed rule,
##                     makes rookie mistakes (overextends, forgets to kite).
##   ADAPTIVE (10%) — reads Hope.combat_profile() (the same axes Knoll
##                     fights you with in the Ascension Trial) and biases
##                     long-term toward countering the player's own habits
##                     — cautious against aggressive players, aggressive
##                     against cautious ones — AND tracks this encounter in
##                     real time, escalating if it keeps landing hits.
## Rarer tiers are deliberately kept rare — most of the crowd should still
## read as filler, so the sharp ones stand out.
##
## They render through the perception lens like real players and are
## replaced 1:1 by real presences online.

signal peer_joined(peer_id: String, profile: Dictionary)
signal peer_updated(peer_id: String, pos: Vector3)
signal peer_left(peer_id: String)
signal bot_wants_cast(peer_id: String, skill: Dictionary) # tiered bots "attacking"

enum BotTier { STATIC, REACTIVE, ADAPTIVE }
const TIER_WEIGHTS := {BotTier.STATIC: 0.6, BotTier.REACTIVE: 0.3, BotTier.ADAPTIVE: 0.1}

const OP_POSITION := 1
const BROADCAST_HZ := 10.0
const GHOST_COUNT := 4
const BOT_AGGRO_RANGE := 16.0
const BOT_ATTACK_RANGE := 4.0

var _socket = null
var _match_id := ""
var _accum := 0.0
var _my_pos := Vector3.ZERO
var _ghosts: Dictionary = {} # id -> {pos, dir, profile, retarget, tier, aggression, caution, misfire_cd, attack_cd, hits_landed}

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
	# Drive ghost bots — tier-specific movement/aggro.
	for gid in _ghosts.keys():
		_drive_ghost(gid, delta)
		peer_updated.emit(gid, _ghosts[gid].pos)

func _drive_ghost(gid: String, delta: float) -> void:
	var g: Dictionary = _ghosts[gid]
	var to_player := _my_pos - g.pos
	to_player.y = 0.0
	var dist := to_player.length()
	g.attack_cd = maxf(g.attack_cd - delta, 0.0)

	match int(g.tier):
		BotTier.STATIC:
			# Ignores the player entirely — pure wander, with an occasional
			# "misfire": stops dead and fires a skill at nothing.
			g.retarget -= delta
			if g.retarget <= 0.0:
				g.retarget = randf_range(3.0, 8.0)
				g.dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
				if randf() < 0.15:
					g.dir = Vector3.ZERO
					_ghost_misfire(gid, g)
			g.pos += g.dir * 3.0 * delta

		BotTier.REACTIVE:
			if dist < BOT_AGGRO_RANGE:
				if dist > BOT_ATTACK_RANGE:
					# Rookie mistake: overextends straight at the player,
					# no strafing, no retreat threshold.
					g.pos += to_player.normalized() * 3.6 * delta
				elif g.attack_cd <= 0.0:
					g.attack_cd = randf_range(1.4, 2.2)
					bot_wants_cast.emit(gid, {"id": "bot_strike", "kind": "damage", "power": 0.8})
			else:
				g.retarget -= delta
				if g.retarget <= 0.0:
					g.retarget = randf_range(3.0, 8.0)
					g.dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
				g.pos += g.dir * 3.0 * delta

		BotTier.ADAPTIVE:
			if dist < BOT_AGGRO_RANGE * 1.3:
				# Cautious players get pressured, aggressive players get
				# kited — countering the profile Hope has learned, biased
				# further in real time by how this fight is actually going.
				var press := clampf(1.0 - g.aggression + (g.hits_landed * 0.08), 0.1, 1.5)
				var keep_range := lerpf(BOT_ATTACK_RANGE * 0.7, BOT_ATTACK_RANGE * 2.2, g.caution)
				if dist > keep_range:
					g.pos += to_player.normalized() * (3.2 + press) * delta
				elif dist < keep_range * 0.6 and g.caution > 0.5:
					g.pos -= to_player.normalized() * 2.6 * delta # kite back out
				if g.attack_cd <= 0.0 and dist <= keep_range * 1.1:
					g.attack_cd = randf_range(0.9, 1.6) / maxf(press, 0.5)
					var power := 0.9 + g.aggression * 0.4
					bot_wants_cast.emit(gid, {"id": "bot_strike", "kind": "damage", "power": power})
			else:
				g.retarget -= delta
				if g.retarget <= 0.0:
					g.retarget = randf_range(2.0, 5.0)
					g.dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
				g.pos += g.dir * 3.5 * delta
	_ghosts[gid] = g

func _ghost_misfire(gid: String, g: Dictionary) -> void:
	var wild_dir := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	bot_wants_cast.emit(gid, {"id": "bot_misfire", "kind": "damage", "power": 0.5, "dir": wild_dir})

## Called by layer_world/pvxc_zone when a bot lands a hit on the player —
## adaptive bots escalate within the encounter, mirroring Knoll's habit of
## getting sharper the longer a fight against you runs.
func report_bot_hit_landed(peer_id: String) -> void:
	if _ghosts.has(peer_id):
		_ghosts[peer_id].hits_landed = int(_ghosts[peer_id].get("hits_landed", 0)) + 1

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

## Offline stand-ins: named from the roster, profiled so perception works,
## tiered so the crowd feels alive without every bot being a threat.
func _spawn_ghosts(layer_id: String) -> void:
	if layer_id in ["hyperliminal", "subliminal"]:
		return # menus and your apartment stay yours
	var knoll: Dictionary = Hope.combat_profile() if Hope else {}
	for i in range(GHOST_COUNT):
		var e := CompanionRegistry.get_random()
		var gid := "ghost_%s_%d" % [str(e.get("name", "wanderer")).replace(" ", "_"), i]
		var profile := {
			"level": randi_range(1, 60),
			"faction": CompanionRegistry.normalize_faction(str(e.get("faction", ""))),
			"alignment": ["radiant", "neutral", "umbral", "feral"][randi() % 4],
			"stats": {"pow": e.get("pow", 40), "spd": e.get("spd", 40)},
		}
		var tier := _roll_tier()
		var aggression := 0.5
		var caution := 0.5
		if tier == BotTier.ADAPTIVE and not knoll.is_empty():
			# Countering, not mirroring: a habitually aggressive player
			# meets a bot that plays cagey, and vice versa.
			aggression = clampf(1.0 - float(knoll.get("caution", 0.5)) + randf_range(-0.1, 0.1), 0.1, 0.95)
			caution = clampf(1.0 - float(knoll.get("aggression", 0.5)) + randf_range(-0.1, 0.1), 0.1, 0.95)
		_ghosts[gid] = {
			"pos": Vector3(randf_range(-60, 60), 0, randf_range(-60, 60)),
			"dir": Vector3.FORWARD, "retarget": 0.0, "profile": profile,
			"tier": tier, "aggression": aggression, "caution": caution,
			"attack_cd": 0.0, "hits_landed": 0,
		}
		peer_joined.emit(gid, profile)

func _roll_tier() -> int:
	var roll := randf()
	var acc := 0.0
	for tier in TIER_WEIGHTS:
		acc += TIER_WEIGHTS[tier]
		if roll <= acc:
			return tier
	return BotTier.STATIC

func peer_profile(peer_id: String) -> Dictionary:
	return _ghosts.get(peer_id, {}).get("profile", {})

func peer_tier(peer_id: String) -> int:
	return int(_ghosts.get(peer_id, {}).get("tier", BotTier.STATIC))
