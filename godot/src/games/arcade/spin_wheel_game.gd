class_name SpinWheelGame
extends Control
# Fortune Wheel arcade game — visual spin + Nakama RPC payout

@onready var spin_btn: Button = $VBox/Controls/SpinBtn
@onready var bet_spin: SpinBox = $VBox/Controls/BetSpin
@onready var result_label: Label = $VBox/ResultLabel
@onready var segment_label: Label = $VBox/SegmentLabel
@onready var wheel_container: Control = $VBox/WheelContainer

const SEGMENTS := [
	"100 coins", "250 coins", "500 coins", "Try Again",
	"1000 coins", "2x Bet", "Lose Bet", "2500 coins",
	"JACKPOT!", "150 coins", "750 coins", "50 coins"
]

var _spinning := false
var _spin_speed := 0.0
var _current_angle := 0.0

func _ready() -> void:
	spin_btn.pressed.connect(_spin)

func _process(delta: float) -> void:
	if _spinning:
		_spin_speed = maxf(0.0, _spin_speed - delta * 180.0)
		_current_angle += _spin_speed * delta
		wheel_container.rotation_degrees = _current_angle
		if _spin_speed <= 0.0:
			_spinning = false

func _spin() -> void:
	if _spinning: return
	_spinning = true
	spin_btn.disabled = true
	result_label.text = "Spinning..."
	segment_label.text = ""

	_spin_speed = randf_range(600.0, 900.0)

	NetworkManager.call_rpc("draw_fortune", {bet=int(bet_spin.value)},
		func(result: Dictionary):
			if result.get("error"):
				NotificationUI.notify_error(result.error)
				spin_btn.disabled = false
				_spinning = false
				return
			var seg: String = result.get("segment", "Try Again")
			var payout: int = result.get("payout", 0)
			await get_tree().create_timer(3.0).timeout
			spin_btn.disabled = false
			segment_label.text = "▶ %s" % seg
			if payout > 0:
				result_label.text = "Won: +%d coins! 🎉" % payout
				NotificationUI.notify_win("Fortune Wheel: +%d!" % payout)
				AchievementManager.check("win", payout)
				QuestManager.update_progress("spin_5")
			else:
				result_label.text = "Better luck next spin!"
			XPManager.award_game("fortune_wheel", payout > 0)
	)
