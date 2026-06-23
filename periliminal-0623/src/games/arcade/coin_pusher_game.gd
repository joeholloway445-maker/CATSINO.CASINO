class_name CoinPusherGame
extends Node2D

# Coin pusher minigame — drop coins to push others off the edge
# Visual-only simulation; payout calculated server-side

@onready var result_label: Label = $UI/ResultLabel
@onready var drop_btn: Button = $UI/DropBtn
@onready var bet_spin: SpinBox = $UI/BetSpin
@onready var coins_label: Label = $UI/CoinsOnBoard

var _coins_on_board := 20
var _drop_in_progress := false

func _ready() -> void:
	drop_btn.pressed.connect(_drop_coin)
	coins_label.text = "Coins on board: %d" % _coins_on_board

func _drop_coin() -> void:
	if _drop_in_progress:
		return
	_drop_in_progress = true
	drop_btn.disabled = true
	result_label.text = "Dropping..."

	await get_tree().create_timer(0.8).timeout

	var push_count := randi_range(0, 5)
	_coins_on_board += 1
	_coins_on_board = max(0, _coins_on_board - push_count)
	coins_label.text = "Coins on board: %d" % _coins_on_board

	if push_count > 0:
		var payout_request := push_count * int(bet_spin.value)
		NetworkManager.call_rpc("spin_slots", {bet=int(bet_spin.value), multiplier=float(push_count) / 2.0},
			func(result: Dictionary):
				var payout: int = result.get("payout", 0)
				result_label.text = "Pushed %d coins! Won: %d" % [push_count, payout]
				if payout > 0:
					NotificationUI.notify_win("Coin Pusher: +%d!" % payout)
					AchievementManager.check("win", payout)
				XPManager.award_game("coin_pusher", payout > 0)
				_drop_in_progress = false
				drop_btn.disabled = false
		)
	else:
		result_label.text = "No coins pushed this time."
		_drop_in_progress = false
		drop_btn.disabled = false
