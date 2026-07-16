class_name CoinPusherGame
extends Node2D

# Coin pusher minigame — drop chips to push others off the edge.
# Always spends the bet in chips (no free-drop exploit).

@onready var result_label: Label = $UI/VBox/ResultLabel
@onready var drop_btn: Button = $UI/VBox/DropBtn
@onready var bet_spin: SpinBox = $UI/VBox/BetRow/BetSpin
@onready var coins_label: Label = $UI/VBox/CoinsOnBoard

var _coins_on_board := 20
var _drop_in_progress := false

func _ready() -> void:
	drop_btn.pressed.connect(_drop_coin)
	coins_label.text = "Chips on board: %d" % _coins_on_board

func _drop_coin() -> void:
	if _drop_in_progress:
		return
	var bet := int(bet_spin.value)
	if bet <= 0:
		result_label.text = "Set a bet first."
		return
	if EconomyManager == null or not EconomyManager.spend_currency_local("chips", bet, "coin_pusher"):
		result_label.text = "Insufficient chips."
		NotificationUI.notify_error("Need %d chips to drop." % bet)
		return

	_drop_in_progress = true
	drop_btn.disabled = true
	result_label.text = "Dropping..."

	await get_tree().create_timer(0.8).timeout

	var push_count := randi_range(0, 5)
	_coins_on_board += 1
	_coins_on_board = max(0, _coins_on_board - push_count)
	coins_label.text = "Chips on board: %d" % _coins_on_board

	if push_count > 0:
		var payout := int(floor(float(bet) * float(push_count) * 0.5))
		if payout > 0 and EconomyManager:
			EconomyManager.earn_currency_local("chips", payout, "coin_pusher_win")
		result_label.text = "Pushed %d! Won: %d chips" % [push_count, payout]
		if payout > 0:
			NotificationUI.notify_win("Coin Pusher: +%d chips!" % payout)
			AchievementManager.check("win", payout)
		XPManager.award_game("coin_pusher", payout > 0)
	else:
		result_label.text = "No chips pushed this time."
	_drop_in_progress = false
	drop_btn.disabled = false
