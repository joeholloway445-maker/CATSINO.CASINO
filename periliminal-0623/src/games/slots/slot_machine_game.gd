extends Control

class_name SlotMachineGame

# ─── Signals ─────────────────────────────────────────────────────────────────
signal spin_complete(win_amount: int)

# ─── Payout table ─────────────────────────────────────────────────────────────
const PAYOUT_MULTIPLIERS: Dictionary = {
	"VOID":  50,
	"CROWN": 20,
	"STAR":  10,
	"CAT":    8,
	"FISH":   5,
	"COIN":   4,
	"YARN":   3,
	"BOWL":   2,
}

# ─── Configuration ────────────────────────────────────────────────────────────
@export var default_bet: int = 50
@export var reel_spin_duration: float = 2.0
@export var reel_stagger_delay: float = 0.4

# ─── Child node references ────────────────────────────────────────────────────
@onready var reel_0: SlotReel = $ReelsContainer/Reel0
@onready var reel_1: SlotReel = $ReelsContainer/Reel1
@onready var reel_2: SlotReel = $ReelsContainer/Reel2
@onready var spin_button: Button = $ControlPanel/SpinButton
@onready var bet_input: SpinBox = $ControlPanel/BetInput
@onready var result_label: Label = $ResultLabel
@onready var balance_label: Label = $ControlPanel/BalanceLabel
@onready var http_client: HTTPClient = $HTTPClientNode  # HttpClient autoload/child

# Internal
var _spinning: bool = false
var _reels_stopped: int = 0
var _stopped_symbols: Array[String] = ["", "", ""]
var _current_bet: int = 0

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	spin_button.pressed.connect(_on_spin_button_pressed)
	bet_input.value = default_bet
	bet_input.min_value = 10
	bet_input.max_value = 10000
	bet_input.step = 10

	reel_0.reel_stopped.connect(func(sym: String) -> void: _on_reel_stopped(0, sym))
	reel_1.reel_stopped.connect(func(sym: String) -> void: _on_reel_stopped(1, sym))
	reel_2.reel_stopped.connect(func(sym: String) -> void: _on_reel_stopped(2, sym))

	spin_complete.connect(func(amount: int) -> void:
		if amount > 0 and is_instance_valid(get_tree()):
			var hud := get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_win_popup"):
				hud.show_win_popup(amount, float(amount) / float(max(_current_bet, 1)))
	)

	_refresh_balance_label()

# ─── Spin flow ────────────────────────────────────────────────────────────────
func _on_spin_button_pressed() -> void:
	if _spinning:
		return
	spin()

func spin() -> void:
	_current_bet = int(bet_input.value)

	if not EconomyManager.can_spend_coins(_current_bet):
		result_label.text = "Not enough coins!"
		result_label.modulate = Color.RED
		return

	_spinning = true
	_reels_stopped = 0
	_stopped_symbols = ["", "", ""]
	spin_button.disabled = true
	result_label.text = "Spinning..."
	result_label.modulate = Color.WHITE

	# Deduct bet immediately (server-authoritative flow follows)
	EconomyManager.spend_coins_local(_current_bet)
	_refresh_balance_label()

	# Start all three reels
	reel_0.spin(reel_spin_duration)
	reel_1.spin(reel_spin_duration + reel_stagger_delay)
	reel_2.spin(reel_spin_duration + reel_stagger_delay * 2.0)

	# Fire off server request concurrently; results determine stop symbols
	_request_spin_result()

func _request_spin_result() -> void:
	# Use CasinoHTTPClient to call Next.js API
	var response: Dictionary = await CasinoHTTPClient.spin_slots(_current_bet)
	if not response.get("ok", false):
		# Fallback: generate result locally (best-effort, not authoritative)
		var symbols := SlotReel.SYMBOLS
		_apply_spin_result([
			symbols[randi() % symbols.size()],
			symbols[randi() % symbols.size()],
			symbols[randi() % symbols.size()],
		], 0)
		return

	var data: Dictionary = response.get("data", {})
	var result_symbols: Array = data.get("symbols", [])
	var server_win: int = data.get("win_amount", 0)

	if result_symbols.size() < 3:
		result_symbols = ["CAT", "CAT", "CAT"]

	_apply_spin_result(result_symbols, server_win)

func _apply_spin_result(symbols: Array, server_win_amount: int) -> void:
	# Stop reels staggered with a short delay between each
	await get_tree().create_timer(reel_spin_duration - 0.1).timeout
	reel_0.stop_at(symbols[0])
	await get_tree().create_timer(reel_stagger_delay).timeout
	reel_1.stop_at(symbols[1])
	await get_tree().create_timer(reel_stagger_delay).timeout
	reel_2.stop_at(symbols[2])
	# Actual resolution happens in _on_reel_stopped once all 3 complete

func _on_reel_stopped(index: int, symbol: String) -> void:
	_stopped_symbols[index] = symbol
	_reels_stopped += 1

	if _reels_stopped < 3:
		return

	# All reels stopped — evaluate
	_spinning = false
	spin_button.disabled = false
	_evaluate_result()

func _evaluate_result() -> void:
	var s0 := _stopped_symbols[0]
	var s1 := _stopped_symbols[1]
	var s2 := _stopped_symbols[2]

	var win_amount: int = 0
	if s0 == s1 and s1 == s2:
		var mult: int = PAYOUT_MULTIPLIERS.get(s0, 1)
		win_amount = _current_bet * mult
		result_label.text = "🎉 JACKPOT! %s %s %s  +%d Coins!" % [s0, s1, s2, win_amount]
		result_label.modulate = Color(1.0, 0.85, 0.1)
	elif s0 == s1 or s1 == s2 or s0 == s2:
		win_amount = int(_current_bet * 1.5)
		result_label.text = "Near miss pair!  +%d Coins" % win_amount
		result_label.modulate = Color(0.8, 1.0, 0.6)
	else:
		result_label.text = "%s  %s  %s  — No win" % [s0, s1, s2]
		result_label.modulate = Color(0.7, 0.7, 0.7)

	if win_amount > 0:
		EconomyManager.add_coins_local(win_amount)
		_refresh_balance_label()

	spin_complete.emit(win_amount)

func _refresh_balance_label() -> void:
	if is_instance_valid(balance_label):
		balance_label.text = "Balance: %d Coins" % EconomyManager.get_coins()
