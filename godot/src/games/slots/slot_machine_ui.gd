extends Control
class_name SlotMachineUI
# UI wrapper for the slot machine — handles bet controls, spin trigger, results

signal spin_won(amount: int)
signal spin_lost()

@onready var _reel1: Node = $ReelContainer/Reel1
@onready var _reel2: Node = $ReelContainer/Reel2
@onready var _reel3: Node = $ReelContainer/Reel3
@onready var _spin_btn: Button = $SpinButton
@onready var _result_label: Label = $ResultLabel
@onready var _bet_label: Label = $BetLabel

var _bet: int = 50
var _spinning: bool = false

func _ready() -> void:
	if _result_label == null:
		_result_label = get_node_or_null("ResultLabel") as Label
	if _bet_label == null:
		_bet_label = get_node_or_null("BetLabel") as Label
	_update_bet_label()
	var bet_down := get_node_or_null("BetDown") as Button
	if bet_down == null:
		bet_down = get_node_or_null("BetRow/BetDown") as Button
	var bet_up := get_node_or_null("BetUp") as Button
	if bet_up == null:
		bet_up = get_node_or_null("BetRow/BetUp") as Button
	if bet_down:
		bet_down.pressed.connect(_decrease_bet)
	if bet_up:
		bet_up.pressed.connect(_increase_bet)
	if _spin_btn:
		_spin_btn.pressed.connect(_on_spin_pressed)
	var back := Button.new()
	back.text = "⬅ Back"
	back.position = Vector2(12, 12)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/world/paw_vegas_hub.tscn"))
	add_child(back)

func _on_spin_pressed() -> void:
	if _spinning: return
	_spinning = true
	_spin_btn.disabled = true
	_result_label.text = "Spinning..."

	var payload = JSON.stringify({"bet": _bet, "game": "lucky_cat_jackpot"})
	NetworkManager.call_rpc("spin_slots", payload, _on_spin_result)

func _on_spin_result(result: Dictionary) -> void:
	_spinning = false
	_spin_btn.disabled = false

	if not result.get("success", false):
		_result_label.text = "Error: " + result.get("error", "?")
		return

	var symbols = result.get("symbols", ["🐱", "🐱", "🐱"])
	var payout = result.get("payout", 0)

	if _reel1: _reel1.set_symbol(symbols[0])
	if _reel2: _reel2.set_symbol(symbols[1])
	if _reel3: _reel3.set_symbol(symbols[2])

	if payout > 0:
		_result_label.text = "🎉 WIN: +%d 🪙" % payout
		spin_won.emit(payout)
	else:
		_result_label.text = "Try again!"
		spin_lost.emit()

func _decrease_bet() -> void:
	_bet = max(10, _bet - 10)
	_update_bet_label()

func _increase_bet() -> void:
	_bet = min(1000, _bet + 10)
	_update_bet_label()

func _update_bet_label() -> void:
	if _bet_label:
		_bet_label.text = "Bet: %d 🪙" % _bet
