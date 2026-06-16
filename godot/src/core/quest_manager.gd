class_name QuestManager
extends Node

signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_progress_updated(quest_id: String, progress: int)

const SAVE_PATH := "user://quests.json"

var _quests: Dictionary = {}  # quest_id -> {status, progress}

func _ready() -> void:
	_load()

func accept_quest(quest_id: String) -> void:
	if _quests.get(quest_id, {}).get("status") == "complete":
		return
	_quests[quest_id] = {status="active", progress=0}
	quest_accepted.emit(quest_id)
	_save()
	NetworkManager.call_rpc("quest_action", {quest_id=quest_id, action="accept"}, func(_r): pass)

func complete_quest(quest_id: String) -> void:
	if _quests.get(quest_id, {}).get("status") != "active":
		return
	_quests[quest_id] = {status="complete", progress=100}
	quest_completed.emit(quest_id)
	AchievementManager.check("quest_complete")
	_save()
	NetworkManager.call_rpc("quest_action", {quest_id=quest_id, action="complete"},
		func(result: Dictionary):
			if result.get("coins_awarded", 0) > 0:
				NotificationUI.notify_win("Quest reward: +%d coins!" % result.coins_awarded)
			XPManager.award_game("quest", true)
	)

func update_progress(quest_id: String, amount: int = 1) -> void:
	if _quests.get(quest_id, {}).get("status") != "active":
		return
	_quests[quest_id].progress = _quests[quest_id].get("progress", 0) + amount
	quest_progress_updated.emit(quest_id, _quests[quest_id].progress)
	_save()

func is_active(quest_id: String) -> bool:
	return _quests.get(quest_id, {}).get("status") == "active"

func is_complete(quest_id: String) -> bool:
	return _quests.get(quest_id, {}).get("status") == "complete"

func get_status(quest_id: String) -> String:
	return _quests.get(quest_id, {}).get("status", "locked")

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_quests))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var parsed := JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			_quests = parsed
