extends Node
class_name QuestSystem

signal quest_accepted(quest_id: String)
signal quest_progressed(quest_id: String, stage: int)
signal quest_completed(quest_id: String, rewards: Dictionary)
signal quest_failed(quest_id: String)
signal objective_updated(quest_id: String, objective: String)

# Quest database: id → Quest data
var _quests: Dictionary = {}
var _active_quests: Dictionary = {}  # id → progress data
var _completed_quests: Array[String] = []

func _ready() -> void:
	_load_quest_db()

# ── Quest Acceptance ───────────────────────────────────────────────────────
func accept_quest(quest_id: String) -> bool:
	if quest_id not in _quests:
		push_error("Quest not found: %s" % quest_id)
		return false
	if quest_id in _active_quests:
		return false  # Already active

	var quest = _quests[quest_id]

	# Check prerequisites
	if not _check_prerequisites(quest):
		return false

	# Check faction alignment if required
	if quest.get("faction") and quest.faction != "Factionless":
		if PlayerProfile.faction != quest.faction and PlayerProfile.faction != "Factionless":
			return false  # Wrong faction

	_active_quests[quest_id] = {
		"stage": 0,
		"progress": {},
		"accepted_at": Time.get_ticks_msec(),
		"objectives_completed": [],
	}

	quest_accepted.emit(quest_id)
	return true

# ── Quest Progression ──────────────────────────────────────────────────────
func progress_quest(quest_id: String, objective: String, value: int = 1) -> void:
	if quest_id not in _active_quests:
		return

	var quest = _quests[quest_id]
	var progress = _active_quests[quest_id]

	# Track objective progress
	if objective not in progress["progress"]:
		progress["progress"][objective] = 0

	progress["progress"][objective] += value

	# Check if objective is complete
	var current_stage = quest.get("stages", [])[progress["stage"]] if progress["stage"] < quest.get("stages", []).size() else null
	if current_stage:
		var obj_data = current_stage.get("objectives", {}).get(objective, {})
		var target = obj_data.get("target", 1)

		if progress["progress"][objective] >= target:
			if objective not in progress["objectives_completed"]:
				progress["objectives_completed"].append(objective)

			# Check if all objectives for this stage are complete
			if _stage_complete(quest, progress):
				_advance_stage(quest_id)

	quest_progressed.emit(quest_id, progress["stage"])
	objective_updated.emit(quest_id, objective)

func _stage_complete(quest: Dictionary, progress: Dictionary) -> bool:
	var current_stage = quest.get("stages", [])[progress["stage"]]
	if not current_stage:
		return false

	var objectives = current_stage.get("objectives", {})
	for obj_name in objectives.keys():
		if obj_name not in progress["objectives_completed"]:
			return false

	return true

func _advance_stage(quest_id: String) -> void:
	var quest = _quests[quest_id]
	var progress = _active_quests[quest_id]
	var max_stage = quest.get("stages", []).size() - 1

	if progress["stage"] >= max_stage:
		_complete_quest(quest_id, quest)
	else:
		progress["stage"] += 1
		progress["objectives_completed"].clear()
		quest_progressed.emit(quest_id, progress["stage"])

func _complete_quest(quest_id: String, quest: Dictionary) -> void:
	var progress = _active_quests[quest_id]

	# Execute completion effects
	var rewards = _execute_rewards(quest, progress)

	_active_quests.erase(quest_id)
	_completed_quests.append(quest_id)

	quest_completed.emit(quest_id, rewards)

