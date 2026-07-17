extends SceneTree
## Headless smoke for GOTY gate 6 — modes scaffolding (bosses/dungeons/campaign).
## Run: godot --headless --path godot -s res://src/dev/gate6_smoke.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[gate6_smoke] start")
	await process_frame
	var ok := true

	var m2: Dictionary = ArenaModes.by_id("duel_2v2")
	if m2.is_empty() or int(m2.get("team_size", 0)) != 2:
		ok = false
		print("[gate6_smoke] duel_2v2 FAIL")
	else:
		print("[gate6_smoke] duel_2v2 ok")

	var dr: Node = root.get_node_or_null("DungeonRuns")
	if dr == null:
		_fail("DungeonRuns missing")
		return
	Engine.set_meta("headless_smoke", true)
	var seed: int = int(dr.begin("dungeon_smoke"))
	print("[gate6_smoke] dungeon seed=", seed)
	dr.advance_depth()
	dr.advance_depth()
	dr.advance_depth()
	if not bool(dr.active) or int(dr.depth) < 3:
		ok = false
		print("[gate6_smoke] dungeon depth FAIL depth=", dr.depth)
	dr.eject("smoke")
	print("[gate6_smoke] dungeon eject ok active=", dr.active)

	var wbs: Node = root.get_node_or_null("WorldBossScheduler")
	print("[gate6_smoke] WorldBossScheduler=", wbs != null)
	if wbs == null:
		ok = false

	var qm: Node = root.get_node_or_null("QuestManager")
	if qm == null:
		_fail("QuestManager missing")
		return
	# accept() is local; update_progress is local — safe headless.
	var accepted: bool = qm.accept("pvp_campaign_01")
	print("[gate6_smoke] pvp_campaign_01 accept=", accepted)
	qm.update_progress("claim_chunk", 3)
	qm.update_progress("defeat_zone_boss", 1)
	# Completion should erase active + notify (rewards local).
	var still_active: bool = qm.is_active("pvp_campaign_01")
	var done: bool = qm.is_complete("pvp_campaign_01")
	print("[gate6_smoke] pvp_campaign_01 complete=", done, " still_active=", still_active)
	if accepted and not done:
		ok = false
		print("[gate6_smoke] campaign completion FAIL")

	var zb_script: GDScript = load("res://src/world/zone_boss_spawner.gd") as GDScript
	var de_script: GDScript = load("res://src/world/dungeon_entrance.gd") as GDScript
	print("[gate6_smoke] ZoneBossSpawner script=", zb_script != null, " DungeonEntrance script=", de_script != null)
	if zb_script == null or de_script == null:
		ok = false

	var ent := WorldEntity.new()
	root.add_child(ent)
	ent.setup_boss({
		"id": "t",
		"faction": "Factionless",
		"category": "Matter",
		"stages": [{"name": "Smoke Titan", "desc": ""}],
	}, 4, null, "WORLD BOSS")
	if ent.max_hp < 400:
		ok = false
		print("[gate6_smoke] boss hp FAIL ", ent.max_hp)
	else:
		print("[gate6_smoke] boss hp=", ent.max_hp)
	if ent._visual == null:
		ok = false
		print("[gate6_smoke] boss visual FAIL")
	else:
		print("[gate6_smoke] boss visual ok")
	# Regular wildlife must also build a mesh (setup() visual regression guard).
	var wild := WorldEntity.new()
	root.add_child(wild)
	wild.setup({
		"id": "w",
		"faction": "Factionless",
		"category": "Energy",
		"stages": [{"name": "Smoke Wisp", "desc": ""}],
	}, 1, null)
	if wild._visual == null:
		ok = false
		print("[gate6_smoke] wild visual FAIL")
	else:
		print("[gate6_smoke] wild visual ok")
	wild.queue_free()
	ent.queue_free()

	# begin again briefly to exercise run_seed() API
	var seed_again: int = int(dr.begin("dungeon_smoke"))
	var via_api: int = int(dr.run_seed())
	if seed_again == 0 or via_api != seed_again:
		ok = false
		print("[gate6_smoke] run_seed FAIL ", via_api, " vs ", seed_again)
	else:
		print("[gate6_smoke] run_seed ok=", via_api)

	# Gate 6 real floors: PeriliminalGenerator produces seeded floors with
	# entities/hazards/exits (not denser-spawn stand-ins).
	var gen := PeriliminalGenerator.new()
	var g1: Dictionary = gen.generate_gauntlet(via_api)
	var g2: Dictionary = gen.generate_gauntlet(via_api)
	var floors: Array = g1.get("floors", [])
	print("[gate6_smoke] gauntlet floors=", floors.size(), " seed=", g1.get("seed", 0))
	if floors.is_empty() or int(g1.get("seed", 0)) != via_api:
		ok = false
		print("[gate6_smoke] gauntlet FAIL")
	else:
		var f0: Dictionary = floors[0]
		if not f0.has("trap_type") or not f0.has("hazards") or not f0.has("exits"):
			ok = false
			print("[gate6_smoke] floor fields FAIL keys=", f0.keys())
		else:
			print("[gate6_smoke] floor0 trap=", f0.get("trap_type"),
				" hazards=", (f0.get("hazards", []) as Array).size(),
				" entities=", (f0.get("entities", []) as Array).size())
		# Same seed → same floor trap sequence.
		var floors2: Array = g2.get("floors", [])
		if floors2.is_empty() or str(floors2[0].get("trap_type", "")) != str(f0.get("trap_type", "")):
			ok = false
			print("[gate6_smoke] gauntlet determinism FAIL")
		else:
			print("[gate6_smoke] gauntlet determinism ok")
		# Entity tokens resolve to real dex lines.
		var ents: Array = f0.get("entities", [])
		if not ents.is_empty():
			var resolved: Dictionary = PeriliminalGenerator.resolve_entity_token(str(ents[0]))
			if resolved.is_empty() or not (resolved.get("line", {}) is Dictionary):
				ok = false
				print("[gate6_smoke] resolve_entity FAIL token=", ents[0])
			elif str((resolved.get("line", {}) as Dictionary).get("id", "")).is_empty():
				ok = false
				print("[gate6_smoke] resolve_entity empty id token=", ents[0])
			else:
				print("[gate6_smoke] resolve_entity ok=",
					(resolved.get("line", {}) as Dictionary).get("id", ""),
					"@", resolved.get("stage", 1))
	dr.eject("smoke2")

	# Arena hotbar cast path — free-roam mode (no wave loop) + skill hits.
	var arena_script: GDScript = load("res://src/world/arena_mode_controller.gd") as GDScript
	var player := Node3D.new()
	player.name = "SmokePlayer"
	root.add_child(player)
	player.global_position = Vector3.ZERO
	var arena: Node = arena_script.new()
	root.add_child(arena)
	arena.call("setup", "smoke_cast", player) # hits free-roam branch, still attaches hotbar
	var hotbar_ok := arena.get_node_or_null("ArenaHotbar") != null
	print("[gate6_smoke] arena hotbar=", hotbar_ok)
	if not hotbar_ok:
		ok = false
	var foe := WorldEntity.new()
	arena.add_child(foe)
	foe.setup({
		"id": "arena_foe",
		"faction": "Factionless",
		"category": "Energy",
		"stages": [{"name": "Arena Smoke", "desc": ""}],
	}, 1, player)
	foe.global_position = Vector3(2, 0, 0)
	arena.call("register_foe", foe)
	var hp_before: int = foe.hp
	var hits_seen := [0]
	if arena.has_signal("cast_resolved"):
		arena.connect("cast_resolved", func(_sid, hits): hits_seen[0] = hits)
	var sk := {
		"id": "smoke_a0", "name": "Smoke Strike", "kind": "damage",
		"shape": "single", "radius": 4.0, "power": 1.2, "element": "energy",
	}
	arena.call("_on_cast", sk)
	await process_frame
	print("[gate6_smoke] arena cast hits=", hits_seen[0], " foe_hp=", foe.hp, "/", hp_before)
	if hits_seen[0] < 1 or foe.hp >= hp_before:
		ok = false
		print("[gate6_smoke] arena cast FAIL")
	else:
		print("[gate6_smoke] arena cast ok")
	arena.set("_running", false)
	arena.queue_free()
	player.queue_free()

	# Hideout live-siege resolve (no dice) + combat registration path
	var hr: Node = root.get_node_or_null("HideoutRegistry")
	if hr:
		hr.call("register_site", "smoke_hideout", "supraliminal", "arlington", Vector3(10, 0, 10))
		var sites: Dictionary = hr.get("_sites")
		if sites.has("smoke_hideout"):
			sites["smoke_hideout"]["owner"] = "RivalGuild"
			sites["smoke_hideout"]["defenders"] = ["crew_a"]
		var flipped: bool = hr.call("resolve_contest_win", "smoke_hideout", "SmokeGuild")
		print("[gate6_smoke] hideout resolve_contest_win=", flipped)
		if not flipped:
			ok = false
		# Live spawn path registers with a LayerWorld-shaped host.
		var gh_script: GDScript = load("res://src/world/city/guild_hideout.gd") as GDScript
		if gh_script != null:
			var host := Node3D.new()
			host.set_script(load("res://src/dev/siege_host_stub.gd"))
			host.add_to_group("layer_world")
			root.add_child(host)
			var siege_player := Node3D.new()
			host.add_child(siege_player)
			hr.call("register_site", "smoke_hideout_live", "supraliminal", "arlington", Vector3(30, 0, 30))
			var sites2: Dictionary = hr.get("_sites")
			if sites2.has("smoke_hideout_live"):
				sites2["smoke_hideout_live"]["owner"] = "RivalGuild"
				sites2["smoke_hideout_live"]["defenders"] = []
			var hideout: Node = gh_script.new()
			host.add_child(hideout)
			hideout.call("setup", "smoke_hideout_live", "supraliminal", "arlington",
				Color(0.5, 0.4, 0.3), siege_player, Vector3(30, 0, 30))
			hideout.call("_begin_siege", "SmokeGuild")
			await process_frame
			var reg_n: int = int(host.get("entities").size()) if host.get("entities") != null else 0
			var alive_n: int = (hideout.get("_siege_alive") as Array).size()
			print("[gate6_smoke] live siege defenders=", alive_n, " registered=", reg_n)
			if alive_n < 1 or reg_n < 1:
				ok = false
				print("[gate6_smoke] live siege register FAIL")
			else:
				print("[gate6_smoke] live siege register ok")
			hideout.queue_free()
			host.queue_free()
	else:
		print("[gate6_smoke] HideoutRegistry missing — skip")

	print("[gate6_smoke] RESULT=", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

func _fail(msg: String) -> void:
	push_error("[gate6_smoke] " + msg)
	print("[gate6_smoke] RESULT=FAIL")
	quit(1)
