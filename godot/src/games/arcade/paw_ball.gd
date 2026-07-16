extends Node
class_name PawBall
# Sports prediction game — bet on paw ball match outcomes
# Server confirms RNG result; client shows animated match

signal match_started(home: String, away: String)
signal match_result(home_score: int, away_score: int, winner: String, payout: int)
signal error_occurred(message: String)

const TEAMS = [
	"Neon Paws FC", "Claw United", "Void Strikers", "Royal Felines",
	"Wild Rovers", "Current FC", "Storm Claws", "Ember XI",
]

var _current_match: Dictionary = {}
var _bet: int = 0
var _player_pick: String = ""
var _match_info: Label
var _result_label: Label
var _bet_spin: SpinBox

func _ready() -> void:
	_match_info = get_node_or_null("VBoxContainer/MatchInfo") as Label
	_result_label = get_node_or_null("VBoxContainer/ResultLabel") as Label
	_bet_spin = get_node_or_null("VBoxContainer/BetRow/BetSpin") as SpinBox
	var home_btn := get_node_or_null("VBoxContainer/ButtonRow/HomeBtn") as Button
	var draw_btn := get_node_or_null("VBoxContainer/ButtonRow/DrawBtn") as Button
	var away_btn := get_node_or_null("VBoxContainer/ButtonRow/AwayBtn") as Button
	if home_btn:
		home_btn.pressed.connect(func() -> void: _play_pick("home"))
	if draw_btn:
		draw_btn.pressed.connect(func() -> void: _play_pick("draw"))
	if away_btn:
		away_btn.pressed.connect(func() -> void: _play_pick("away"))
	if not match_started.is_connected(_on_match_started_ui):
		match_started.connect(_on_match_started_ui)
	if not match_result.is_connected(_on_match_result_ui):
		match_result.connect(_on_match_result_ui)
	if not error_occurred.is_connected(_on_error_ui):
		error_occurred.connect(_on_error_ui)
	_preview_matchup()

func _preview_matchup() -> void:
	var home_idx := randi() % TEAMS.size()
	var away_idx := (home_idx + 1 + randi() % (TEAMS.size() - 1)) % TEAMS.size()
	if _match_info:
		_match_info.text = "%s vs %s — pick a result" % [TEAMS[home_idx], TEAMS[away_idx]]

func _play_pick(pick: String) -> void:
	var bet := int(_bet_spin.value) if _bet_spin else 100
	start_match(bet, pick)

func _on_match_started_ui(home: String, away: String) -> void:
	if _match_info:
		_match_info.text = "%s vs %s — playing..." % [home, away]
	if _result_label:
		_result_label.text = "Whistle blown..."

func _on_match_result_ui(home_score: int, away_score: int, winner: String, payout: int) -> void:
	if _result_label:
		_result_label.text = "Final %d-%d (%s). Payout: %d" % [home_score, away_score, winner, payout]
	if payout > 0 and NotificationUI:
		NotificationUI.notify_win("Paw Ball: +%d" % payout)
	_preview_matchup()

func _on_error_ui(message: String) -> void:
	if _result_label:
		_result_label.text = message
	if NotificationUI:
		NotificationUI.notify_error(message)

func start_match(bet: int, pick: String) -> void:
	if _current_match.get("active", false):
		error_occurred.emit("Match already in progress")
		return

	var home_idx = randi() % TEAMS.size()
	var away_idx = (home_idx + 1 + randi() % (TEAMS.size() - 1)) % TEAMS.size()

	_bet = bet
	_player_pick = pick
	_current_match = {
		"active": true,
		"home": TEAMS[home_idx],
		"away": TEAMS[away_idx],
	}

	match_started.emit(_current_match.home, _current_match.away)

	var payload = JSON.stringify({
		"bet": bet,
		"pick": pick,
		"home": _current_match.home,
		"away": _current_match.away,
	})
	NetworkManager.call_rpc("predict_match", payload, _on_result)

func _on_result(result: Dictionary) -> void:
	_current_match["active"] = false
	if not result.get("success", false):
		error_occurred.emit(result.get("error", "Server error"))
		return

	var home_score = result.get("home_score", 0)
	var away_score = result.get("away_score", 0)
	var winner = result.get("winner", "draw")
	var payout = result.get("payout", 0)

	match_result.emit(home_score, away_score, winner, payout)

func get_teams() -> Array[String]:
	return TEAMS

func pick_home() -> void:
	_player_pick = "home"

func pick_draw() -> void:
	_player_pick = "draw"

func pick_away() -> void:
	_player_pick = "away"
