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
