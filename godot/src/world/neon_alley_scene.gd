extends Node

signal race_finished(place: int, prize_coins: int)

const ENTRY_FEE: int = 50

var _ai_racers: Array[CharacterData] = []
var _status: Label

func _ready() -> void:
	_spawn_ai_racers()
	_build_ui()

func _spawn_ai_racers() -> void:
	_ai_racers.clear()
	var races: Array = [
		CharacterData.Race.KETH, CharacterData.Race.VEX, CharacterData.Race.FEROX,
		CharacterData.Race.NYX, CharacterData.Race.VOLT, CharacterData.Race.LUMARI,
	]
	for i in range(6):
		var racer: CharacterData = CharacterData.new()
		racer.character_name = "Racer_%d" % i
		racer.race = races[i % races.size()]
		racer.base_spd = randi_range(60, 95)
		racer.base_lck = randi_range(20, 60)
		racer.base_pow = randi_range(10, 40)
		racer.base_res = randi_range(10, 40)
		_ai_racers.append(racer)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var title := Label.new()
	title.text = "🏁 NEON ALLEY"
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	_status = Label.new()
	_status.text = "Street heats. Entry %d coins." % ENTRY_FEE
	root.add_child(_status)

	var start_btn := Button.new()
	start_btn.text = "Start Street Race"
	start_btn.pressed.connect(func() -> void:
		var player := CharacterData.new()
		player.character_name = "You"
		player.base_spd = 70 + PlayerProfile.level * 2
		player.base_lck = 40
		await start_race(player))
	root.add_child(start_btn)

	var full_track := Button.new()
	full_track.text = "Open Grand Circuit"
	full_track.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/games/racing/race_track.tscn"))
	root.add_child(full_track)

	var back := Button.new()
	back.text = "⬅ Menu"
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	root.add_child(back)

func start_race(player_char: CharacterData) -> void:
	if EconomyManager == null or not await EconomyManager.spend_coins(ENTRY_FEE, "neon_alley_race"):
		if _status:
			_status.text = "Not enough coins for entry."
		return
	var all_chars: Array[CharacterData] = []
	all_chars.append(player_char)
	all_chars.append_array(_ai_racers)
	var scores: Array[Dictionary] = []
	for c in all_chars:
		var totals := c.compute_total_stats()
		var spd_score: float = float(totals.get("spd", c.base_spd))
		var lck_variance: float = (randf() - 0.5) * (float(totals.get("lck", c.base_lck)) * 0.3)
		scores.append({"char": c, "score": spd_score + lck_variance})
	scores.sort_custom(func(a, b): return a["score"] > b["score"])
	var place: int = 1
	for i in range(scores.size()):
		if scores[i]["char"] == player_char:
			place = i + 1
			break
	await get_tree().create_timer(1.2).timeout
	var prize: int = 0
	match place:
		1: prize = ENTRY_FEE * 5
		2: prize = ENTRY_FEE * 2
		3: prize = ENTRY_FEE * 1
	if prize > 0:
		EconomyManager.add_coins(prize, "neon_alley_prize")
	if _status:
		_status.text = "Finished #%d — prize %d coins" % [place, prize]
	race_finished.emit(place, prize)
