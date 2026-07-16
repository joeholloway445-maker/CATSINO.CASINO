class_name BlackjackGame
extends Control

@onready var player_hand: HBoxContainer = $VBox/PlayerArea/Hand
@onready var dealer_hand: HBoxContainer = $VBox/DealerArea/Hand
@onready var player_value: Label = $VBox/PlayerArea/ValueLabel
@onready var dealer_value: Label = $VBox/DealerArea/ValueLabel
@onready var hit_btn: Button = $VBox/Controls/HitBtn
@onready var stand_btn: Button = $VBox/Controls/StandBtn
@onready var double_btn: Button = $VBox/Controls/DoubleBtn
@onready var deal_btn: Button = $VBox/Controls/DealBtn
@onready var bet_spin: SpinBox = $VBox/Controls/BetSpin
@onready var result_label: Label = $VBox/ResultLabel

const SUITS := ["🐾", "🐱", "🌟", "🎭"]
const VALUES := ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

func _ready() -> void:
	deal_btn.pressed.connect(_deal)
	hit_btn.pressed.connect(func(): _action("hit"))
	stand_btn.pressed.connect(func(): _action("stand"))
	double_btn.pressed.connect(func(): _action("double"))
	_set_game_buttons(false)
	var back := Button.new()
	back.text = "⬅ Back"
	back.position = Vector2(12, 12)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/world/paw_vegas_hub.tscn"))
	add_child(back)

func _deal() -> void:
	result_label.text = ""
	NetworkManager.call_rpc("play_blackjack", {action="deal", bet=int(bet_spin.value)},
		func(result: Dictionary):
			if result.get("error"):
				NotificationUI.notify_error(result.error)
				return
			_render_hands(result)
			_set_game_buttons(true)
			deal_btn.disabled = true
			if result.get("outcome") == "blackjack":
				_finish(result)
	)

func _action(act: String) -> void:
	NetworkManager.call_rpc("play_blackjack", {action=act, bet=int(bet_spin.value)},
		func(result: Dictionary):
			if result.get("error"):
				NotificationUI.notify_error(result.error)
				return
			_render_hands(result)
			if result.get("outcome"):
				_finish(result)
	)

func _render_hands(result: Dictionary) -> void:
	_render_hand(player_hand, result.get("player_cards", []))
	_render_hand(dealer_hand, result.get("dealer_cards", []))
	player_value.text = "Value: %d" % result.get("player_value", 0)
	dealer_value.text = "Dealer: %d" % result.get("dealer_value", 0)

func _render_hand(container: HBoxContainer, cards: Array) -> void:
	for child in container.get_children():
		child.queue_free()
	for card in cards:
		var idx: int = card if card is int else 0
		var lbl := Label.new()
		lbl.text = "%s%s" % [VALUES[idx % 13], SUITS[idx / 13]]
		lbl.add_theme_font_size_override("font_size", 24)
		container.add_child(lbl)

func _finish(result: Dictionary) -> void:
	_set_game_buttons(false)
	deal_btn.disabled = false
	var outcome := result.get("outcome", "")
	var payout: int = result.get("payout", 0)
	match outcome:
		"blackjack":
			result_label.text = "BLACKJACK! +%d 🃏" % payout
			AchievementManager.check("blackjack")
		"win": result_label.text = "You WIN! +%d 🎉" % payout
		"bust": result_label.text = "BUST! 💸"
		"dealer_bust": result_label.text = "Dealer busts! +%d 🎉" % payout
		"push": result_label.text = "PUSH — bet returned"
		"lose": result_label.text = "Dealer wins 😿"
	if payout > 0:
		NotificationUI.notify_win("Blackjack: +%d coins!" % payout)
		AchievementManager.check("win", payout)
	XPManager.award_game("blackjack", payout > 0)

func _set_game_buttons(enabled: bool) -> void:
	hit_btn.disabled = not enabled
	stand_btn.disabled = not enabled
	double_btn.disabled = not enabled
