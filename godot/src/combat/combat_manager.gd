class_name CombatManager
extends Node

signal combat_started(bet: int, opponent_frame: String)
signal combat_ended(won: bool, payout: int)
signal move_made(move: String, damage: int, is_player: bool)
signal hp_changed(player_hp: float, opponent_hp: float)

var player_hp := 100.0
var opponent_hp := 100.0
var _bet := 0
var _in_combat := false
var _player_frame := "phantom"
var _opponent_frame := "tremor"
var _game_state: Dictionary = {}

func start_combat(bet: int, player_frame: String) -> void:
	if _in_combat:
		return
	_bet = bet
	_player_frame = player_frame if player_frame != "" else "phantom"
	_in_combat = true
	NetworkManager.call_rpc("combat_action", {
		action = "start",
		bet = _bet,
		frame_id = _player_frame,
		opponent_id = "npc_arena_guard",
	}, func(result: Dictionary):
		if result.get("error") and not result.get("success", false):
			_in_combat = false
			NotificationUI.notify_error(str(result.get("error", "Combat start failed")))
			return
		_game_state = result.get("state", {})
		player_hp = float(result.get("player_hp", _game_state.get("player_hp", 250)))
		opponent_hp = float(result.get("opponent_hp", _game_state.get("opponent_hp", 280)))
		combat_started.emit(bet, _opponent_frame)
		hp_changed.emit(player_hp, opponent_hp)
	)

func make_move(move: String) -> void:
	if not _in_combat:
		return
	NetworkManager.call_rpc("combat_action", {
		action = "move",
		move = move,
		bet = _bet,
		frame_id = _player_frame,
		game_state = _game_state,
	}, func(result: Dictionary):
		if result.get("error") and not result.get("success", false):
			NotificationUI.notify_error(str(result.get("error", "Move failed")))
			return
		if result.has("state") and result.state is Dictionary:
			_game_state = result.state
		var player_dmg: int = int(result.get("player_damage", 0))
		var opp_dmg: int = int(result.get("opponent_damage", 0))
		if result.has("player_hp"):
			player_hp = float(result.player_hp)
		else:
			player_hp = maxf(0.0, player_hp - float(player_dmg))
		if result.has("opponent_hp"):
			opponent_hp = float(result.opponent_hp)
		else:
			opponent_hp = maxf(0.0, opponent_hp - float(opp_dmg))
		move_made.emit(move, opp_dmg, true)
		move_made.emit(str(result.get("opponent_move", "?")), player_dmg, false)
		hp_changed.emit(player_hp, opponent_hp)
		var outcome := str(result.get("outcome", ""))
		if outcome != "":
			_finish(outcome, int(result.get("payout", 0)), bool(result.get("server_wallet", false)))
	)

func _finish(outcome: String, payout: int, server_wallet: bool = false) -> void:
	_in_combat = false
	_game_state.clear()
	var won := outcome == "player_wins"
	if won and payout > 0 and not server_wallet:
		EconomyManager.add_coins(payout, "combat_win")
	combat_ended.emit(won, payout)
	if won:
		NotificationUI.notify_win("Combat win! +%d coins ⚔️" % payout)
		AchievementManager.check("battle_win")
		CrownManager.add_score("Top 1v1 Victories", "local_player", 1, PlayerProfile.faction)
		QuestManager.update_progress("enter_combat")
		QuestManager.update_progress("win_combat")
		QuestManager.update_progress("win_1_combat")
	else:
		NotificationUI.notify_error("Defeated! Better luck next time.")
	XPManager.award_game("combat", won)
