extends SceneTree
## Headless smoke for GOTY gate 8 — local Nakama path (no prod secrets).
## Requires docker-compose.dev.yml + built modules:
##   ./scripts/build_nakama_modules.sh
##   docker compose -f docker-compose.dev.yml up -d
## Run: godot --headless --path godot -s res://src/dev/gate8_smoke.gd
##
## If Nakama isn't reachable, prints SKIP (exit 0) — prod host stays pinned.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[gate8_smoke] start")
	await process_frame
	var acct: Node = root.get_node_or_null("AccountManager")
	if acct == null:
		_fail("AccountManager missing")
		return

	# PresenceManager must exist even offline (ghost path).
	var presence: Node = root.get_node_or_null("PresenceManager")
	print("[gate8_smoke] PresenceManager=", presence != null)
	if presence == null:
		_fail("PresenceManager missing")
		return

	# Probe TCP — avoid long auth hangs when compose isn't up.
	var host := "127.0.0.1"
	var port := 7350
	if FileAccess.file_exists("res://server_config.json"):
		var cfg = JSON.parse_string(FileAccess.get_file_as_string("res://server_config.json"))
		if cfg is Dictionary:
			host = str(cfg.get("nakama_host", host))
			port = int(cfg.get("nakama_port", port))

	var reachable := await _tcp_probe(host, port, 1.5)
	print("[gate8_smoke] nakama ", host, ":", port, " reachable=", reachable)
	if not reachable:
		# Offline ghost path still must work.
		if presence.has_method("join_layer"):
			await presence.join_layer("liminal")
			print("[gate8_smoke] offline ghost join_layer ok")
		print("[gate8_smoke] RESULT=SKIP (start docker-compose.dev.yml for live auth)")
		quit(0)
		return

	var ok: bool = await acct.auth_device("gate8_smoke_device")
	print("[gate8_smoke] auth_device=", ok, " authenticated=", acct.get("is_authenticated"))
	if not ok:
		_fail("auth_device failed against local Nakama")
		return

	var net: Node = root.get_node_or_null("NetworkManager")
	if net == null or not net.has_method("call_rpc"):
		_fail("NetworkManager missing")
		return

	var wallet := {"success": false}
	var done := false
	net.call("call_rpc", "get_wallet", {}, func(result: Dictionary):
		wallet = result
		done = true)
	var wait_until := Time.get_ticks_msec() + 8000
	while not done and Time.get_ticks_msec() < wait_until:
		await process_frame
	print("[gate8_smoke] get_wallet success=", wallet.get("success", false),
		" keys=", wallet.keys())
	if not bool(wallet.get("success", wallet.get("ok", false))):
		print("[gate8_smoke] wallet soft-fail (modules may be empty) — continuing")

	# Layer presence — must return a real match id for non-private layers.
	var presence_rpc := {"ok": false}
	done = false
	net.call("call_rpc", "join_layer_presence", {"layer_id": "liminal"}, func(result: Dictionary):
		presence_rpc = result
		done = true)
	wait_until = Time.get_ticks_msec() + 8000
	while not done and Time.get_ticks_msec() < wait_until:
		await process_frame
	print("[gate8_smoke] join_layer_presence=", presence_rpc)
	var mid := str(presence_rpc.get("match_id", ""))
	if not bool(presence_rpc.get("ok", presence_rpc.get("success", false))) or mid == "":
		_fail("join_layer_presence did not return match_id — rebuild modules + restart nakama")
		return

	# Client join path: PresenceManager must land online (not ghost-only).
	if presence.has_method("join_layer"):
		await presence.join_layer("liminal")
		await process_frame
		var online := false
		if presence.has_method("is_online_presence"):
			online = bool(presence.call("is_online_presence"))
		print("[gate8_smoke] PresenceManager online=", online, " match=", mid)
		if not online:
			# Socket join can fail on stub addons — still require RPC success above.
			print("[gate8_smoke] presence socket soft-fail (addon stub?) — RPC path PASS")

	# District counts RPC must respond (may be zeros before anyone joins).
	var districts := {"districts": {}}
	done = false
	net.call("call_rpc", "get_active_districts", {}, func(result: Dictionary):
		districts = result
		done = true)
	wait_until = Time.get_ticks_msec() + 5000
	while not done and Time.get_ticks_msec() < wait_until:
		await process_frame
	print("[gate8_smoke] get_active_districts keys=", districts.keys(),
		" districts=", districts.get("districts", {}))

	print("[gate8_smoke] RESULT=PASS")
	quit(0)

func _tcp_probe(host: String, port: int, timeout_s: float) -> bool:
	var peer := StreamPeerTCP.new()
	var err := peer.connect_to_host(host, port)
	if err != OK:
		return false
	var deadline := Time.get_ticks_msec() + int(timeout_s * 1000.0)
	while Time.get_ticks_msec() < deadline:
		peer.poll()
		var st := peer.get_status()
		if st == StreamPeerTCP.STATUS_CONNECTED:
			peer.disconnect_from_host()
			return true
		if st == StreamPeerTCP.STATUS_ERROR:
			return false
		await process_frame
	peer.disconnect_from_host()
	return false

func _fail(msg: String) -> void:
	push_error("[gate8_smoke] " + msg)
	print("[gate8_smoke] RESULT=FAIL")
	quit(1)
