extends Node
class_name PvPArenaSystem

signal match_created(match_id: String)
signal match_started(match_id: String)
signal match_ended(match_id: String, winner_id: String)
signal ranked_rating_updated(player_id: String, new_rating: int)
signal tournament_started(tournament_id: String)

const LADDER_TIERS = {
	"bronze": {"min_rating": 0, "max_rating": 999, "rewards": 10},
	"silver": {"min_rating": 1000, "max_rating": 1999, "rewards": 25},
	"gold": {"min_rating": 2000, "max_rating": 2999, "rewards": 50},
	"platinum": {"min_rating": 3000, "max_rating": 3999, "rewards": 100},
	"diamond": {"min_rating": 4000, "max_rating": 4999, "rewards": 200},
	"grandmaster": {"min_rating": 5000, "max_rating": 99999, "rewards": 500}
}

const MATCHMAKING_POOLS = {
	"casual": {
		"name": "Casual Matches",
		"rating_window": 500,
		"description": "Practice and have fun"
	},
	"ranked": {
		"name": "Ranked Ladder",
		"rating_window": 200,
		"description": "Climb the global ladder"
	},
	"competitive": {
		"name": "Competitive Circuit",
		"rating_window": 100,
		"min_rating": 3000,
		"description": "Elite players only"
	},
	"tournament": {
		"name": "Tournament",
		"description": "Seasonal tournaments"
	}
}

var _active_matches: Dictionary = {}
var _player_ratings: Dictionary = {}
var _match_history: Array[Dictionary] = []
var _leaderboard: Array[Dictionary] = []
var _active_tournaments: Dictionary = {}

func _ready() -> void:
	pass

func create_match(player1_id: String, player2_id: String, mode: String = "casual") -> String:
	var match_id = "%s_vs_%s_%d" % [player1_id, player2_id, randi()]

	_active_matches[match_id] = {
		"match_id": match_id,
		"player1_id": player1_id,
		"player2_id": player2_id,
		"mode": mode,
		"status": "waiting",
		"created_at": Time.get_ticks_msec(),
		"started_at": 0,
		"ended_at": 0,
		"winner": null
	}

	match_created.emit(match_id)
	return match_id

func start_match(match_id: String) -> bool:
	if match_id not in _active_matches:
		return false

	_active_matches[match_id]["status"] = "in_progress"
	_active_matches[match_id]["started_at"] = Time.get_ticks_msec()
	match_started.emit(match_id)
	return true

func end_match(match_id: String, winner_id: String) -> bool:
	if match_id not in _active_matches:
		return false

	var m: Dictionary = _active_matches[match_id]
	m["status"] = "completed"
	m["ended_at"] = Time.get_ticks_msec()
	m["winner"] = winner_id

	# Update ratings
	var loser_id := str(m["player1_id"] if winner_id == m["player2_id"] else m["player2_id"])
	_update_ratings(winner_id, loser_id, str(m["mode"]))

	# Record in history
	_match_history.append(m.duplicate())

	# Update leaderboard
	_update_leaderboard()

	match_ended.emit(match_id, winner_id)
	return true

func _update_ratings(winner_id: String, loser_id: String, mode: String) -> void:
	if mode == "casual":
		return  # No rating changes in casual

	var winner_rating := int(_player_ratings.get(winner_id, 1500))
	var loser_rating := int(_player_ratings.get(loser_id, 1500))

	# ELO-style rating update
	var k_factor = 32  # Standard K-factor
	var expected_winner = 1.0 / (1.0 + pow(10.0, (loser_rating - winner_rating) / 400.0))
	var expected_loser = 1.0 / (1.0 + pow(10.0, (winner_rating - loser_rating) / 400.0))

	var new_winner_rating = int(winner_rating + k_factor * (1.0 - expected_winner))
	var new_loser_rating = int(loser_rating + k_factor * (0.0 - expected_loser))

	_player_ratings[winner_id] = new_winner_rating
	_player_ratings[loser_id] = new_loser_rating

	ranked_rating_updated.emit(winner_id, new_winner_rating)
	ranked_rating_updated.emit(loser_id, new_loser_rating)

