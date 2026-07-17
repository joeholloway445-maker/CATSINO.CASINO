extends Node

signal quest_completed(quest_id: String, rewards: Dictionary)

var _active_quests: Array[Dictionary] = []
var _completed_quest_ids: Array[String] = []

const NPC_DIALOGUES: Dictionary = {
	0: {"name": "Elder Whiskers", "lines": ["The forest holds ancient power...", "Seek the glowing mushrooms to the east."]},
	1: {"name": "Patchwork Pete", "lines": ["Trade you some berries for coins?", "I've seen strange things in the deep forest."]},
	2: {"name": "Luna the Guide", "lines": ["Follow the stars to find your path.", "Three quests await the worthy soul."]},
	3: {"name": "Bramble", "lines": ["Growl... leave me alone.", "Fine. There's treasure beyond the waterfall."]}
}

func _ready() -> void:
	_seed_quests()
	_build_ui()

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var title := Label.new()
	title.text = "🌿 CAT FOREST"
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	var status := Label.new()
	status.name = "Status"
	status.text = "Talk to locals or advance a hunt."
	root.add_child(status)

	for npc_id in NPC_DIALOGUES.keys():
		var btn := Button.new()
		btn.text = "Talk: %s" % NPC_DIALOGUES[npc_id]["name"]
		var id := int(npc_id)
		btn.pressed.connect(func() -> void:
			var d := talk_to_npc(id)
			status.text = "%s — %s" % [d.get("speaker", "?"), str(d.get("dialogue", [])).substr(0, 80)]
		)
		root.add_child(btn)

	for quest in _active_quests:
		var qbtn := Button.new()
		qbtn.text = "Advance: %s" % quest["name"]
		var qid: String = quest["id"]
		qbtn.pressed.connect(func() -> void:
			update_quest_progress(qid, 1)
			status.text = "Progressed %s" % qid
		)
		root.add_child(qbtn)

	var explore := Button.new()
	explore.text = "Explore Nearby Chunk"
	explore.pressed.connect(func() -> void:
		explore_chunk(Vector3(randf_range(-200, 200), 0, randf_range(-200, 200)), "local_player", 3)
		status.text = "You push deeper into the canopy."
	)
	root.add_child(explore)

	var back := Button.new()
	back.text = "⬅ Menu"
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	root.add_child(back)

func _seed_quests() -> void:
	_active_quests = [
		{
			"id": "forest_hunt_001",
			"name": "Mushroom Harvest",
			"objective": "Collect glowing mushrooms",
			"progress": 0,
			"goal": 10,
			"reward_coins": 200,
			"reward_xp": 150,
			"reward_companion_id": ""
		},
		{
			"id": "forest_hunt_002",
			"name": "Predator Patrol",
			"objective": "Defeat forest predators",
			"progress": 0,
			"goal": 5,
			"reward_coins": 350,
			"reward_xp": 300,
			"reward_companion_id": "forest_wolf_companion"
		},
		{
			"id": "forest_explore_001",
			"name": "Ancient Ruins",
			"objective": "Discover hidden ruins",
			"progress": 0,
			"goal": 3,
			"reward_coins": 500,
			"reward_xp": 500,
			"reward_companion_id": "ruin_spirit_companion"
		}
	]

func update_quest_progress(quest_id: String, amount: int) -> void:
	for quest in _active_quests:
		if quest["id"] == quest_id:
			quest["progress"] = mini(quest["progress"] + amount, quest["goal"])
			if quest["progress"] >= quest["goal"]:
				complete_quest(quest_id)
			return

func complete_quest(quest_id: String) -> void:
	if quest_id in _completed_quest_ids:
		return
	for quest in _active_quests:
		if quest["id"] == quest_id and quest["progress"] >= quest["goal"]:
			_completed_quest_ids.append(quest_id)
			_active_quests.erase(quest)
			var rewards: Dictionary = {
				"coins": quest["reward_coins"],
				"xp": quest["reward_xp"],
				"companion_id": quest["reward_companion_id"]
			}
			EconomyManager.add_coins(rewards["coins"])
			if rewards["companion_id"] != "":
				CompanionSystem.unlock_companion(rewards["companion_id"])
			quest_completed.emit(quest_id, rewards)
			return

func talk_to_npc(npc_id: int) -> Dictionary:
	if npc_id in NPC_DIALOGUES:
		var data = NPC_DIALOGUES[npc_id]
		return {
			"speaker": data["name"],
			"dialogue": data["lines"],
			"type": "npc_dialogue",
			"npc_id": npc_id
		}
	return {"error": "npc_not_found", "npc_id": npc_id}

func get_active_quests() -> Array[Dictionary]:
	return _active_quests.duplicate(true)

## Drives the "Ancient Ruins" discover-quest off DiscoveryManager's
## perception-weighted chunk system (ported from godot_hdv_core). Call as
## the player moves through the forest; advances forest_explore_001 once
## per newly-generated (not previously visited) chunk.
func explore_chunk(world_pos: Vector3, player_id: String, perception: int = 1) -> void:
	var coord := DiscoveryManager.world_pos_to_chunk(world_pos)
	var already_known := DiscoveryManager.has_chunk(coord)
	var chunk := DiscoveryManager.get_or_generate_chunk(coord)
	if chunk.is_hub:
		return
	var loadout := CharacterCreatorLogic.build_loadout(PlayerProfile.selected_race_id, PlayerProfile.selected_frame)
	var pack := PlayerInfluencePack.from_loadout(player_id, loadout, perception)
	DiscoveryManager.register_party_visit(coord, [pack])
	if not already_known:
		update_quest_progress("forest_explore_001", 1)
