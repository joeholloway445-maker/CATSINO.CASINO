extends SceneTree
## Headless smoke for GOTY gate 5 — combat economy / hideout / casino / StoryVote.
## Avoids EconomyManager paths that await Nakama pushes (those hang headless).
## Run: godot --headless --path godot -s res://src/dev/gate5_smoke.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[gate5_smoke] start")
	await process_frame
	var ok := true
	var r := root

	var eco: Node = r.get_node_or_null("EconomyManager")
	if eco == null:
		_fail("EconomyManager missing")
		return
	# Read-only checks — earn/spend await server push and hang offline headless.
	var bal: int = int(eco.get_balance("fragments"))
	print("[gate5_smoke] economy fragments=", bal, " coins=", eco.get_coins())

	var sv: Node = r.get_node_or_null("StoryVote")
	if sv == null:
		_fail("StoryVote missing")
		return
	var ballot_n := 0
	if sv.get("BALLOTS") != null:
		ballot_n = int(sv.get("BALLOTS").size()) if typeof(sv.get("BALLOTS")) != TYPE_NIL else 0
	# Prefer script constant via has_method — avoid bare Autoload in -s smokes.
	var can_vote := false
	if sv.has_method("can_vote"):
		can_vote = bool(sv.call("can_vote", "s1_main_story"))
	print("[gate5_smoke] StoryVote ballots=", ballot_n, " can_vote=", can_vote)

	var hr: Node = r.get_node_or_null("HideoutRegistry")
	if hr == null:
		_fail("HideoutRegistry missing")
		return
	hr.register_site("smoke_site", "supraliminal", "arlington", Vector3(10, 0, 10))
	var claimable: Dictionary = hr.can_claim("smoke_site", "smoke_guild")
	print("[gate5_smoke] hideout can_claim=", claimable)
	# claim() may earn currency (network await) — only exercise can_claim offline.

	if not OfflineCasino.supports("spin_slots"):
		ok = false
		print("[gate5_smoke] casino supports FAIL")
	else:
		print("[gate5_smoke] casino supports spin_slots ok")
	if not OfflineCasino.supports("get_leaderboard"):
		ok = false
		print("[gate5_smoke] get_leaderboard support FAIL")
	else:
		print("[gate5_smoke] get_leaderboard support ok")
	if not OfflineCasino.supports("summon_companion"):
		ok = false
		print("[gate5_smoke] summon_companion support FAIL")
	else:
		print("[gate5_smoke] summon_companion support ok")
	# Poker/blackjack parse guards — inference bugs block table scenes.
	var poker_ok: bool = ResourceLoader.exists("res://src/games/arcade/poker.gd")
	var bj_ok: bool = ResourceLoader.exists("res://src/games/arcade/blackjack.gd")
	print("[gate5_smoke] poker.gd=", poker_ok, " blackjack.gd=", bj_ok)
	if not poker_ok or not bj_ok:
		ok = false
	var poker_scr: GDScript = load("res://src/games/arcade/poker.gd") as GDScript
	var bj_scr: GDScript = load("res://src/games/arcade/blackjack.gd") as GDScript
	print("[gate5_smoke] poker load=", poker_scr != null, " blackjack load=", bj_scr != null)
	if poker_scr == null or bj_scr == null:
		ok = false

	var chips: int = int(eco.get_balance("chips"))
	print("[gate5_smoke] chips balance=", chips)
	# Local chip debit/credit — no Nakama await.
	if eco.has_method("spend_currency_local") and eco.has_method("earn_currency_local"):
		var spent: bool = eco.spend_currency_local("chips", 1, "gate5_smoke")
		if spent:
			eco.earn_currency_local("chips", 1, "gate5_smoke")
		print("[gate5_smoke] chips local loop spent=", spent)
	else:
		ok = false
		print("[gate5_smoke] chips local API FAIL")

	var skills: Node = r.get_node_or_null("SkillManager")
	print("[gate5_smoke] SkillManager=", skills != null)
	if skills == null:
		ok = false

	var hotbar_ok: bool = ResourceLoader.exists("res://src/skills/hotbar_ui.gd")
	print("[gate5_smoke] HotbarUI=", hotbar_ok)
	if not hotbar_ok:
		ok = false

	var we_script: GDScript = load("res://src/world/world_entity.gd") as GDScript
	print("[gate5_smoke] WorldEntity=", we_script != null)
	if we_script == null:
		ok = false

	# Live hideout siege must register defenders with LayerWorld combat so
	# hotbar casts / bites land (Gate 5 hideout juice — not spectacle-only).
	var gh_script: GDScript = load("res://src/world/city/guild_hideout.gd") as GDScript
	var stub_script: GDScript = load("res://src/dev/siege_host_stub.gd") as GDScript
	print("[gate5_smoke] GuildHideout=", gh_script != null, " SiegeHostStub=", stub_script != null)
	if gh_script == null or stub_script == null:
		ok = false
	else:
		var host := Node3D.new()
		host.set_script(stub_script)
		host.name = "SiegeHost"
		host.add_to_group("layer_world")
		root.add_child(host)
		var player := Node3D.new()
		player.name = "SmokePlayer"
		host.add_child(player)
		hr.register_site("smoke_siege", "supraliminal", "arlington", Vector3(20, 0, 20))
		var sites: Dictionary = hr.get("_sites")
		if sites.has("smoke_siege"):
			sites["smoke_siege"]["owner"] = "RivalGuild"
			sites["smoke_siege"]["defenders"] = ["siege_crew_a"]
		var hideout: Node = gh_script.new()
		host.add_child(hideout)
		hideout.call("setup", "smoke_siege", "supraliminal", "arlington",
			Color(0.6, 0.3, 0.3), player, Vector3(20, 0, 20))
		hideout.call("_begin_siege", "SmokeAttackers")
		await process_frame
		var alive: Array = hideout.get("_siege_alive")
		var registered: int = int(host.get("entities").size()) if host.get("entities") != null else 0
		print("[gate5_smoke] siege defenders=", alive.size(), " registered=", registered,
			" active=", hideout.get("_siege_active"))
		if alive.is_empty() or registered < 1:
			ok = false
			print("[gate5_smoke] siege register FAIL")
		else:
			# Hotbar path: take_hit until dead → ownership flips.
			var defender: WorldEntity = alive[0] as WorldEntity
			var hp0: int = defender.hp
			defender.take_hit(hp0 + 50)
			await process_frame
			var flipped_owner := str(hr.call("owner_of", "smoke_siege"))
			print("[gate5_smoke] after kill owner=", flipped_owner,
				" siege_active=", hideout.get("_siege_active"))
			if flipped_owner != "SmokeAttackers":
				ok = false
				print("[gate5_smoke] siege resolve FAIL")
			else:
				print("[gate5_smoke] siege combat ok")
		hideout.queue_free()
		host.queue_free()

	print("[gate5_smoke] RESULT=", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

func _fail(msg: String) -> void:
	push_error("[gate5_smoke] " + msg)
	print("[gate5_smoke] RESULT=FAIL")
	quit(1)
