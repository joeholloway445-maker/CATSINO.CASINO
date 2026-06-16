extends Node
# Bridges world_data/quests.json into the QuestManager at startup.
# Any quests defined in the JSON are registered automatically.

func _ready() -> void:
	if WorldLoader.quests.is_empty():
		await WorldLoader.world_loaded
	_register_json_quests()

func _register_json_quests() -> void:
	var count := 0
	for quest_id in WorldLoader.quests.keys():
		if not QuestManager.quests.has(quest_id):
			var q: Dictionary = WorldLoader.quests[quest_id]
			QuestManager.quests[quest_id] = {
				"title": q.get("title", quest_id),
				"type": q.get("type", "side"),
				"description": q.get("description", ""),
				"district": q.get("district", ""),
				"giver_npc": q.get("giver_npc", ""),
				"objectives": q.get("objectives", []),
				"reward_coins": q.get("reward_coins", 0),
				"reward_xp": q.get("reward_xp", 0),
				"unlock_companion": q.get("unlock_companion", ""),
				"next_quest": q.get("next_quest", ""),
				"prerequisites": q.get("prerequisites", []),
				"completed": false,
				"active": false,
				"progress": {},
			}
			count += 1
	if count > 0:
		print("[WorldQuestBridge] Registered %d quests from world_data/quests.json" % count)
