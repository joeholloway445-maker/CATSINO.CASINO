class_name RaceGameManager
extends Node
# Coordinates the full race flow: lobby -> race -> result

signal race_started(frame_id: String, bet: int)
signal race_finished(position: int, payout: int)

@onready var race_ui: RaceUI = get_node_or_null("../CanvasLayer/RaceUI")
@onready var race_ai: RaceAI = get_node_or_null("RaceAI")

var _current_bet: int = 0
var _current_frame: String = "basic"

func _ready() -> void:
	# RaceUI resolves races itself (server RPC or local RaceAI sim); listen to
	# its result so achievements/XP/quest progress fire either way.
	if race_ui:
		race_ui.race_started.connect(func(frame_id: String, bet: int):
			_current_frame = frame_id
			_current_bet = bet
			race_started.emit(frame_id, bet))
		race_ui.race_finished.connect(func(position: int, payout: int):
			_on_race_result(position, payout, {}))

## Legacy programmatic entry point (bypasses RaceUI) — still server-only.
func start_race(frame_id: String, bet: int) -> void:
	_current_bet = bet
	_current_frame = frame_id
	race_started.emit(frame_id, bet)

	NetworkManager.call_rpc("start_race", {frame_id=frame_id, bet=bet},
		func(result: Dictionary):
			if result.get("error"):
				NotificationUI.notify_error(result.error)
				return
			var position: int = result.get("position", 4)
			var payout: int = result.get("payout", 0)
			_on_race_result(position, payout, result)
	)

func _on_race_result(position: int, payout: int, result: Dictionary) -> void:
	race_finished.emit(position, payout)
	AchievementManager.check("race_enter")
	if position <= 3:
		AchievementManager.check("race_podium")
	if payout > 0:
		NotificationUI.notify_win("Race %d place! +%d coins 🏁" % [position, payout])
		AchievementManager.check("win", payout)
	else:
		NotificationUI.notify_error("Race finished: %d place. No payout." % position)
	XPManager.award_game("race", position <= 3)
	QuestManager.update_progress("neon_alley_racer")
	if position == 1:
		QuestManager.update_progress("race_champion")
