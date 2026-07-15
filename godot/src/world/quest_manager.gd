extends Node

signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String, rewards: Dictionary)
signal quest_failed(quest_id: String)
signal objective_progress(quest_id: String, obj_id: String, current: int, target: int)

enum QuestState { AVAILABLE, ACTIVE, COMPLETED, FAILED }
enum QuestType { MAIN, SIDE, DAILY, REPEATABLE, FACTION }

const QUESTS: Array[Dictionary] = [
	# Main story quests
	{
		id="main_001", type=QuestType.MAIN, name="Welcome to Paws Vegas",
		desc="Explore the Paws Vegas central district and talk to the locals.",
		objectives=[
			{id="visit_coliseum", desc="Visit Cat Coliseum", target=1},
			{id="visit_arcade", desc="Visit Arcade Galaxy", target=1},
			{id="talk_npc", desc="Talk to 3 locals", target=3},
		],
		rewards={coins=500, xp=100},
		prereq=[],
	},
	{
		id="main_002", type=QuestType.MAIN, name="First Steps in Combat",
		desc="Enter a battle at Cat Coliseum and prove your worth.",
		objectives=[
			{id="enter_combat", desc="Enter a combat", target=1},
			{id="win_combat", desc="Win a combat", target=1},
		],
		rewards={coins=750, xp=200, companion_unlock="SC003"},
		prereq=["main_001"],
	},
	{
		id="main_003", type=QuestType.MAIN, name="The Veiled Current Mystery",
		desc="Investigate rumors of strange activity in Neon Alley.",
		objectives=[
			{id="visit_neon", desc="Visit Neon Alley", target=1},
			{id="race_neon", desc="Complete a race in Neon Alley", target=1},
			{id="talk_vc_npc", desc="Talk to the VeiledCurrent informant", target=1},
		],
		rewards={coins=1000, xp=300},
		prereq=["main_002"],
	},
	{
		id="main_004", type=QuestType.MAIN, name="The Wild Hunt",
		desc="Venture into Cat Forest and survive what lurks within.",
		objectives=[
			{id="visit_forest", desc="Enter Cat Forest", target=1},
			{id="survive_encounters", desc="Survive 5 wild encounters", target=5},
			{id="find_artifact", desc="Discover the Forest Artifact", target=1},
		],
		rewards={coins=2000, xp=500, companion_unlock="WA050"},
		prereq=["main_003"],
	},
	# Side quests
	{
		id="side_001", type=QuestType.SIDE, name="The Lucky Gambler",
		desc="A mysterious cat challenges you to beat the odds.",
		objectives=[
			{id="win_slots_3", desc="Win 3 slot games", target=3},
			{id="win_500", desc="Win at least 500 coins in one spin", target=1},
		],
		rewards={coins=1500, xp=150},
		prereq=["main_001"],
	},
	{
		id="side_002", type=QuestType.SIDE, name="Speed Demon",
		desc="A racing legend wants to see what you're made of.",
		objectives=[
			{id="race_3", desc="Complete 3 races", target=3},
			{id="first_place", desc="Finish 1st place in any race", target=1},
		],
		rewards={coins=2000, xp=200},
		prereq=["main_001"],
	},
	{
		id="side_003", type=QuestType.SIDE, name="Companion Collector",
		desc="A scholar needs you to document companion diversity.",
		objectives=[
			{id="unlock_5", desc="Unlock 5 companions", target=5},
			{id="diff_factions", desc="Unlock companions from 3 factions", target=3},
		],
		rewards={coins=3000, xp=400, gems=50},
		prereq=["main_002"],
	},
	{
		id="side_004", type=QuestType.SIDE, name="The Merchant's Request",
		desc="A merchant needs items from across all districts.",
		objectives=[
			{id="visit_all_5", desc="Visit all 5 districts", target=5},
			{id="spend_5000", desc="Spend 5,000 coins total", target=5000},
		],
		rewards={coins=5000, xp=500},
		prereq=["main_003"],
	},
	{
		id="side_005", type=QuestType.SIDE, name="Cartographer's Call",
		desc="Chart the wild overworld beyond the districts — every chunk you discover is painted with your influence.",
		objectives=[
			{id="discover_chunk", desc="Discover 10 wild overworld chunks", target=10},
		],
		rewards={coins=2500, xp=600},
		prereq=[],
	},
	# Daily quests (repeatable)
	{
		id="daily_001", type=QuestType.DAILY, name="Daily Spin",
		desc="Spin the slots 5 times today.",
		objectives=[{id="spin_5", desc="Spin 5 times", target=5}],
		rewards={coins=250, xp=50},
		prereq=[],
	},
	{
		id="daily_002", type=QuestType.DAILY, name="Daily Racer",
		desc="Complete one race today.",
		objectives=[{id="race_1", desc="Complete 1 race", target=1}],
		rewards={coins=300, xp=75},
		prereq=[],
	},
	{
		id="daily_003", type=QuestType.DAILY, name="Daily Warrior",
		desc="Win one combat today.",
		objectives=[{id="win_1_combat", desc="Win 1 combat", target=1}],
		rewards={coins=400, xp=100},
		prereq=[],
	},
	# Faction quests
	{
		id="faction_sc_001", type=QuestType.FACTION, name="SovereignCrown Trial",
		desc="Prove your worth to the SovereignCrown by dominating in combat.",
		objectives=[
			{id="win_pow_combat", desc="Win 5 combats using POW builds", target=5},
			{id="sc_companion", desc="Have 2 SovereignCrown companions active", target=1},
		],
		rewards={coins=5000, xp=1000, faction_rep={SovereignCrown=500}},
		prereq=["main_002"],
	},
	{
		id="faction_vc_001", type=QuestType.FACTION, name="VeiledCurrent Initiation",
		desc="Match the speed of the VeiledCurrent.",
		objectives=[
			{id="win_spd_race", desc="Win 3 races using SPD build", target=3},
			{id="vc_companion", desc="Unlock 2 VeiledCurrent companions", target=2},
		],
		rewards={coins=5000, xp=1000, faction_rep={VeiledCurrent=500}},
		prereq=["main_003"],
	},
	{
		id="faction_wa_001", type=QuestType.FACTION, name="WildlandsAscendant Rite",
		desc="Survive the trials of the wilderness.",
		objectives=[
			{id="survive_10", desc="Survive 10 encounters in Cat Forest", target=10},
			{id="wa_companion", desc="Unlock 3 WildlandsAscendant companions", target=3},
		],
		rewards={coins=5000, xp=1000, faction_rep={WildlandsAscendant=500}},
		prereq=["main_004"],
	},
]

