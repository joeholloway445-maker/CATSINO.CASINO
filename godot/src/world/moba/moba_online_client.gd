class_name MobaOnlineClient
extends Node3D
## Nakama-driven online Paws of the Ancients client. Sends intents, renders
## authoritative snapshots. Falls back is handled by the arena hub before
## this node is created.

signal match_won(score: int)
signal match_lost()
signal score_changed(score: int)
signal status(text: String)

const Op := {
	"READY": 1,
	"INPUT": 2,
	"BASIC_ATTACK": 4,
	"SHOP_BUY": 5,
	"SHOP_SELL": 6,
	"RECALL_START": 7,
	"RECALL_CANCEL": 8,
	"SNAPSHOT": 101,
	"EVENT": 107,
	"PHASE": 108,
	"MATCH_END": 109,
}

var player: Node3D
var match_id: String = ""
var my_id: String = ""
var my_team: String = "ally"
var score := 0
var _socket = null
var _running := true
var _shop := MobaShop.new()
var _shop_ui: MobaShopUI
var _hud: MobaHud
var _structs: Dictionary = {} # id -> Node3D
var _minions: Dictionary = {} # id -> Node3D
var _heroes: Dictionary = {} # id -> Node3D
var _attack_cd := 0.0
var _phase := 0
var _last_snapshot: Dictionary = {}

func start(p_player: Node3D, p_match_id: String) -> void:
	player = p_player
	match_id = p_match_id
	my_id = str(PlayerProfile.username) if PlayerProfile else "player"
	_build_ui()
	status.emit("Connecting to match…")
	var ok: bool = await _connect_and_join()
	if not ok:
		status.emit("Online join failed — starting local practice")
		NotificationUI.notify_error("Could not join online match — practice mode.")
		_fallback_offline()
		return
	_send(Op.READY, {})
	NotificationUI.notify_info("Online lobby joined. Waiting for teams…")

func hud_line() -> String:
	var phase_name := ["LOBBY", "COUNTDOWN", "FIGHT", "END"]
	var pn := phase_name[_phase] if _phase >= 0 and _phase < phase_name.size() else "?"
	return "ONLINE %s · %s · gold %d · %s" % [pn, my_team.to_upper(), _shop.gold, "LIVE" if _running else "DONE"]

func _fallback_offline() -> void:
	var local := MobaMatch.new()
	local.name = "MobaMatchOfflineFallback"
	add_child(local)
	local.match_won.connect(func(s: int): match_won.emit(s))
	local.match_lost.connect(func(): match_lost.emit())
	local.score_changed.connect(func(s: int): score_changed.emit(s))
	local.start(player)

func _build_ui() -> void:
	_hud = MobaHud.new()
	add_child(_hud)
	_hud.setup(_shop, self)
	_shop_ui = MobaShopUI.new()
	add_child(_shop_ui)
	_shop_ui.setup(_shop, Callable(self, "at_fountain"))
	# Intercept buy/sell to send server intents — shop still applies locally for UX,
	# server snapshot reconciles.
	_shop.item_bought.connect(func(id: String): _send(Op.SHOP_BUY, {"item_id": id}))
	_shop.item_sold.connect(func(_id: String, slot: int): _send(Op.SHOP_SELL, {"slot": slot}))
	var open_btn := Button.new()
	open_btn.text = "Shop (B)"
	open_btn.position = Vector2(24, 52)
	open_btn.pressed.connect(_shop_ui.toggle)
	var layer := CanvasLayer.new()
	layer.layer = 19
	add_child(layer)
	layer.add_child(open_btn)

func at_fountain() -> bool:
	if player == null:
		return false
	var f := Vector3(-32, 0.5, 0) if my_team == "ally" else Vector3(32, 0.5, 0)
	return player.global_position.distance_to(f) <= 9.0

func hero_is_alive() -> bool:
	return _shop.hero.get("hp", 1) > 0

