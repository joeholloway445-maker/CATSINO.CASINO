extends Node
# Bridges world_data/quests.json into the QuestManager at startup: each JSON
# quest is converted to QuestManager's native shape and registered. Built-in
# QUESTS win id collisions (register_quest skips ids that already exist).

func _ready() -> void:
	if WorldLoader.quests.is_empty():
		await WorldLoader.world_loaded
	_register_json_quests()

func _register_json_quests() -> void:
	var count := 0
	for quest_id in WorldLoader.quests.keys():
		var q: Dictionary = WorldLoader.quests[quest_id]
		var rewards := {
			"coins": int(q.get("reward_coins", 0)),
			"xp": int(q.get("reward_xp", 0)),
		}
		if str(q.get("unlock_companion", "")) != "":
			rewards["companion_unlock"] = q["unlock_companion"]
		var objectives: Array = []
		for obj in q.get("objectives", []):
			objectives.append({
				"id": obj.get("id", ""),
				"desc": obj.get("description", ""),
				"target": int(obj.get("target", 1)),
				"type": obj.get("type", ""),
				"district": obj.get("district", ""),
			})
		QuestManager.register_quest({
			"id": quest_id,
			"type": q.get("type", "side"),
			"name": q.get("title", quest_id),
			"desc": q.get("description", ""),
			"district": q.get("district", ""),
			"giver_npc": q.get("giver_npc", ""),
			"objectives": objectives,
			"rewards": rewards,
			"prereq": q.get("prerequisites", []),
		})
		count += 1
	if count > 0:
		print("[WorldQuestBridge] Registered %d quests from world_data/quests.json" % count)