func _update_leaderboard() -> void:
	_leaderboard.clear()

	for player_id in _player_ratings.keys():
		var rating := int(_player_ratings[player_id])
		_leaderboard.append({
			"player_id": player_id,
			"rating": rating,
			"tier": _get_tier_for_rating(rating),
			"wins": _count_wins(player_id),
			"losses": _count_losses(player_id)
		})

	# Sort by rating descending
	_leaderboard.sort_custom(func(a, b):
		return a["rating"] > b["rating"]
	)

func _get_tier_for_rating(rating: int) -> String:
	for tier in LADDER_TIERS.keys():
		var tier_data = LADDER_TIERS[tier]
		if rating >= tier_data["min_rating"] and rating <= tier_data["max_rating"]:
			return tier
	return "bronze"

func _count_wins(player_id: String) -> int:
	var wins = 0
	for m in _match_history:
		if m["winner"] == player_id:
			wins += 1
	return wins

func _count_losses(player_id: String) -> int:
	var losses = 0
	for m in _match_history:
		if (m["player1_id"] == player_id or m["player2_id"] == player_id) and m["winner"] != player_id:
			losses += 1
	return losses

func find_opponent(player_id: String, mode: String = "ranked") -> String:
	if mode not in MATCHMAKING_POOLS:
		return ""

	var pool = MATCHMAKING_POOLS[mode]
	var player_rating = _player_ratings.get(player_id, 1500)
	var rating_window = pool.get("rating_window", 200)

	# Find all players in rating window
	var candidates = []
	for other_player in _player_ratings.keys():
		if other_player == player_id:
			continue

		var other_rating = _player_ratings[other_player]
		if abs(other_rating - player_rating) <= rating_window:
			candidates.append(other_player)

	if candidates.is_empty():
		return ""

	# Return random opponent
	return candidates[randi() % candidates.size()]

func create_tournament(tournament_id: String, format: String = "single_elimination", max_players: int = 8) -> bool:
	_active_tournaments[tournament_id] = {
		"tournament_id": tournament_id,
		"format": format,
		"max_players": max_players,
		"participants": [],
		"brackets": [],
		"status": "recruiting",
		"created_at": Time.get_ticks_msec()
	}

	tournament_started.emit(tournament_id)
	return true

func join_tournament(tournament_id: String, player_id: String) -> bool:
	if tournament_id not in _active_tournaments:
		return false

	var tournament = _active_tournaments[tournament_id]

	if tournament["participants"].size() >= tournament["max_players"]:
		return false

	if player_id in tournament["participants"]:
		return false

	tournament["participants"].append(player_id)
	return true

func get_player_rating(player_id: String) -> int:
	return int(_player_ratings.get(player_id, 1500))

func get_player_tier(player_id: String) -> String:
	return _get_tier_for_rating(get_player_rating(player_id))

func get_leaderboard(limit: int = 100) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for i in range(mini(limit, _leaderboard.size())):
		entries.append(_leaderboard[i])
	return entries

func get_match(match_id: String) -> Dictionary:
	return _active_matches.get(match_id, {})

func get_match_history(player_id: String, limit: int = 10) -> Array[Dictionary]:
	var history: Array[Dictionary] = []
	for m in _match_history:
		if (m["player1_id"] == player_id or m["player2_id"] == player_id) and m["status"] == "completed":
			history.append(m)

	var entries: Array[Dictionary] = []
	for i in range(mini(limit, history.size())):
		entries.append(history[i])
	return entries

# ── Save/Load ──────────────────────────────────────────────────────────────
func save_state() -> Dictionary:
	return {
		"player_ratings": _player_ratings.duplicate(),
		"match_history": _match_history.duplicate(true),
		"leaderboard": _leaderboard.duplicate(true)
	}

func load_state(data: Dictionary) -> void:
	var ratings = data.get("player_ratings", {})
	_player_ratings = ratings if ratings is Dictionary else {}

	var hist = data.get("match_history", [])
	_match_history.clear()
	if hist is Array:
		for item in hist:
			if item is Dictionary:
				_match_history.append(item)

	var board = data.get("leaderboard", [])
	_leaderboard.clear()
	if board is Array:
		for item in board:
			if item is Dictionary:
				_leaderboard.append(item)