func _connect_and_join() -> bool:
	if not NetworkManager.is_connected_to_server():
		return false
	var client = AccountManager.get_nakama_client()
	var session = AccountManager.get_nakama_session()
	if client == null or session == null or not client.has_method("create_socket"):
		return false
	_socket = client.create_socket()
	_socket.received_match_state.connect(_on_match_state)
	var conn = await _socket.connect_async(session)
	if conn != null and conn.has_method("is_exception") and conn.is_exception():
		push_warning("MobaOnline: socket connect failed")
		return false
	var join = await _socket.join_match_async(match_id)
	if join != null and join.has_method("is_exception") and join.is_exception():
		push_warning("MobaOnline: join failed")
		return false
	# Prefer server user id when session exposes it.
	if session.get("user_id") != null:
		my_id = str(session.user_id)
	elif session.has_method("get_user_id"):
		my_id = str(session.get_user_id())
	return true

func _send(op: int, payload: Dictionary) -> void:
	if _socket == null or match_id.is_empty():
		return
	if not _socket.has_method("send_match_state_async"):
		return
	_socket.send_match_state_async(match_id, op, JSON.stringify(payload))

func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			_shop_ui.toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			_send(Op.RECALL_START, {})
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if not _running or player == null:
		return
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	# Broadcast position
	_send(Op.INPUT, {"x": player.global_position.x, "z": player.global_position.z})
	# Auto-attack nearest enemy from last snapshot
	if _attack_cd <= 0.0:
		var tid := _nearest_target_id()
		if not tid.is_empty():
			_send(Op.BASIC_ATTACK, {"target_id": tid})
			_attack_cd = 0.85 / maxf(float(_shop.hero.get("attack_speed", 1.0)), 0.2)

func _nearest_target_id() -> String:
	var origin := player.global_position
	var best := ""
	var best_d := float(_shop.hero.get("attack_range", 3.2))
	for id in _minions.keys():
		var n: Node3D = _minions[id]
		if not is_instance_valid(n):
			continue
		if str(n.get_meta("team", "")) == my_team:
			continue
		var d: float = origin.distance_to(n.global_position)
		if d < best_d:
			best_d = d
			best = id
	for id in _structs.keys():
		var n: Node3D = _structs[id]
		if not is_instance_valid(n):
			continue
		if str(n.get_meta("team", "")) == my_team:
			continue
		if bool(n.get_meta("invuln", false)):
			continue
		var d: float = origin.distance_to(n.global_position)
		if d < best_d + 0.5:
			best_d = d
			best = id
	for id in _heroes.keys():
		if id == my_id:
			continue
		var n: Node3D = _heroes[id]
		if not is_instance_valid(n):
			continue
		if str(n.get_meta("team", "")) == my_team:
			continue
		var d: float = origin.distance_to(n.global_position)
		if d < best_d:
			best_d = d
			best = id
	return best

func _on_match_state(state) -> void:
	# NakamaMatchData-like: op_code + data
	var op: int = int(state.get("op_code", state.get("opCode", -1))) if typeof(state) == TYPE_DICTIONARY else int(state.op_code) if "op_code" in state else -1
	var raw: String = ""
	if typeof(state) == TYPE_DICTIONARY:
		raw = str(state.get("data", ""))
		op = int(state.get("op_code", op))
	else:
		raw = str(state.data) if "data" in state else ""
		if "op_code" in state:
			op = int(state.op_code)
	var data = JSON.parse_string(raw)
	if data == null:
		return
	match op:
		Op.SNAPSHOT:
			_apply_snapshot(data)
		Op.PHASE:
			_phase = int(data.get("phase", _phase))
			if _hud:
				_hud.show_banner(["Lobby", "Countdown", "FIGHT!", "Match Over"][_phase] if _phase < 4 else "…", 1.5)
		Op.EVENT:
			_on_event(data)
		Op.MATCH_END:
			_on_match_end(data)

func _on_event(data: Dictionary) -> void:
	var t := str(data.get("type", ""))
	if _hud == null:
		return
	match t:
		"join":
			_hud.push_feed("%s joined (%s)" % [data.get("id", "?"), data.get("team", "?")], Color(0.7, 0.9, 1.0))
		"countdown":
			_hud.show_banner("Starting in %s…" % str(data.get("seconds", 3)), 2.0)
		"fight":
			_hud.show_banner("FIGHT!", 1.5)
		"wave":
			_hud.push_feed("Wave %s" % str(data.get("n", "?")), Color(0.85, 0.9, 1.0))
		"kill":
			_hud.push_feed("Kill: %s → %s" % [data.get("killer", "?"), data.get("victim", "?")], Color(1.0, 0.75, 0.35))
		"leave_bot":
			_hud.push_feed("%s replaced by bot" % data.get("id", "?"), Color(1.0, 0.6, 0.4))

