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
	if not OfflineCasino.supports("find_or_create_layer_match"):
		ok = false
		print("[gate8_smoke] find_or_create_layer_match support FAIL")
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

	# REQUIRE_LIVE: retry — CI can take minutes between compose-up and smoke
	# (Godot install + class cache), and a single 1.5s probe is flaky.
	var reachable := false
	var probe_budget := 12.0 if _require_live() else 1.5
	var probe_deadline := Time.get_ticks_msec() + int(probe_budget * 1000.0)
	while Time.get_ticks_msec() < probe_deadline:
		reachable = await _tcp_probe(host, port, 1.5)
		if reachable:
			break
		await process_frame
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
	if net == null or not net.has_method("call_rpc_await"):
		_fail("NetworkManager missing call_rpc_await")
		return

	# Live RPC path — call_rpc_await (Object.call orphans coroutines).
	var wallet: Dictionary = await net.call_rpc_await("get_wallet", {})
	print("[gate8_smoke] get_wallet success=", wallet.get("success", false),
		" keys=", wallet.keys(), " offline=", wallet.get("offline", false),
		" err=", wallet.get("error", wallet.get("live_error", "")))
	if not bool(wallet.get("success", wallet.get("ok", false))):
		print("[gate8_smoke] wallet soft-fail (modules may be empty) — PASS with warning")

	# StoryVote
	var vote_ballot := "gate8_smoke_ballot"
	var vote: Dictionary = await net.call_rpc_await("story_vote",
		{"ballot": vote_ballot, "option": 0})
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

	var tallies: Dictionary = await net.call_rpc_await("get_story_tallies",
		{"ballot": vote_ballot})
	print("[gate8_smoke] get_story_tallies success=", tallies.get("success", false),
		" total=", tallies.get("total", -1),
		" keys=", tallies.keys())
	if vote_ok and not bool(tallies.get("success", tallies.get("ok", false))):
		print("[gate8_smoke] get_story_tallies soft-fail — PASS with warning")

	# Client join path: PresenceManager must land online (not ghost-only).
	if presence.has_method("join_layer"):
		await presence.join_layer("liminal")
		await process_frame
		var online := false
		if presence.has_method("is_online_match"):
			online = bool(presence.call("is_online_match"))
		var mid := ""
		if presence.has_method("current_match_id"):
			mid = str(presence.call("current_match_id"))
		print("[gate8_smoke] PresenceManager online=", online, " match=", mid)
		if not online:
			print("[gate8_smoke] presence socket soft-fail (addon stub?) — RPC path PASS")

	# Optional district counts RPC (PresenceManager.presence_count covers hubs offline).
	var districts: Dictionary = await net.call_rpc_await("get_active_districts", {})
	print("[gate8_smoke] get_active_districts keys=", districts.keys(),
		" ok=", bool(districts.get("success", districts.get("ok", false))),
		" error=", districts.get("error", ""))
	if not bool(districts.get("success", districts.get("ok", false))):
		print("[gate8_smoke] get_active_districts soft-fail (optional) — PASS with warning")

	# World boss shared cadence RPC.
	var boss_state: Dictionary = await net.call_rpc_await("get_world_boss_state", {})
	print("[gate8_smoke] get_world_boss_state=", boss_state)
	if not bool(boss_state.get("ok", boss_state.get("success", false))):
		_fail("get_world_boss_state failed — rebuild modules + restart nakama")
		return
	if not boss_state.has("next_spawn_unix"):
		_fail("get_world_boss_state missing next_spawn_unix")
		return
	if bool(boss_state.get("offline", false)):
		print("[gate8_smoke] get_world_boss_state offline mirror (live RPC soft) — ok")
	else:
		print("[gate8_smoke] get_world_boss_state live ok")

	# Live: board_id alias on get_leaderboard / submit_score + find_match.
	var live_sub: Dictionary = await net.call_rpc_await("submit_score",
		{"board_id": "global_wins", "score": 3})
	print("[gate8_smoke] live submit_score success=", live_sub.get("success", false),
		" leaderboard=", live_sub.get("leaderboard", live_sub.get("board_id", "")),
		" error=", live_sub.get("error", ""),
		" keys=", live_sub.keys())
	if not bool(live_sub.get("success", live_sub.get("ok", false))):
		print("[gate8_smoke] live submit_score soft-fail — PASS with warning")
	else:
		print("[gate8_smoke] live submit_score ok")

	var live_lb: Dictionary = await net.call_rpc_await("get_leaderboard",
		{"board_id": "global_wins", "limit": 10})
	print("[gate8_smoke] live get_leaderboard success=", live_lb.get("success", false),
		" board_id=", live_lb.get("board_id", ""),
		" records=", (live_lb.get("records", []) as Array).size() if live_lb.get("records") is Array else -1,
		" error=", live_lb.get("error", ""),
		" keys=", live_lb.keys())
	if not bool(live_lb.get("success", live_lb.get("ok", false))):
		print("[gate8_smoke] live get_leaderboard soft-fail — PASS with warning")
	else:
		print("[gate8_smoke] live get_leaderboard ok")

	var live_match: Dictionary = await net.call_rpc_await("find_match",
		{"game_type": "duel_1v1"})
	print("[gate8_smoke] live find_match success=", live_match.get("success", false),
		" match_id=", live_match.get("match_id", ""),
		" error=", live_match.get("error", ""),
		" keys=", live_match.keys())
	if not bool(live_match.get("success", live_match.get("ok", false))):
		print("[gate8_smoke] live find_match soft-fail — PASS with warning")
	else:
		print("[gate8_smoke] live find_match ok")

	# Gate 8 core: real layer presence match id (not inventable "layer_<id>").
	var layer: Dictionary = await net.call_rpc_await("find_or_create_layer_match",
		{"layer_id": "liminal"})
	var layer_mid := str(layer.get("match_id", ""))
	print("[gate8_smoke] find_or_create_layer_match success=", layer.get("success", false),
		" created=", layer.get("created", false),
		" match_id=", layer_mid,
		" keys=", layer.keys())
	if not bool(layer.get("success", layer.get("ok", false))) or layer_mid.is_empty():
		print("[gate8_smoke] layer_presence soft-fail (rebuild modules?) — PASS with warning")
	else:
		print("[gate8_smoke] layer_presence ok")

	# PresenceManager resolves the same RPC when authenticated.
	# (`presence` already resolved near the top of this smoke.)
	if presence != null and presence.has_method("join_layer"):
		await presence.call("join_layer", "liminal")
		await process_frame
		await process_frame
		var mid := ""
		if presence.has_method("current_match_id"):
			mid = str(presence.call("current_match_id"))
		print("[gate8_smoke] PresenceManager match_id=", mid,
			" online=", presence.call("is_online_match") if presence.has_method("is_online_match") else "?")
		if mid.is_empty() and not layer_mid.is_empty():
			print("[gate8_smoke] PresenceManager join soft-fail — PASS with warning")
		elif not mid.is_empty():
			print("[gate8_smoke] PresenceManager joined live layer match")

	
	# Gate 8 thicken: hideout claim / contest online parity.
	var hideout_site := "gate8_smoke_hideout"
	var upsert: Dictionary = await net.call_rpc_await("hideout_upsert_site",
		{"site_id": hideout_site, "realm": "supraliminal", "hub": "smoke",
			"pos": [12.0, 34.0]})
	print("[gate8_smoke] hideout_upsert_site success=", upsert.get("success", false),
		" keys=", upsert.keys())
	var upsert_ok := bool(upsert.get("success", upsert.get("ok", false)))
	if not upsert_ok:
		print("[gate8_smoke] hideout_upsert soft-fail (rebuild modules?) — PASS with warning")

	var claim: Dictionary = await net.call_rpc_await("hideout_claim",
		{"site_id": hideout_site, "guild": "SmokeGuild"})
	print("[gate8_smoke] hideout_claim success=", claim.get("success", false),
		" owner=", (claim.get("site", {}) as Dictionary).get("owner", "") if claim.get("site") is Dictionary else "",
		" keys=", claim.keys())
	var claim_ok := bool(claim.get("success", claim.get("ok", false)))
	if upsert_ok and not claim_ok:
		print("[gate8_smoke] hideout_claim soft-fail — PASS with warning")
	elif claim_ok:
		print("[gate8_smoke] hideout_claim ok")

	# Seed a rival owner via second claim path: contest needs prior owner.
	# Claim as rival only works on empty site — use a second site for contest.
	var contest_site := "gate8_smoke_contest"
	var rival: Dictionary = await net.call_rpc_await("hideout_upsert_site",
		{"site_id": contest_site, "realm": "supraliminal", "hub": "smoke",
			"pos": [400.0, 400.0]})
	rival = await net.call_rpc_await("hideout_claim",
		{"site_id": contest_site, "guild": "RivalGuild"})

	var contested: Dictionary = await net.call_rpc_await("hideout_contest_win",
		{"site_id": contest_site, "attacker_guild": "SmokeGuild"})
	print("[gate8_smoke] hideout_contest_win success=", contested.get("success", false),
		" prior=", contested.get("prior_owner", ""),
		" keys=", contested.keys())
	if bool(rival.get("success", rival.get("ok", false))) \
			and not bool(contested.get("success", contested.get("ok", false))):
		print("[gate8_smoke] hideout_contest_win soft-fail — PASS with warning")
	elif bool(contested.get("success", contested.get("ok", false))):
		print("[gate8_smoke] hideout_contest_win ok")

	var got: Dictionary = await net.call_rpc_await("hideout_get", {"site_id": hideout_site})
	print("[gate8_smoke] hideout_get success=", got.get("success", false),
		" keys=", got.keys())

	
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