var _active: Dictionary = {}   # quest_id -> {state, progress}
var _completed: Array[String] = []
## Quests registered at runtime (world_data/quests.json via WorldQuestBridge),
## already converted to the same shape as QUESTS.
var _dynamic_quests: Array[Dictionary] = []

func _ready() -> void:
	_load_quest_state()

func register_quest(quest: Dictionary) -> void:
	if quest.get("id", "") == "" or not _find_quest(quest["id"]).is_empty():
		return
	_dynamic_quests.append(quest)

func all_quests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.assign(QUESTS)
	result.append_array(_dynamic_quests)
	return result

func get_available_quests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for q in all_quests():
		if q.id in _completed:
			continue
		if q.id in _active:
			continue
		var prereqs: Array = q.get("prereq", [])
		var prereqs_met = prereqs.all(func(p): return p in _completed)
		if prereqs_met:
			result.append(q.duplicate())
	return result

func accept(quest_id: String) -> bool:
	var quest = _find_quest(quest_id)
	if quest.is_empty():
		return false
	if quest_id in _active or quest_id in _completed:
		return false
	_active[quest_id] = {
		"state": QuestState.ACTIVE,
		"progress": {}
	}
	for obj in quest.get("objectives", []):
		_active[quest_id]["progress"][obj.id] = 0
	quest_accepted.emit(quest_id)
	_save_quest_state()
	return true

func update_progress(trigger: String, amount: int = 1) -> void:
	for quest_id in _active.keys():
		var quest = _find_quest(quest_id)
		for obj in quest.get("objectives", []):
			# Built-in quests match on objective id; JSON quests carry a
			# trigger `type` ("spin", "win_race", ...) shared across quests.
			if obj.get("id", "") == trigger or obj.get("type", "") == trigger:
				var current: int = _active[quest_id]["progress"].get(obj.id, 0)
				current = mini(current + amount, obj.get("target", 1))
				_active[quest_id]["progress"][obj.id] = current
				objective_progress.emit(quest_id, obj.id, current, obj.get("target", 1))
		_check_completion(quest_id, quest)
	_save_quest_state()

