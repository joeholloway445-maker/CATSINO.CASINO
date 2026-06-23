extends Node

signal minigame_result(game: String, win: int)

const SYMBOLS: Array[String] = ["🐱", "⭐", "💎", "🎰", "🍀", "🔔", "7️⃣", "🌙"]
const SYMBOL_PAYOUTS: Dictionary = {
	"🐱": 5, "⭐": 3, "💎": 20, "🎰": 10,
	"🍀": 8, "🔔": 4, "7️⃣": 15, "🌙": 2
}

var _current_number: int = 5
var _coin_grid: Dictionary = {}

func _ready() -> void:
	_init_coin_grid()
	seed(Time.get_ticks_msec())

func _init_coin_grid() -> void:
	for x in range(10):
		for y in range(8):
			_coin_grid[Vector2i(x, y)] = randf() < 0.3

# --- Coin Flip ---
func play_coin_flip(bet: int) -> bool:
	if not EconomyManager.spend_coins(bet):
		return false
	seed(Time.get_unix_time_from_system() * 1000 + randi())
	var win: bool = randf() > 0.5
	var payout: int = bet * 2 if win else 0
	if win:
		EconomyManager.add_coins(payout)
	minigame_result.emit("coin_flip", payout)
	return win

# --- Higher / Lower ---
func play_higher_lower(bet: int, guess: String) -> Dictionary:
	if not EconomyManager.spend_coins(bet):
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
		EconomyManager.add_coins(payout)
	minigame_result.emit("higher_lower", payout)
	return {
		"previous": previous,
		"current": _current_number,
		"correct": correct,
		"payout": payout
	}

# --- Scratch Card ---
func play_scratch_card(bet: int) -> Dictionary:
	if not EconomyManager.spend_coins(bet):
		return {"error": "insufficient_funds"}
	var revealed: Array[String] = []
	for i in range(3):
		revealed.append(SYMBOLS[randi() % SYMBOLS.size()])
	var payout: int = 0
	if revealed[0] == revealed[1] and revealed[1] == revealed[2]:
		payout = bet * SYMBOL_PAYOUTS.get(revealed[0], 2)
	elif revealed[0] == revealed[1] or revealed[1] == revealed[2] or revealed[0] == revealed[2]:
		payout = bet * 2
	if payout > 0:
		EconomyManager.add_coins(payout)
	minigame_result.emit("scratch_card", payout)
	return {"symbols": revealed, "payout": payout}

# --- Cat Wheel ---
func play_cat_wheel() -> void:
	DistrictManager.launch_district(DistrictManager.Districts.PAW_VEGAS)
