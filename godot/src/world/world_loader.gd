extends Node
# Loads all world data from JSON files in res://world_data/
# Non-coders: edit the JSON files — this loader picks up changes automatically on restart.

signal world_loaded()

const DATA_DIR := "res://world_data/"

var districts: Dictionary = {}
var npcs: Dictionary = {}
var dialogues: Dictionary = {}
var shops: Dictionary = {}
var quests: Dictionary = {}

func _ready() -> void:
	_load_all()
	world_loaded.emit()
	print("[WorldLoader] World data loaded: %d districts, %d NPCs, %d quests, %d shops" % [
		districts.size(), npcs.size(), quests.size(), shops.size()
	])

func _load_all() -> void:
	districts = _load_json("districts.json").get("districts", []).reduce(func(acc, d): acc[d.id] = d; return acc, {})
	npcs      = _load_json("npcs.json").get("npcs", []).reduce(func(acc, n): acc[n.id] = n; return acc, {})
	dialogues = _load_json("dialogue.json").get("dialogues", []).reduce(func(acc, d): acc[d.dialogue_id] = d; return acc, {})
	shops     = _load_json("shops.json").get("shops", []).reduce(func(acc, s): acc[s.shop_id] = s; return acc, {})
	quests    = _load_json("quests.json").get("quests", []).reduce(func(acc, q): acc[q.id] = q; return acc, {})

func _load_json(filename: String) -> Dictionary:
	var path := DATA_DIR + filename
	if not FileAccess.file_exists(path):
		push_warning("[WorldLoader] Missing file: " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[WorldLoader] Cannot open: " + path)
		return {}
	var text := file.get_as_text()
	file.close()
	var result = JSON.parse_string(text)
	if result == null:
		push_error("[WorldLoader] Invalid JSON in: " + path)
		return {}
	return result

# ── Query helpers ─────────────────────────────────────────────────────────────

func get_district(id: String) -> Dictionary:
	return districts.get(id, {})

func get_all_districts() -> Array:
	return districts.values()

func get_npcs_in_district(district_id: String) -> Array:
	return npcs.values().filter(func(n): return n.get("district", "") == district_id)

func get_npc(npc_id: String) -> Dictionary:
	return npcs.get(npc_id, {})

func get_dialogue(dialogue_id: String) -> Dictionary:
	return dialogues.get(dialogue_id, {})

func get_dialogue_node(dialogue_id: String, node_id: String) -> Dictionary:
	var dlg := get_dialogue(dialogue_id)
	for node in dlg.get("nodes", []):
		if node.get("id", "") == node_id:
			return node
	return {}

func get_shop(shop_id: String) -> Dictionary:
	return shops.get(shop_id, {})

func get_shops_in_district(district_id: String) -> Array:
	return shops.values().filter(func(s): return s.get("district", "") == district_id)

func get_quest(quest_id: String) -> Dictionary:
	return quests.get(quest_id, {})

func get_quests_by_type(type: String) -> Array:
	return quests.values().filter(func(q): return q.get("type", "") == type)

func get_quests_for_npc(npc_id: String) -> Array:
	return quests.values().filter(func(q): return q.get("giver_npc", "") == npc_id)
