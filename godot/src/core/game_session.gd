class_name GameSession
extends Node
# Tracks the current active game session state (which game, active bets, etc.)

signal session_started(game_id: String)
signal session_ended(game_id: String, won: bool, payout: int)

var current_game: String = ""
var session_start_time: float = 0.0
var total_bet_this_session: int = 0
var total_won_this_session: int = 0
var _loss_streak := 0
var games_played: int = 0

func start(game_id: String) -> void:
	current_game = game_id
	session_start_time = Time.get_unix_time_from_system()
	session_started.emit(game_id)

func record_result(won: bool, bet: int, payout: int) -> void:
	total_bet_this_session += bet
	total_won_this_session += payout
	games_played += 1
	session_ended.emit(current_game, won, payout)
	AchievementManager.check("big_spender", total_bet_this_session)
	# spend_5000 (side_004) counts cumulative coins bet, not a threshold flag.
	QuestManager.update_progress("spend_5000", bet)
	QuestManager.update_progress("play_game")
	# Psychology: gambling under pressure. Pressure = bet vs bankroll;
	# streak = consecutive losses walking in. Hope files it; Supabase keeps it.
	var balance := EconomyManager.get_balance("chips") + EconomyManager.get_coins()
	_loss_streak = 0 if won else _loss_streak + 1
	Hope.record("gambling", {
		"game": current_game, "bet": bet, "payout": payout,
		"balance_before": balance + bet - payout, "balance_after": balance,
		"streak": _loss_streak,
		"pressure": float(bet) / maxf(balance + bet - payout, 1.0),
	})
	EconomyManager.earn_prestige(5 if won else 2, "gameplay")
	if won:
		QuestManager.update_progress("win_game")
	if payout >= 500:
		QuestManager.update_progress("win_500")

func get_net() -> int:
	return total_won_this_session - total_bet_this_session

func get_session_duration() -> float:
	return Time.get_unix_time_from_system() - session_start_time

func reset() -> void:
	current_game = ""
	total_bet_this_session = 0
	total_won_this_session = 0
	games_played = 0
