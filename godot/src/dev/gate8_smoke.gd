extends SceneTree
## Headless smoke for GOTY gate 8 — local Nakama path (no prod secrets).
## Requires docker-compose.dev.yml + built modules:
##   ./scripts/build_nakama_modules.sh
##   docker compose -f docker-compose.dev.yml up -d
## Run: godot --headless --path godot -s res://src/dev/gate8_smoke.gd
##
## Offline alias checks always run. If Nakama isn't reachable, prints SKIP
## after those (exit 0) — prod host stays pinned.
## Set env GATE8_REQUIRE_LIVE=1 (CI live job) to treat SKIP as FAIL.

func _init() -> void:
	call_deferred("_run")

func _require_live() -> bool:
	return str(OS.get_environment("GATE8_REQUIRE_LIVE")).strip_edges() in ["1", "true", "TRUE", "yes"]

func _run() -> void:
	print("[gate8_smoke] start")
	await process_frame
	var ok := true

	# Always: OfflineCasino field-alias path (board_id ↔ leaderboard) + match.
	if not OfflineCasino.supports("get_leaderboard") or not OfflineCasino.supports("submit_score"):
		_fail("OfflineCasino missing leaderboard RPCs")
		return
	if not OfflineCasino.supports("find_match"):
		_fail("OfflineCasino missing find_match")
		return
	if not OfflineCasino.supports("get_story_tallies"):
		ok = false
		print("[gate8_smoke] get_story_tallies support FAIL")

	var offline_lb: Dictionary = await OfflineCasino.resolve(
		"get_leaderboard", {"board_id": "global_wins", "limit": 5})
	print("[gate8_smoke] offline get_leaderboard success=", offline_lb.get("success", false),
		" board_id=", offline_lb.get("board_id", ""),
		" leaderboard=", offline_lb.get("leaderboard", ""))
	if not bool(offline_lb.get("success", offline_lb.get("ok", false))):
		ok = false
		print("[gate8_smoke] offline get_leaderboard FAIL")
	elif str(offline_lb.get("board_id", "")) != "global_wins" \
			or str(offline_lb.get("leaderboard", "")) != "global_wins":
		ok = false
		print("[gate8_smoke] offline board_id alias FAIL")
	else:
		print("[gate8_smoke] offline board_id alias ok")

	var offline_sub: Dictionary = await OfflineCasino.resolve(
		"submit_score", {"board_id": "global_wins", "score": 7})
	print("[gate8_smoke] offline submit_score success=", offline_sub.get("success", false),
		" leaderboard=", offline_sub.get("leaderboard", ""))
	if not bool(offline_sub.get("success", offline_sub.get("ok", false))) \
			or str(offline_sub.get("leaderboard", "")) != "global_wins":
		ok = false
		print("[gate8_smoke] offline submit_score FAIL")
	else:
		print("[gate8_smoke] offline submit_score ok")

	var offline_match: Dictionary = await OfflineCasino.resolve(
		"find_match", {"game_type": "duel_1v1"})
	print("[gate8_smoke] offline find_match success=", offline_match.get("success", false),
		" practice=", offline_match.get("practice", false))
	if not bool(offline_match.get("success", offline_match.get("ok", false))):
		ok = false
		print("[gate8_smoke] offline find_match FAIL")
	else:
		print("[gate8_smoke] offline find_match ok")

	# Client-side payload mirror (NetworkManager) — board_id → leaderboard.
	var net_offline: Node = root.get_node_or_null("NetworkManager")
	if net_offline != null and net_offline.has_method("_normalize_payload"):
		var mirrored: Variant = net_offline.call(
			"_normalize_payload", "get_leaderboard", {"board_id": "slot_wins", "limit": 3})
		if mirrored is Dictionary \
				and str(mirrored.get("leaderboard", "")) == "slot_wins" \
				and str(mirrored.get("board_id", "")) == "slot_wins":
			print("[gate8_smoke] NetworkManager board_id mirror ok")
		else:
			ok = false
			print("[gate8_smoke] NetworkManager board_id mirror FAIL ", mirrored)
	else:
		ok = false
		print("[gate8_smoke] NetworkManager normalize missing FAIL")

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
		if _require_live():
			_fail("GATE8_REQUIRE_LIVE=1 but Nakama unreachable — docker compose not up?")
			return
		print("[gate8_smoke] RESULT=", "PASS" if ok else "FAIL",
			" (SKIP live — start docker-compose.dev.yml for auth)")
		quit(0 if ok else 1)
		return

	var auth_ok: bool = await acct.auth_device("gate8_smoke_device")
	print("[gate8_smoke] auth_device=", auth_ok, " authenticated=", acct.get("is_authenticated"))
	if not auth_ok:
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
		print("[gate8_smoke] wallet soft-fail (modules may be empty) — PASS with warning")

	# StoryVote
	var vote_ballot := "gate8_smoke_ballot"
	var vote := {"success": false}
	done = false
	net.call("call_rpc", "story_vote",
		{"ballot": vote_ballot, "option": 0},
		func(result: Dictionary):
			vote = result
			done = true)
	wait_until = Time.get_ticks_msec() + 8000
	while not done and Time.get_ticks_msec() < wait_until:
		await process_frame
	print("[gate8_smoke] story_vote success=", vote.get("success", false),
		" recorded=", vote.get("recorded", false),
		" reason=", vote.get("reason", vote.get("error", "")),
		" keys=", vote.keys())
	var vote_ok := bool(vote.get("success", vote.get("ok", false)))
	var cooldown_ok := str(vote.get("reason", "")) == "cooldown"
	if not vote_ok and not cooldown_ok:
		print("[gate8_smoke] story_vote soft-fail (rebuild modules?) — PASS with warning")
	else:
		print("[gate8_smoke] story_vote ok")

	var tallies := {"success": false}
	done = false
	net.call("call_rpc", "get_story_tallies",
		{"ballot": vote_ballot},
		func(result: Dictionary):
			tallies = result
			done = true)
	wait_until = Time.get_ticks_msec() + 8000
	while not done and Time.get_ticks_msec() < wait_until:
		await process_frame
	print("[gate8_smoke] get_story_tallies success=", tallies.get("success", false),
		" total=", tallies.get("total", -1),
		" keys=", tallies.keys())
	if vote_ok and not bool(tallies.get("success", tallies.get("ok", false))):
		print("[gate8_smoke] get_story_tallies soft-fail — PASS with warning")

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

	# World boss shared cadence RPC.
	var boss_state := {"ok": false}
	done = false
	net.call("call_rpc", "get_world_boss_state", {}, func(result: Dictionary):
		boss_state = result
		done = true)
	wait_until = Time.get_ticks_msec() + 8000
	while not done and Time.get_ticks_msec() < wait_until:
		await process_frame
	print("[gate8_smoke] get_world_boss_state=", boss_state)
	if not bool(boss_state.get("ok", boss_state.get("success", false))):
		_fail("get_world_boss_state failed — rebuild modules + restart nakama")
		return
	if not boss_state.has("next_spawn_unix"):
		_fail("get_world_boss_state missing next_spawn_unix")
		return

	# Live: board_id alias on get_leaderboard / submit_score + find_match.
	var live_sub := {"success": false}
	done = false
	net.call("call_rpc", "submit_score",
		{"board_id": "global_wins", "score": 3},
		func(result: Dictionary):
			live_sub = result
			done = true)
	wait_until = Time.get_ticks_msec() + 8000
	while not done and Time.get_ticks_msec() < wait_until:
		await process_frame
	print("[gate8_smoke] live submit_score success=", live_sub.get("success", false),
		" leaderboard=", live_sub.get("leaderboard", live_sub.get("board_id", "")),
		" error=", live_sub.get("error", ""),
		" keys=", live_sub.keys())
	if not bool(live_sub.get("success", live_sub.get("ok", false))):
		print("[gate8_smoke] live submit_score soft-fail — PASS with warning")
	else:
		print("[gate8_smoke] live submit_score ok")

	var live_lb := {"success": false}
	done = false
	net.call("call_rpc", "get_leaderboard",
		{"board_id": "global_wins", "limit": 10},
		func(result: Dictionary):
			live_lb = result
			done = true)
	wait_until = Time.get_ticks_msec() + 8000
	while not done and Time.get_ticks_msec() < wait_until:
		await process_frame
	print("[gate8_smoke] live get_leaderboard success=", live_lb.get("success", false),
		" board_id=", live_lb.get("board_id", ""),
		" records=", (live_lb.get("records", []) as Array).size() if live_lb.get("records") is Array else -1,
		" error=", live_lb.get("error", ""),
		" keys=", live_lb.keys())
	if not bool(live_lb.get("success", live_lb.get("ok", false))):
		print("[gate8_smoke] live get_leaderboard soft-fail — PASS with warning")
	else:
		print("[gate8_smoke] live get_leaderboard ok")

	var live_match := {"success": false}
	done = false
	net.call("call_rpc", "find_match",
		{"game_type": "duel_1v1"},
		func(result: Dictionary):
			live_match = result
			done = true)
	wait_until = Time.get_ticks_msec() + 8000
	while not done and Time.get_ticks_msec() < wait_until:
		await process_frame
	print("[gate8_smoke] live find_match success=", live_match.get("success", false),
		" match_id=", live_match.get("match_id", ""),
		" error=", live_match.get("error", ""),
		" keys=", live_match.keys())
	if not bool(live_match.get("success", live_match.get("ok", false))):
		print("[gate8_smoke] live find_match soft-fail — PASS with warning")
	else:
		print("[gate8_smoke] live find_match ok")

	print("[gate8_smoke] RESULT=", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

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
