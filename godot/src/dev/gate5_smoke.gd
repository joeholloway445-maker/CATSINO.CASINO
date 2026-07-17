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

	# Combat juice wiring — SkillVFX + CombatSfx (Gate 5/7 cast/hit audio).
	var vfx_scr: GDScript = load("res://src/skills/skill_vfx.gd") as GDScript
	var sfx_scr: GDScript = load("res://src/audio/combat_sfx.gd") as GDScript
	print("[gate5_smoke] SkillVFX=", vfx_scr != null, " CombatSfx=", sfx_scr != null)
	if vfx_scr == null or sfx_scr == null:
		ok = false
	else:
		var host := Node3D.new()
		r.add_child(host)
		# Fire-and-forget paths must not throw headless (synth/AssetLibrary).
		SkillVFX.cast_flash(host, Vector3.ZERO)
		SkillVFX.hit_spark(host, Vector3(1, 0, 0))
		SkillVFX.ultimate_burst(host, Vector3.ZERO, 4.0)
		SkillVFX.shield_bubble(host, host, 0.1)
		print("[gate5_smoke] SkillVFX cast/hit/ult/shield ok")
		for slot in ["skill_cast", "skill_hit", "skill_ult", "skill_shield",
				"boss_spawn", "boss_phase", "boss_death"]:
			CombatSfx.play(host, slot, Vector3.ZERO)
		print("[gate5_smoke] CombatSfx slots ok")
		# Leave host for SceneTree quit — early queue_free trips SkillVFX
		# particle/shield timer lambdas under headless.

	print("[gate5_smoke] RESULT=", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

func _fail(msg: String) -> void:
	push_error("[gate5_smoke] " + msg)
	print("[gate5_smoke] RESULT=FAIL")
	quit(1)