func _on_match_end(data: Dictionary) -> void:
	_running = false
	var winner := str(data.get("winner", ""))
	if data.has("snapshot"):
		_apply_snapshot(data.snapshot)
	var won: bool = winner == my_team
	if _hud:
		_hud.show_banner("VICTORY" if won else "DEFEAT", 4.0)
	if won:
		match_won.emit(score)
	else:
		match_lost.emit()

func _apply_snapshot(snap: Dictionary) -> void:
	_last_snapshot = snap
	_phase = int(snap.get("phase", _phase))
	# Players
	var seen_heroes: Dictionary = {}
	for p in snap.get("players", []):
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var id := str(p.get("id", ""))
		seen_heroes[id] = true
		if id == my_id or (not p.get("bot", true) and str(p.get("name", "")) == str(PlayerProfile.username)):
			my_id = id
			my_team = str(p.get("team", my_team))
			_sync_local_hero(p)
			if player and bool(p.get("alive", true)):
				# Soft-correct if desynced heavily
				var server_pos := Vector3(float(p.get("x", 0)), player.global_position.y, float(p.get("z", 0)))
				if player.global_position.distance_to(server_pos) > 8.0:
					player.global_position = server_pos
			elif player and not bool(p.get("alive", true)):
				player.visible = false
			if player and bool(p.get("alive", true)):
				player.visible = true
			continue
		_upsert_hero(p)
	for id in _heroes.keys():
		if not seen_heroes.has(id):
			if is_instance_valid(_heroes[id]):
				_heroes[id].queue_free()
			_heroes.erase(id)
	# Structures
	var seen_s: Dictionary = {}
	for s in snap.get("structures", []):
		if typeof(s) != TYPE_DICTIONARY:
			continue
		var id := str(s.get("id", ""))
		seen_s[id] = true
		_upsert_struct(s)
	for id in _structs.keys():
		if not seen_s.has(id):
			if is_instance_valid(_structs[id]):
				_structs[id].queue_free()
			_structs.erase(id)
	# Minions
	var seen_m: Dictionary = {}
	for m in snap.get("minions", []):
		if typeof(m) != TYPE_DICTIONARY:
			continue
		var id := str(m.get("id", ""))
		seen_m[id] = true
		_upsert_minion(m)
	for id in _minions.keys():
		if not seen_m.has(id):
			if is_instance_valid(_minions[id]):
				_minions[id].queue_free()
			_minions.erase(id)

func _sync_local_hero(p: Dictionary) -> void:
	_shop.gold = int(p.get("gold", _shop.gold))
	_shop.hero.hp = int(p.get("hp", 160))
	_shop.hero.max_hp = int(p.get("max_hp", 160))
	_shop.hero.damage = int(p.get("damage", 14))
	_shop.hero.armor = int(p.get("armor", 2))
	_shop.hero.attack_speed = float(p.get("attack_speed", 1.0))
	_shop.hero.tower_mult = float(p.get("tower_mult", 0.0))
	_shop.hero.attack_range = float(p.get("attack_range", 3.2))
	_shop.hero.level = int(p.get("level", 1))
	_shop.hero.xp = int(p.get("xp", 0))
	_shop.hero.xp_next = int(p.get("xp_next", 100))
	_shop.hero.kills = int(p.get("kills", 0))
	_shop.hero.deaths = int(p.get("deaths", 0))
	_shop.hero.assists = int(p.get("assists", 0))
	_shop.hero.cs = int(p.get("cs", 0))
	score = int(p.get("kills", 0)) * 40 + int(p.get("cs", 0)) * 5
	score_changed.emit(score)
	_shop.gold_changed.emit(_shop.gold)
	if float(p.get("recall_left", -1)) >= 0.0 and _hud:
		var rl: float = float(p.get("recall_left", 0))
		_hud.set_recall(1.0 - clampf(rl / 4.0, 0.0, 1.0))
	if not bool(p.get("alive", true)) and _hud:
		# Approximate respawn display from tick fields if present
		_hud.set_respawn(3.0)

