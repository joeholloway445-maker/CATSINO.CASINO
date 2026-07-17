class_name PawPokerGame
extends Control

signal hand_result(outcome: String, payout: int)

const HAND_RANKS := ["High Card", "One Pair", "Two Pair", "Three of a Kind",
	"Straight", "Flush", "Full House", "Four of a Kind", "Straight Flush", "Royal Flush"]

@onready var hand_container: HBoxContainer = $VBox/HandContainer
@onready var deal_btn: Button = $VBox/Controls/DealBtn
@onready var draw_btn: Button = $VBox/Controls/DrawBtn
@onready var bet_spin: SpinBox = $VBox/Controls/BetSpin
@onready var result_label: Label = $VBox/ResultLabel

var _held: Array[bool] = [false, false, false, false, false]
var _cards: Array[Dictionary] = []
var _phase: String = "bet"  # bet, hold, done

func _ready() -> void:
	draw_btn.disabled = true
	deal_btn.pressed.connect(_deal)
	draw_btn.pressed.connect(_draw)

func _deal() -> void:
	if _phase != "bet":
		_reset()
		return
	NetworkManager.call_rpc("play_poker", {action="deal", bet=int(bet_spin.value)},
		func(result: Dictionary):
			if result.get("error"):
				NotificationUI.notify_error(result.error)
				return
			_cards = result.get("cards", [])
			_held = [false, false, false, false, false]
			_render_hand()
			_phase = "hold"
			deal_btn.text = "New Hand"
			deal_btn.disabled = true
			draw_btn.disabled = false
			result_label.text = "Select cards to HOLD, then Draw"
	)

func _draw() -> void:
	NetworkManager.call_rpc("play_poker", {action="draw", held=_held, bet=int(bet_spin.value)},
		func(result: Dictionary):
			if result.get("error"):
				NotificationUI.notify_error(result.error)
				return
			_cards = result.get("cards", [])
			var hand_name: String = str(result.get("hand_name", "High Card"))
			var payout: int = int(result.get("payout", 0))
			_render_hand()
			_phase = "done"
			draw_btn.disabled = true
			deal_btn.disabled = false
			result_label.text = "%s! Payout: %d chips" % [hand_name, payout]
			if payout > 0:
				NotificationUI.notify_win("♠ %s — %d chips" % [hand_name, payout])
				AchievementManager.check("win", payout)
				if hand_name == "Full House":
					AchievementManager.check("full_house")
			XPManager.award_game("poker", payout > 0)
			hand_result.emit(hand_name, payout)
	)

func _render_hand() -> void:
	for child in hand_container.get_children():
		child.queue_free()
	const SUITS := ["🐾", "🐱", "🌟", "🎭"]
	const VALUES := ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
	for i in range(_cards.size()):
		var card: Dictionary = _cards[i] as Dictionary
		var idx: int = int(card.get("index", 0))
		var val: String = VALUES[idx % 13]
		var suit: String = SUITS[idx / 13]
		var btn := Button.new()
		btn.text = "%s\n%s" % [val, suit]
		btn.custom_minimum_size = Vector2(60, 90)
		if _held[i]:
			btn.modulate = Color(1, 1, 0)
		btn.pressed.connect(func(): _toggle_hold(i))
		hand_container.add_child(btn)

func _toggle_hold(idx: int) -> void:
	if _phase != "hold":
		return
	_held[idx] = not _held[idx]
	_render_hand()

func _reset() -> void:
	_phase = "bet"
	_cards = []
	_held = [false, false, false, false, false]
	for child in hand_container.get_children():
		child.queue_free()
	result_label.text = ""
	deal_btn.text = "Deal"
