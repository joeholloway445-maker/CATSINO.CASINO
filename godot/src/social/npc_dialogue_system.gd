extends Node
class_name NPCDialogueSystem

signal dialogue_started(npc_id: String, dialogue_key: String)
signal dialogue_option_presented(npc_id: String, options: Array[Dictionary])
signal dialogue_ended(npc_id: String, choice: String)

# NPC dialogue database: npc_id → dialogue tree
var _dialogue_db: Dictionary = {}

# NPC dispositions: npc_id → disposition_value (-100 to 100)
var _npc_dispositions: Dictionary = {}

# NPC memory: what they know about you (from WordOfMouth)
var _npc_memory: Dictionary = {}

func _ready() -> void:
	_load_dialogue_db()
	_load_dispositions()

# ── Dialogue Initiation ────────────────────────────────────────────────────
func start_dialogue(npc_id: String, dialogue_key: String = "greeting") -> bool:
	if npc_id not in _dialogue_db:
		push_error("NPC dialogue not found: %s" % npc_id)
		return false

	var npc_dialogue = _dialogue_db[npc_id]
	var dialogue_tree = npc_dialogue.get(dialogue_key, {})

	if dialogue_tree.is_empty():
		return false

	dialogue_started.emit(npc_id, dialogue_key)

	# Check disposition-based dialogue variants
	var disposition = _npc_dispositions.get(npc_id, 0)
	var dialogue_line = _get_disposition_variant(dialogue_tree, disposition)

	# Inject word-of-mouth greeting if available
	var wow_line = WordOfMouth.greeting_line(npc_id)
	if wow_line:
		dialogue_line = "%s\n\n(Rumor has it: %s)" % [dialogue_line, wow_line]

	# Present dialogue with options
	_present_dialogue(npc_id, dialogue_key, dialogue_line, dialogue_tree)

	return true

func _get_disposition_variant(dialogue_tree: Dictionary, disposition: int) -> String:
	# Disposition-based dialogue variants
	if disposition > 50:
		return dialogue_tree.get("line_friendly", dialogue_tree.get("line", ""))
	elif disposition < -50:
		return dialogue_tree.get("line_hostile", dialogue_tree.get("line", ""))
	else:
		return dialogue_tree.get("line", "")

func _present_dialogue(npc_id: String, dialogue_key: String, line: String, tree: Dictionary) -> void:
	var options = []

	# Social options (nice/mean/flirt)
	if tree.get("allow_social_options", true):
		options.append({
			"text": "Be nice",
			"type": "social_nice",
			"effect": {"disposition": 10, "tone": "nice"}
		})
		options.append({
			"text": "Be mean",
			"type": "social_mean",
			"effect": {"disposition": -15, "tone": "mean"}
		})
		options.append({
			"text": "Flirt",
			"type": "social_flirt",
			"effect": {"disposition": 5, "tone": "flirt"}
		})

	# Custom dialogue options from tree
	if "options" in tree:
		for opt in tree["options"]:
			options.append({
				"text": opt.get("text", "..."),
				"type": "custom",
				"next_dialogue": opt.get("next_key"),
				"requirements": opt.get("requirements", {}),
				"effect": opt.get("effect", {})
			})

	# Quest dialogue options
	if "quest_options" in tree:
		for quest_opt in tree["quest_options"]:
			options.append({
				"text": quest_opt.get("text", "..."),
				"type": "quest",
				"quest_id": quest_opt.get("quest_id"),
				"effect": {"progression": quest_opt.get("quest_id")}
			})

	# Leave option
	options.append({
		"text": "Leave",
		"type": "leave",
		"next_dialogue": null
	})

	# Filter options by requirements
	options = _filter_options_by_requirements(options)

	dialogue_option_presented.emit(npc_id, options)

# ── Dialogue Choice ────────────────────────────────────────────────────────
func choose_dialogue_option(npc_id: String, option_index: int) -> void:
	if npc_id not in _dialogue_db:
		return

	var options = []  # This would be populated from the UI state
	if option_index >= options.size():
		return

	var choice = options[option_index]

	# Apply effects
	_apply_dialogue_effect(npc_id, choice.get("effect", {}))

	# Track choice in NPC memory
	if npc_id not in _npc_memory:
		_npc_memory[npc_id] = []
	_npc_memory[npc_id].append({
		"choice": choice.get("text"),
		"timestamp": Time.get_ticks_msec()
	})

	# Record tone for WordOfMouth
	if "tone" in choice.get("effect", {}):
		WordOfMouth.record_interaction(npc_id, choice["effect"]["tone"])

	# Proceed to next dialogue or end
	if choice.get("next_dialogue"):
		start_dialogue(npc_id, choice["next_dialogue"])
	else:
		dialogue_ended.emit(npc_id, choice.get("text", ""))