func _check_completion(quest_id: String, quest: Dictionary) -> void:
	var progress = _active[quest_id].get("progress", {})
	for obj in quest.get("objectives", []):
		if progress.get(obj.id, 0) < obj.get("target", 1):
			return
	# All objectives complete
	_active.erase(quest_id)
	_completed.append(quest_id)
	var rewards: Dictionary = quest.get("rewards", {})
	if rewards.get("coins", 0) > 0:
		EconomyManager.add_coins(rewards["coins"], "quest_reward")
	if rewards.get("xp", 0) > 0:
		PlayerProfile.add_xp(rewards["xp"])
	if rewards.get("gems", 0) > 0:
		EconomyManager.earn_gems(rewards["gems"], "quest_reward")
	if rewards.has("companion_unlock"):
		CompanionSystem.unlock_companion(rewards["companion_unlock"])
	quest_completed.emit(quest_id, rewards)
	AchievementManager.check("quest_completed")
	CrownManager.add_score("Top Quest Completions", "local_player", 1)
	SkillManager.grant_points(1, quest.get("name", "quest complete"))

## Compat shims for callers written against the old core quest tracker.
## accept_quest also mirrors the action to the Nakama quest RPC so
## server-tracked quests (neon_alley_racer, arcade_champion, ...) stay in
## sync when a session exists.
func accept_quest(quest_id: String) -> void:
	if not _find_quest(quest_id).is_empty():
		accept(quest_id)
	if NetworkManager.is_connected_to_server():
		NetworkManager.call_rpc("quest_action", {quest_id=quest_id, action="accept"}, func(_r): pass)

## Force-completes a local quest (fills every objective) or, for
## server-only quest ids, just reports completion to Nakama.
func complete_quest(quest_id: String) -> void:
	var quest := _find_quest(quest_id)
	if not quest.is_empty() and quest_id in _active:
		for obj in quest.get("objectives", []):
			_active[quest_id]["progress"][obj.id] = obj.get("target", 1)
		_check_completion(quest_id, quest)
		_save_quest_state()
	if NetworkManager.is_connected_to_server():
		NetworkManager.call_rpc("quest_action", {quest_id=quest_id, action="complete"},
			func(result: Dictionary):
				if result.get("coins_awarded", 0) > 0:
					NotificationUI.show_notification("Quest reward: +%d coins!" % result.coins_awarded, Color(0.3, 1.0, 0.3), "🎉")
		)

func is_active(quest_id: String) -> bool:
	return quest_id in _active

func is_complete(quest_id: String) -> bool:
	return quest_id in _completed

func get_quest(quest_id: String) -> Dictionary:
	return _find_quest(quest_id).duplicate(true)

func get_active_quest_ids() -> Array[String]:
	var ids: Array[String] = []
	for quest_id in _active.keys():
		ids.append(str(quest_id))
	return ids

func get_completed_quest_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_completed)
	return ids

func get_progress(quest_id: String) -> Dictionary:
	if quest_id not in _active:
		return {}
	var progress: Dictionary = _active[quest_id].get("progress", {})
	return progress.duplicate(true)

func abandon(quest_id: String) -> bool:
	if quest_id not in _active:
		return false
	_active[quest_id]["state"] = QuestState.FAILED
	quest_failed.emit(quest_id)
	_active.erase(quest_id)
	_save_quest_state()
	return true

func _find_quest(quest_id: String) -> Dictionary:
	for q in all_quests():
		if q.id == quest_id:
			return q
	return {}

func _save_quest_state() -> void:
	var data = {"active": _active, "completed": _completed}
	var file = FileAccess.open("user://quests.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func _load_quest_state() -> void:
	if not FileAccess.file_exists("user://quests.json"):
		return
	var file = FileAccess.open("user://quests.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			_active = parsed.get("active", {})
			_completed.clear()
			var completed_raw = parsed.get("completed", [])
			if completed_raw is Array:
				for id in completed_raw:
					_completed.append(str(id))