# ── Rewards ────────────────────────────────────────────────────────────────
func _execute_rewards(quest: Dictionary, progress: Dictionary) -> Dictionary:
	var rewards = quest.get("rewards", {})
	var applied = {}

	# XP reward — player profile (companions get XP via add_xp on equipped id)
	if "xp" in rewards:
		var xp_amt: int = int(rewards["xp"])
		PlayerProfile.add_xp(xp_amt)
		if not PlayerProfile.selected_companion.is_empty():
			var cid = PlayerProfile.selected_companion
			if str(cid).is_valid_int():
				CompanionSystem.add_xp(int(cid), xp_amt)
		applied["xp"] = xp_amt

	# Currency reward → EconomyManager (coins)
	if "currency" in rewards:
		EconomyManager.add_coins(int(rewards["currency"]), "quest:%s" % str(quest.get("id", "")))
		applied["currency"] = rewards["currency"]
	if "coins" in rewards:
		EconomyManager.add_coins(int(rewards["coins"]), "quest:%s" % str(quest.get("id", "")))
		applied["coins"] = rewards["coins"]

	# Title reward (affects identity seed)
	if "title" in rewards:
		PlayerProfile.add_title(str(rewards["title"]))
		if IdentityLens:
			IdentityLens.lens_changed.emit()
		applied["title"] = rewards["title"]

	# NPC relationship change
	if "npc_disposition" in rewards:
		for npc_id in rewards["npc_disposition"].keys():
			NPCDialogueSystem.adjust_disposition(str(npc_id), int(rewards["npc_disposition"][npc_id]))
		applied["npc_disposition"] = rewards["npc_disposition"]

	# Entity unlock — capture/companion path (never auto-unlock wilds elsewhere)
	if "entity_unlock" in rewards:
		for entity_id in rewards["entity_unlock"]:
			EntityDexData.unlock_entity(entity_id)
		applied["entity_unlock"] = rewards["entity_unlock"]

	# Faction reputation
	if "faction_rep" in rewards:
		for faction in rewards["faction_rep"].keys():
			FactionManager.add_reputation(faction, int(rewards["faction_rep"][faction]))
		applied["faction_rep"] = rewards["faction_rep"]

	return applied

# ── Prerequisites ──────────────────────────────────────────────────────────
func _check_prerequisites(quest: Dictionary) -> bool:
	var prereqs = quest.get("prerequisites", {})

	# Level check
	if "min_level" in prereqs:
		if PlayerProfile.level < prereqs["min_level"]:
			return false

	# Completed quest check
	if "requires_quests" in prereqs:
		for req_quest in prereqs["requires_quests"]:
			if req_quest not in _completed_quests:
				return false

	# NPC disposition check
	if "npc_min_disposition" in prereqs:
		for npc_id in prereqs["npc_min_disposition"].keys():
			var disp = NPCDialogueSystem.get_disposition(str(npc_id))
			if disp < prereqs["npc_min_disposition"][npc_id]:
				return false

	# Faction check
	if "faction_min_rep" in prereqs:
		for faction in prereqs["faction_min_rep"].keys():
			var rep = FactionManager.get_reputation(faction)
			if rep < prereqs["faction_min_rep"][faction]:
				return false

	return true

# ── Database Loading ───────────────────────────────────────────────────────
func _load_quest_db() -> void:
	# Load all quest definitions from json files in quests/data/
	var quest_dir = "res://src/quests/data/"
	var dir = DirAccess.open(quest_dir)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var path := quest_dir + file_name
				var f := FileAccess.open(path, FileAccess.READ)
				if f:
					var quest_data = JSON.parse_string(f.get_as_text())
					if quest_data is Dictionary and "id" in quest_data:
						_quests[quest_data["id"]] = quest_data
					elif quest_data is Array:
						for entry in quest_data:
							if entry is Dictionary and "id" in entry:
								_quests[entry["id"]] = entry
			file_name = dir.get_next()

# ── Query API ──────────────────────────────────────────────────────────────
func get_quest(quest_id: String) -> Dictionary:
	return _quests.get(quest_id, {})

func get_active_quests() -> Array[String]:
	return _active_quests.keys()

func get_quest_progress(quest_id: String) -> Dictionary:
	return _active_quests.get(quest_id, {})

func is_quest_active(quest_id: String) -> bool:
	return quest_id in _active_quests

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in _completed_quests

func get_completed_quests() -> Array[String]:
	return _completed_quests.duplicate()

# ── Save/Load State ────────────────────────────────────────────────────────
func save_progress() -> Dictionary:
	return {
		"active_quests": _active_quests.duplicate(true),
		"completed_quests": _completed_quests.duplicate(),
	}

func load_progress(data: Dictionary) -> void:
	_active_quests = data.get("active_quests", {})
	_completed_quests = data.get("completed_quests", [])
