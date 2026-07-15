extends Node
## Bridges godot/src/quests/data/all_faction_quests.json (the 47-quest
## faction storyline set) into QuestManager, the same way world_quest_bridge.gd
## already does for world_data/quests.json. Before this, the JSON was only
## ever read directly by quest_ui.gd for display — QuestManager.accept()
## never saw these quests, so nothing in it was actually completable, and
## NPCs handed out fabricated quest_%d ids matching none of them.
##
## Real, documented simplification: QuestManager's native shape is single-
## stage (one flat objectives list, one reward set). The source JSON has
## multi-stage quests (sequential unlock) and, for some final stages,
## player-choice branches with different rewards per branch. Faithfully
## preserving stage-gating and branch choice would need QuestManager itself
## extended to understand them — a bigger change than "make the existing
## quests completable". Instead: every stage's objectives are flattened
## into one combined list (all become concurrent requirements rather than
## sequential), and where a stage only defines branch rewards (no flat
## "rewards" key), the alphabetically-first branch's reward is used
## deterministically. This is a real behavior change from the original
## narrative design, not a hidden one — flagged here and in the commit
## that introduces it.

const FACTION_QUESTS_PATH := "res://src/quests/data/all_faction_quests.json"

func _ready() -> void:
	_register_faction_quests()

func _register_faction_quests() -> void:
	if not FileAccess.file_exists(FACTION_QUESTS_PATH):
		return
	var file := FileAccess.open(FACTION_QUESTS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Array):
		return

	var count := 0
	for quest in parsed:
		if not (quest is Dictionary) or str(quest.get("id", "")) == "":
			continue
		QuestManager.register_quest(_convert(quest))
		count += 1
	if count > 0:
		print("[FactionQuestBridge] Registered %d quests from all_faction_quests.json" % count)

func _convert(quest: Dictionary) -> Dictionary:
	var objectives: Array = []
	var stages: Array = quest.get("stages", [])
	for stage in stages:
		if not (stage is Dictionary):
			continue
		var stage_objectives = stage.get("objectives", {})
		if stage_objectives is Dictionary:
			for obj_key in stage_objectives.keys():
				var obj: Dictionary = stage_objectives[obj_key]
				objectives.append({
					"id": obj_key,
					"desc": str(obj.get("desc", obj_key.capitalize())),
					"target": int(obj.get("target", 1)),
					"type": str(obj.get("type", "")),
				})

	var rewards := _resolve_rewards(quest, stages)

	var prereq: Array = []
	var prereqs: Dictionary = quest.get("prerequisites", {})
	if prereqs.get("requires_quests") is Array:
		prereq = prereqs["requires_quests"]

	return {
		"id": str(quest.get("id", "")),
		"type": str(quest.get("faction", "side")),
		"name": str(quest.get("title", quest.get("id", ""))),
		"desc": str(quest.get("description", "")),
		"faction": str(quest.get("faction", "")),
		"objectives": objectives,
		"rewards": rewards,
		"prereq": prereq,
	}

## Top-level "rewards" if the quest has one flat outcome; otherwise the
## alphabetically-first branch's rewards from the final stage that defines
## branches (see module doc — a deterministic simplification, not a
## faithful reproduction of player choice).
func _resolve_rewards(quest: Dictionary, stages: Array) -> Dictionary:
	if quest.get("rewards") is Dictionary:
		return _flatten_reward_keys(quest["rewards"])

	for i in range(stages.size() - 1, -1, -1):
		var stage = stages[i]
		if not (stage is Dictionary):
			continue
		var branches = stage.get("branches", {})
		if branches is Dictionary and not branches.is_empty():
			var keys: Array = branches.keys()
			keys.sort()
			var chosen: Dictionary = branches[keys[0]]
			if chosen.get("rewards") is Dictionary:
				return _flatten_reward_keys(chosen["rewards"])

	return {"coins": 100, "xp": 100}

## Source JSON uses "currency"/"xp"; QuestManager's reward-granting code
## (mirrored from combat_manager.gd's pattern) expects "coins"/"xp".
func _flatten_reward_keys(rewards: Dictionary) -> Dictionary:
	var out := rewards.duplicate()
	if out.has("currency") and not out.has("coins"):
		out["coins"] = out["currency"]
	return out