func _upsert_struct(s: Dictionary) -> void:
	var id := str(s.get("id", ""))
	var node: Node3D
	if _structs.has(id) and is_instance_valid(_structs[id]):
		node = _structs[id]
	else:
		node = _make_box(s)
		_structs[id] = node
	node.global_position = Vector3(float(s.get("x", 0)), 0, float(s.get("z", 0)))
	node.set_meta("team", str(s.get("team", "")))
	node.set_meta("invuln", bool(s.get("invuln", false)))
	var lbl: Label3D = node.get_node_or_null("Label")
	if lbl:
		var lock := " 🔒" if bool(s.get("invuln", false)) else ""
		lbl.text = "%s %s%s\n%d/%d" % [str(s.get("team", "")).to_upper(), str(s.get("kind", "")).to_upper(), lock, int(s.get("hp", 0)), int(s.get("max_hp", 1))]

func _upsert_minion(m: Dictionary) -> void:
	var id := str(m.get("id", ""))
	var node: Node3D
	if _minions.has(id) and is_instance_valid(_minions[id]):
		node = _minions[id]
	else:
		node = _make_capsule(m, 0.35)
		_minions[id] = node
	node.global_position = Vector3(float(m.get("x", 0)), 0.5, float(m.get("z", 0)))
	node.set_meta("team", str(m.get("team", "")))
	var lbl: Label3D = node.get_node_or_null("Label")
	if lbl:
		lbl.text = "%s %d" % ["▲" if str(m.get("team")) == "ally" else "▼", int(m.get("hp", 0))]

func _upsert_hero(p: Dictionary) -> void:
	var id := str(p.get("id", ""))
	if not bool(p.get("alive", true)):
		if _heroes.has(id) and is_instance_valid(_heroes[id]):
			_heroes[id].visible = false
		return
	var node: Node3D
	if _heroes.has(id) and is_instance_valid(_heroes[id]):
		node = _heroes[id]
		node.visible = true
	else:
		node = _make_capsule(p, 0.45)
		_heroes[id] = node
	node.global_position = Vector3(float(p.get("x", 0)), 0.5, float(p.get("z", 0)))
	node.set_meta("team", str(p.get("team", "")))
	var lbl: Label3D = node.get_node_or_null("Label")
	if lbl:
		lbl.text = "%s\n%d/%d" % [str(p.get("name", id)), int(p.get("hp", 0)), int(p.get("max_hp", 1))]

func _make_box(s: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = str(s.get("id", "struct"))
	add_child(root)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	var kind := str(s.get("kind", "tower"))
	box.size = Vector3(3.6, 7.0, 3.6) if kind == "nexus" else (Vector3(2.8, 3.2, 2.8) if kind == "inhibitor" else Vector3(2.4, 4.8, 2.4))
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	var team := str(s.get("team", "enemy"))
	mat.albedo_color = Color(0.35, 0.65, 1.0) if team == "ally" else Color(1.0, 0.35, 0.3)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mesh.material_override = mat
	mesh.position.y = box.size.y * 0.5
	root.add_child(mesh)
	var lbl := Label3D.new()
	lbl.name = "Label"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position.y = box.size.y + 0.6
	lbl.font_size = 30
	root.add_child(lbl)
	return root

func _make_capsule(data: Dictionary, radius: float) -> Node3D:
	var root := Node3D.new()
	root.name = str(data.get("id", data.get("name", "unit")))
	add_child(root)
	var mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = radius
	cap.height = radius * 3.0
	mesh.mesh = cap
	var mat := StandardMaterial3D.new()
	var team := str(data.get("team", "enemy"))
	mat.albedo_color = Color(0.4, 0.75, 1.0) if team == "ally" else Color(1.0, 0.45, 0.35)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mesh.material_override = mat
	mesh.position.y = 0.8
	root.add_child(mesh)
	var lbl := Label3D.new()
	lbl.name = "Label"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position.y = 1.8
	lbl.font_size = 26
	root.add_child(lbl)
	return root
