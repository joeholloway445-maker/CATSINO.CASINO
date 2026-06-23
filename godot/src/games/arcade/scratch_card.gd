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

	card_complete.emit(payout > 0, payout)

func is_active() -> bool:
	return _active

func get_cells() -> Array[String]:
	return _cells.duplicate()
