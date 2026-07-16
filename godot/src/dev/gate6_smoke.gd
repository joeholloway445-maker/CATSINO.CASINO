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
	}, 4, null)
	if ent.max_hp < 400:
		ok = false
		print("[gate6_smoke] boss hp FAIL ", ent.max_hp)
	else:
		print("[gate6_smoke] boss hp=", ent.max_hp)
	ent.queue_free()

	print("[gate6_smoke] RESULT=", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

func _fail(msg: String) -> void:
	push_error("[gate6_smoke] " + msg)
	print("[gate6_smoke] RESULT=FAIL")
	quit(1)
