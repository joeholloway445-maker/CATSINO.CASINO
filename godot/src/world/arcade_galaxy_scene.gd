extends Node

signal minigame_result(game: String, win: int)

const SYMBOLS: Array[String] = ["🐱", "⭐", "💎", "🎰", "🍀", "🔔", "7️⃣", "🌙"]
const SYMBOL_PAYOUTS: Dictionary = {
	"🐱": 5, "⭐": 3, "💎": 20, "🎰": 10,
	"🍀": 8, "🔔": 4, "7️⃣": 15, "🌙": 2
}

var _current_number: int = 5
var _coin_grid: Dictionary = {}
var _status: Label
var _bet_spin: SpinBox

func _ready() -> void:
	_init_coin_grid()
	seed(Time.get_ticks_msec())
	_build_station_ui()

func _init_coin_grid() -> void:
	for x in range(10):
		for y in range(8):
			_coin_grid[Vector2i(x, y)] = randf() < 0.3

func _build_station_ui() -> void:
	var layer := get_node_or_null("UILayer") as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "UILayer"
		add_child(layer)
	var hud := layer.get_node_or_null("ArcadeHUD") as Control
	if hud == null:
		hud = Control.new()
		hud.name = "ArcadeHUD"
		hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer.add_child(hud)
	for c in hud.get_children():
		c.queue_free()

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	hud.add_child(root)

	var title := Label.new()
	title.text = "👾 ARCADE GALAXY"
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	var sub := Label.new()
	sub.text = "Pick a cabinet. Coins in, chaos out."
	sub.modulate = Color(0.75, 0.75, 0.8)
	root.add_child(sub)

	var bet_row := HBoxContainer.new()
	root.add_child(bet_row)
	var bet_lbl := Label.new()
	bet_lbl.text = "Bet:"
	bet_row.add_child(bet_lbl)
	_bet_spin = SpinBox.new()
	_bet_spin.min_value = 10
	_bet_spin.max_value = 500
	_bet_spin.step = 10
	_bet_spin.value = 25
	bet_row.add_child(_bet_spin)

	_status = Label.new()
	_status.text = "Ready."
	root.add_child(_status)

	var stations := [
		{"label": "🪙 Coin Flip", "fn": _ui_coin_flip},
		{"label": "⬆️ Higher / Lower", "fn": _ui_higher_lower},
		{"label": "🎟️ Scratch Card Cabinet", "fn": _ui_scratch},
		{"label": "🎡 Fortune Wheel", "fn": _ui_cat_wheel},
		{"label": "🪙 Coin Pusher Floor", "fn": _ui_coin_pusher},
		{"label": "🃏 Blackjack Table", "fn": _ui_blackjack},
	]
	for s in stations:
		var btn := Button.new()
		btn.text = s.label
		var callable: Callable = s.fn
		btn.pressed.connect(callable)
		root.add_child(btn)

	var back := Button.new()
	back.text = "⬅ Back to Menu"
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	root.add_child(back)

func _bet() -> int:
	return int(_bet_spin.value) if _bet_spin else 25

func _set_status(text: String) -> void:
	if _status:
		_status.text = text

func _ui_coin_flip() -> void:
	await play_coin_flip(_bet())

func _ui_higher_lower() -> void:
	var guess := "higher" if randf() > 0.5 else "lower"
	var result := await play_higher_lower(_bet(), guess)
	if result.has("error"):
		_set_status(str(result.error))
	else:
		_set_status("Was %d → %d (%s). Payout %d" % [
			result.get("previous", 0), result.get("current", 0),
			guess, result.get("payout", 0)])

func _ui_scratch() -> void:
	var result := await play_scratch_card(_bet())
	if result.has("error"):
		_set_status(str(result.error))
	else:
		_set_status("Scratch %s — +%d" % [str(result.get("symbols", [])), int(result.get("payout", 0))])

func _ui_cat_wheel() -> void:
	play_cat_wheel()

func _ui_coin_pusher() -> void:
	get_tree().change_scene_to_file("res://scenes/games/arcade/coin_pusher.tscn")

func _ui_blackjack() -> void:
	get_tree().change_scene_to_file("res://scenes/games/arcade/blackjack.tscn")

func play_coin_flip(bet: int) -> bool:
	if EconomyManager == null or not EconomyManager.spend_currency_local("chips", bet, "arcade_coin_flip"):
		_set_status("Not enough chips")
		return false
	var win: bool = randf() > 0.5
	var payout: int = bet * 2 if win else 0
	if win:
		EconomyManager.earn_currency_local("chips", payout, "arcade_coin_flip_win")
	_set_status("Coin flip: %s (+%d chips)" % ["WIN" if win else "lose", payout])
	minigame_result.emit("coin_flip", payout)
	return win

func play_higher_lower(bet: int, guess: String) -> Dictionary:
	if EconomyManager == null or not EconomyManager.spend_currency_local("chips", bet, "arcade_hl"):
		return {"error": "insufficient_funds"}
	var previous: int = _current_number
	_current_number = randi_range(1, 10)
	var correct: bool
	if guess == "higher":
		correct = _current_number > previous
	elif guess == "lower":
		correct = _current_number < previous
	else:
		return {"error": "invalid_guess"}
	var payout: int = 0
	if correct:
		payout = bet * 2
		EconomyManager.earn_currency_local("chips", payout, "arcade_hl_win")
	minigame_result.emit("higher_lower", payout)
	return {
		"previous": previous,
		"current": _current_number,
		"correct": correct,
		"payout": payout
	}

func play_scratch_card(bet: int) -> Dictionary:
	if EconomyManager == null or not EconomyManager.spend_currency_local("chips", bet, "arcade_scratch"):
		return {"error": "insufficient_funds"}
	var revealed: Array[String] = []
	for i in range(3):
		revealed.append(SYMBOLS[randi() % SYMBOLS.size()])
	var payout: int = 0
	if revealed[0] == revealed[1] and revealed[1] == revealed[2]:
		payout = bet * int(SYMBOL_PAYOUTS.get(revealed[0], 2))
	elif revealed[0] == revealed[1] or revealed[1] == revealed[2] or revealed[0] == revealed[2]:
		payout = bet * 2
	if payout > 0:
		EconomyManager.earn_currency_local("chips", payout, "arcade_scratch_win")
	minigame_result.emit("scratch_card", payout)
	return {"symbols": revealed, "payout": payout}

func play_cat_wheel() -> void:
	get_tree().change_scene_to_file("res://scenes/games/arcade/fortune_wheel.tscn")
