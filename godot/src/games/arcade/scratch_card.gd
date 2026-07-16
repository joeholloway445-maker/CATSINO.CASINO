extends Node
class_name ScratchCard
# Scratch card game — 9 cells, reveal all to find 3-of-a-kind wins
# Server generates the card; client handles reveal animation

signal card_generated(cells: Array[String])
signal cell_revealed(index: int, symbol: String)
signal card_complete(winning: bool, payout: int)
signal error_occurred(message: String)

const SYMBOLS = ["🐱", "🌟", "🎭", "🐾", "💎", "🎰"]
const PAYOUT_TABLE = {
	"🐱": 2,
	"🌟": 3,
	"🎭": 3,
	"🐾": 5,
	"💎": 10,
	"🎰": 20,
}

var _cells: Array[String] = []
var _revealed: Array[bool] = []
var _bet: int = 0
var _active: bool = false
var _grid: GridContainer
var _result_label: Label
var _cell_buttons: Array[Button] = []

func _ready() -> void:
	_grid = get_node_or_null("VBoxContainer/Grid") as GridContainer
	_result_label = get_node_or_null("VBoxContainer/ResultLabel") as Label
	var buy_btn := get_node_or_null("VBoxContainer/BuyBtn") as Button
	if buy_btn and not buy_btn.pressed.is_connected(_on_buy_pressed):
		buy_btn.pressed.connect(_on_buy_pressed)
	if not card_generated.is_connected(_on_card_generated_ui):
		card_generated.connect(_on_card_generated_ui)
	if not cell_revealed.is_connected(_on_cell_revealed_ui):
		cell_revealed.connect(_on_cell_revealed_ui)
	if not card_complete.is_connected(_on_card_complete_ui):
		card_complete.connect(_on_card_complete_ui)
	if not error_occurred.is_connected(_on_error_ui):
		error_occurred.connect(_on_error_ui)

func _on_buy_pressed() -> void:
	buy_card(50)

func _on_card_generated_ui(_cells_in: Array) -> void:
	_rebuild_grid()
	if _result_label:
		_result_label.text = "Scratch the cells!"

func _rebuild_grid() -> void:
	if _grid == null:
		return
	for c in _grid.get_children():
		c.queue_free()
	_cell_buttons.clear()
	for i in 9:
		var btn := Button.new()
		btn.text = "❓"
		btn.custom_minimum_size = Vector2(72, 72)
		var idx := i
		btn.pressed.connect(func() -> void: reveal(idx))
		_grid.add_child(btn)
		_cell_buttons.append(btn)

func _on_cell_revealed_ui(index: int, symbol: String) -> void:
	if index >= 0 and index < _cell_buttons.size():
		_cell_buttons[index].text = symbol
		_cell_buttons[index].disabled = true

func _on_card_complete_ui(winning: bool, payout: int) -> void:
	if _result_label:
		_result_label.text = ("WIN +%d coins!" % payout) if winning else "No match — try again."
	if winning and NotificationUI:
		NotificationUI.notify_win("Scratch: +%d" % payout)

func _on_error_ui(message: String) -> void:
	if _result_label:
		_result_label.text = message
	if NotificationUI:
		NotificationUI.notify_error(message)

func buy_card(bet: int) -> void:
	if _active:
		error_occurred.emit("Card already active")
		return
	_bet = bet
	_revealed.resize(9)
	_revealed.fill(false)
	_active = true
	var payload = JSON.stringify({"bet": bet, "game": "scratch_card"})
	NetworkManager.call_rpc("buy_scratch_card", payload, _on_card_received)

func _on_card_received(result: Dictionary) -> void:
	if not result.get("success", false):
		error_occurred.emit(result.get("error", "Server error"))
		_active = false
		return

	var raw_cells = result.get("cells", [])
	_cells.clear()
	for c in raw_cells:
		_cells.append(str(c))

	card_generated.emit(_cells)

func reveal(index: int) -> void:
	if not _active or index < 0 or index >= 9: return
	if _revealed[index]: return
	_revealed[index] = true
	cell_revealed.emit(index, _cells[index] if index < _cells.size() else "?")

	if _revealed.all(func(r): return r):
		_check_win()

func reveal_all() -> void:
	for i in range(9):
		reveal(i)

func _check_win() -> void:
	_active = false
	# Count symbol occurrences
	var counts: Dictionary = {}
	for s in _cells:
		counts[s] = counts.get(s, 0) + 1

	var payout = 0
	for sym in counts:
		if counts[sym] >= 3:
			payout = int(_bet * PAYOUT_TABLE.get(sym, 1))
			break

	if payout > 0 and EconomyManager:
		EconomyManager.add_coins(payout, "scratch_win")
	card_complete.emit(payout > 0, payout)

func is_active() -> bool:
	return _active

func get_cells() -> Array[String]:
	return _cells.duplicate()
