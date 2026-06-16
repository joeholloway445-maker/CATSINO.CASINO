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
var _player_frame := "basic"
var _opponent_frame := "basic"

func start_combat(bet: int, player_frame: String) -> void:
	if _in_combat:
		return
	_bet = bet
	_player_frame = player_frame
	_in_combat = true
	player_hp = 100.0
	opponent_hp = 100.0
	combat_started.emit(bet, _opponent_frame)

func make_move(move: String) -> void:
	if not _in_combat:
		return

	NetworkManager.call_rpc("combat_action", {move=move, bet=_bet, frame_id=_player_frame},
		func(result: Dictionary):
			if result.get("error"):
				NotificationUI.notify_error(result.error)
				return

			var player_dmg: int = result.get("player_damage", 0)
			var opp_dmg: int = result.get("opponent_damage", 0)

			player_hp = maxf(0.0, player_hp - player_dmg)
			opponent_hp = maxf(0.0, opponent_hp - opp_dmg)

			move_made.emit(move, opp_dmg, true)
			move_made.emit(result.get("opponent_move", "?"), player_dmg, false)
			hp_changed.emit(player_hp, opponent_hp)

			var outcome := result.get("outcome", "")
			if outcome:
				_finish(outcome, result.get("payout", 0))
	)

func _finish(outcome: String, payout: int) -> void:
	_in_combat = false
	var won := outcome == "player_wins"
	combat_ended.emit(won, payout)
	if won:
		NotificationUI.notify_win("Combat win! +%d coins ⚔️" % payout)
		AchievementManager.check("battle_win")
		QuestManager.update_progress("first_battle")
		QuestManager.update_progress("grand_tournament")
	else:
		NotificationUI.notify_error("Defeated! Better luck next time.")
	XPManager.award_game("combat", won)
