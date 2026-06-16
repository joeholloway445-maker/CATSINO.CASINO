class_name SlotGameManager
extends Node
# Coordinates slot machine game flow with XP, quests, achievements

signal spin_completed(result: Dictionary)

func spin(bet: int) -> void:
	var multiplier := EventManager.get_slot_multiplier() if is_instance_valid(EventManager) else 1.0
	NetworkManager.call_rpc("spin_slots", {bet=bet, multiplier=multiplier},
		func(result: Dictionary):
			if result.get("error"):
				NotificationUI.notify_error(result.error)
				return
			var payout: int = result.get("payout", 0)
			spin_completed.emit(result)
			AchievementManager.check("spin")
			QuestManager.update_progress("daily_spin")
			if payout > 0:
				AchievementManager.check("win", payout)
				QuestManager.update_progress("win_3_games")
				if payout >= 10000:
					AchievementManager.check("big_win", payout)
			XPManager.award_game("slots", payout > 0)
			NetworkManager.call_rpc("submit_score", {board_id="slot_wins", score=int(payout > 0)}, func(_r): pass)
	)
