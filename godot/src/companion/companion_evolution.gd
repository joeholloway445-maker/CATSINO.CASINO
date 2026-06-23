class_name CompanionEvolution
extends Node

signal evolution_complete(companion_id: String)
signal level_up(companion_id: String, new_level: int)

func feed(companion_id: String, xp_amount: int) -> void:
	NetworkManager.call_rpc("feed_companion", {companion_id=companion_id, xp_amount=xp_amount},
		func(result: Dictionary):
			if result.get("success"):
				if result.get("leveled_up"):
					level_up.emit(companion_id, result.companion.level)
					NotificationUI.notify_achievement("🐾 %s leveled up to %d!" % [companion_id, result.companion.level])
			else:
				NotificationUI.notify_error("Feed failed: %s" % result.get("error", "Unknown error"))
	)

func evolve(companion_id: String) -> void:
	NetworkManager.call_rpc("evolve_companion", {companion_id=companion_id},
		func(result: Dictionary):
			if result.get("success"):
				evolution_complete.emit(companion_id)
				NotificationUI.notify_achievement("✨ %s EVOLVED!" % companion_id)
			else:
				NotificationUI.notify_error("Evolve failed: %s" % result.get("error", "Unknown error"))
	)
