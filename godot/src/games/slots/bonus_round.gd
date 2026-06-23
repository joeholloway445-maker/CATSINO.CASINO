extends Node

signal bonus_complete(total_win: int)

const FREE_SPINS: int = 5
const MULTIPLIER: int = 2
const SYMBOLS: Array[String] = ["🐱", "⭐", "💎", "🎰", "🍀", "🔔", "7️⃣", "🌙"]
const REEL_SIZE: int = 3

var _base_bet: int = 0
var _spins_remaining: int = 0
var _total_win: int = 0
var _is_running: bool = false
var _countdown_label: Label

func _ready() -> void:
	_countdown_label = Label.new()
	_countdown_label.text = "FREE SPINS: 0 remaining"
	add_child(_countdown_label)

func start_bonus(base_bet: int) -> void:
	if _is_running:
		return
	_is_running = true
	_base_bet = base_bet
	_spins_remaining = FREE_SPINS
	_total_win = 0
	_run_bonus_spins()

func _run_bonus_spins() -> void:
	while _spins_remaining > 0:
		_update_countdown()
		await get_tree().create_timer(0.8).timeout
		var spin_result = _spin_reels()
		var win = _evaluate_spin(spin_result) * MULTIPLIER
		_total_win += win
		_spins_remaining -= 1
	_update_countdown()
	_is_running = false
	bonus_complete.emit(_total_win)
	if _total_win > 0:
		EconomyManager.add_coins(_total_win)

func _update_countdown() -> void:
	if _countdown_label:
		_countdown_label.text = "FREE SPINS: %d remaining" % _spins_remaining

func _spin_reels() -> Array[String]:
	var result: Array[String] = []
	for i in range(REEL_SIZE):
		result.append(SYMBOLS[randi() % SYMBOLS.size()])
	return result

func _evaluate_spin(reels: Array[String]) -> int:
	if reels[0] == reels[1] and reels[1] == reels[2]:
		match reels[0]:
			"💎": return _base_bet * 20
			"7️⃣": return _base_bet * 15
			"🎰": return _base_bet * 10
			"🍀": return _base_bet * 8
			"🐱": return _base_bet * 5
			"⭐": return _base_bet * 3
			"🔔": return _base_bet * 4
			_: return _base_bet * 2
	if reels[0] == reels[1] or reels[1] == reels[2] or reels[0] == reels[2]:
		return _base_bet
	return 0
