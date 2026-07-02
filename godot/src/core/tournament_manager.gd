extends Node

signal tournament_started(tournament: Dictionary)
signal tournament_round_complete(round_num: int, results: Array)
signal tournament_finished(winner: Dictionary, standings: Array)

enum TournamentState { IDLE, REGISTRATION, IN_PROGRESS, FINISHED }
enum TournamentType { COMBAT, RACING, SLOTS, MIXED }

var current_tournament: Dictionary = {}
var state: TournamentState = TournamentState.IDLE
var _bracket: Array[Dictionary] = []
var _round: int = 0
var _standings: Array[Dictionary] = []

const MAX_PARTICIPANTS = 16
const PRIZE_POOL_MULTIPLIER = 10  # total pot = entry_fee * participants * multiplier

func create_tournament(type: TournamentType, entry_fee: int, name: String) -> Dictionary:
	if state != TournamentState.IDLE:
		push_warning("TournamentManager: tournament already active")
		return {}
	current_tournament = {
		"id": str(Time.get_unix_time_from_system()),
		"name": name,
		"type": type,
		"entry_fee": entry_fee,
		"participants": [],
		"prize_pool": 0,
		"created_at": Time.get_unix_time_from_system()
	}
	state = TournamentState.REGISTRATION
	return current_tournament

func register(player_data: Dictionary) -> bool:
	if state != TournamentState.REGISTRATION:
		return false
	if current_tournament["participants"].size() >= MAX_PARTICIPANTS:
		return false
	# Only the human player pays from the real wallet; AI entrants just
	# inflate the prize pool. spend_coins is a coroutine — must be awaited.
	if player_data.get("is_player", false):
		if not await EconomyManager.spend_coins(current_tournament["entry_fee"], "tournament_entry"):
			return false
		AchievementManager.check("tournament_entered")
	current_tournament["participants"].append(player_data)
	current_tournament["prize_pool"] += current_tournament["entry_fee"]
	return true

func start() -> void:
	if state != TournamentState.REGISTRATION:
		return
	var participants: Array = current_tournament["participants"]
	if participants.size() < 2:
		push_warning("TournamentManager: not enough participants")
		return
	participants.shuffle()
	_build_bracket(participants)
	state = TournamentState.IN_PROGRESS
	_round = 1
	tournament_started.emit(current_tournament)
	_run_next_round()

func _build_bracket(participants: Array) -> void:
	_bracket = []
	for i in range(0, participants.size() - 1, 2):
		_bracket.append({
			"player_a": participants[i],
			"player_b": participants[i + 1] if i + 1 < participants.size() else null,
			"winner": null
		})

func _run_next_round() -> void:
	var round_results: Array[Dictionary] = []
	var next_round_players: Array = []
	for match_data in _bracket:
		var winner = _resolve_match(match_data)
		match_data["winner"] = winner
		round_results.append({"match": match_data, "winner": winner})
		next_round_players.append(winner)
	tournament_round_complete.emit(_round, round_results)
	if next_round_players.size() <= 1:
		_finish(next_round_players[0] if not next_round_players.is_empty() else {})
	else:
		_round += 1
		_bracket = []
		for i in range(0, next_round_players.size() - 1, 2):
			_bracket.append({
				"player_a": next_round_players[i],
				"player_b": next_round_players[i + 1] if i + 1 < next_round_players.size() else null,
				"winner": null
			})
		await get_tree().create_timer(1.5).timeout
		_run_next_round()

func _resolve_match(match_data: Dictionary) -> Dictionary:
	var a: Dictionary = match_data["player_a"]
	var b = match_data["player_b"]
	if b == null:
		return a  # bye
	# Use CombatSystem for combat tournaments, else stat-based comparison
	match current_tournament.get("type", TournamentType.COMBAT):
		TournamentType.COMBAT:
			if CombatSystem.has_method("quick_resolve"):
				return CombatSystem.quick_resolve(a, b)
			return a if randf() > 0.5 else b
		TournamentType.RACING:
			var spd_a = a.get("spd", 50) + randi() % 20
			var spd_b = b.get("spd", 50) + randi() % 20
			return a if spd_a >= spd_b else b
		_:
			return a if randf() > 0.5 else b

func _finish(winner: Dictionary) -> void:
	state = TournamentState.FINISHED
	var prize_pool: int = current_tournament.get("prize_pool", 0) * PRIZE_POOL_MULTIPLIER
	_distribute_prizes(winner, prize_pool)
	_standings = [winner]
	tournament_finished.emit(winner, _standings)
	if winner.get("is_player", false):
		AchievementManager.check("tournament_won")
		CrownManager.add_score("Top Arena Victories", "local_player", 1, PlayerProfile.faction)
	await get_tree().create_timer(3.0).timeout
	state = TournamentState.IDLE
	current_tournament = {}

func _distribute_prizes(winner: Dictionary, prize_pool: int) -> void:
	if winner.get("is_player", false):
		EconomyManager.add_coins(prize_pool)
		push_warning("TournamentManager: player won %d coins" % prize_pool)
