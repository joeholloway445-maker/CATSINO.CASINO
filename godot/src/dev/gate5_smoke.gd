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
	print("[gate5_smoke] StoryVote ballots=", StoryVote.BALLOTS.size(),
		" can_vote=", sv.can_vote("s1_main_story"))

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

	print("[gate5_smoke] RESULT=", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

func _fail(msg: String) -> void:
	push_error("[gate5_smoke] " + msg)
	print("[gate5_smoke] RESULT=FAIL")
	quit(1)