func _apply_dialogue_effect(npc_id: String, effect: Dictionary) -> void:
	# Disposition change
	if "disposition" in effect:
		adjust_disposition(npc_id, effect["disposition"])

	# Quest progression
	if "progression" in effect:
		QuestSystem.progress_quest(effect["progression"], "npc_dialogue")

	# State change
	if "state" in effect:
		_npc_memory[npc_id] = {"state": effect["state"]}

	# Entity unlock
	if "entity_unlock" in effect:
		EntityDexData.unlock_entity(effect["entity_unlock"])

# ── Disposition Management ─────────────────────────────────────────────────
func adjust_disposition(npc_id: String, amount: int) -> void:
	if npc_id not in _npc_dispositions:
		_npc_dispositions[npc_id] = 0

	_npc_dispositions[npc_id] = clamp(_npc_dispositions[npc_id] + amount, -100, 100)

func get_disposition(npc_id: String) -> int:
	return _npc_dispositions.get(npc_id, 0)

func set_disposition(npc_id: String, value: int) -> void:
	_npc_dispositions[npc_id] = clamp(value, -100, 100)

# ── Option Filtering ───────────────────────────────────────────────────────
func _filter_options_by_requirements(options: Array[Dictionary]) -> Array[Dictionary]:
	var filtered = []

	for opt in options:
		var req = opt.get("requirements", {})

		# Disposition requirement
		if "min_disposition" in req:
			if opt.get("npc_id") and get_disposition(opt["npc_id"]) < req["min_disposition"]:
				continue

		# Faction requirement
		if "faction" in req:
			if PlayerProfile.faction != req["faction"] and PlayerProfile.faction != "Factionless":
				continue

		# Companion requirement — uses PlayerProfile compat getters
		if "companion_race" in req:
			if PlayerProfile.selected_companion.is_empty() \
					or PlayerProfile.selected_companion_race != req["companion_race"]:
				continue

		# Frame requirement
		if "frame" in req:
			if PlayerProfile.selected_frame != req["frame"]:
				continue

		filtered.append(opt)

	return filtered

# ── Database Loading ───────────────────────────────────────────────────────
func _load_dialogue_db() -> void:
	# Load all dialogue trees from dialogue/ directory
	var dialogue_dir = "res://src/dialogue/"
	var dir = DirAccess.open(dialogue_dir)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var npc_id = file_name.trim_suffix(".json")
				var dialogue_data = JSON.parse_string(
					ResourceLoader.load(dialogue_dir + file_name).get_text()
				)
				if dialogue_data:
					_dialogue_db[npc_id] = dialogue_data
			file_name = dir.get_next()

func _load_dispositions() -> void:
	# Load saved dispositions or initialize to 0
	if FileAccess.file_exists("user://npc_dispositions.json"):
		var data = JSON.parse_string(FileAccess.get_file_as_string("user://npc_dispositions.json"))
		_npc_dispositions = data

# ── Memory Access ─────────────────────────────────────────────────────────
func get_npc_memory(npc_id: String) -> Array:
	return _npc_memory.get(npc_id, [])

func recall_interaction(npc_id: String, days_ago: int = 0) -> Dictionary:
	var memory = get_npc_memory(npc_id)
	if memory.is_empty():
		return {}

	# Return most recent interaction (or specific days_ago)
	if days_ago < memory.size():
		return memory[memory.size() - 1 - days_ago]
	return {}

# ── Save/Load ──────────────────────────────────────────────────────────────
func save_state() -> Dictionary:
	return {
		"dispositions": _npc_dispositions.duplicate(),
		"memory": _npc_memory.duplicate(true)
	}

func load_state(data: Dictionary) -> void:
	_npc_dispositions = data.get("dispositions", {})
	_npc_memory = data.get("memory", {})
