extends Control

signal quest_accepted_from_ui(quest_id: String)

const FACTION_QUESTS_PATH := "res://src/quests/data/all_faction_quests.json"
const STATUS_ALL := "All"
const STATUS_AVAILABLE := "Available"
const STATUS_ACTIVE := "Active"
const STATUS_COMPLETED := "Completed"

var _faction_filter: OptionButton
var _status_filter: OptionButton
var _quest_list: ItemList
var _detail_panel: VBoxContainer
var _empty_detail: Label
var _selected_quest_id := ""
var _quest_rows: Array[Dictionary] = []

func _ready() -> void:
	_register_faction_quests()
	_build_ui()
	_refresh()
	if QuestManager:
		QuestManager.quest_accepted.connect(func(_id): _populate_all())
		QuestManager.quest_completed.connect(func(_id, _r): _populate_all())
		QuestManager.quest_failed.connect(func(_id): _populate_all())
		QuestManager.objective_progress.connect(func(_q, _o, _c, _t): _populate_all())
	UINav.add_back_button(self)

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var title := Label.new()
	title.text = "QUEST LOG"
	title.add_theme_font_size_override("font_size", 20)
	root.add_child(title)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(split)

	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(320, 0)
	sidebar.add_theme_constant_override("separation", 8)
	split.add_child(sidebar)

	var filter_label := Label.new()
	filter_label.text = "Filters"
	filter_label.add_theme_font_size_override("font_size", 14)
	sidebar.add_child(filter_label)

	_faction_filter = OptionButton.new()
	_faction_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_faction_filter.item_selected.connect(func(_idx): _refresh())
	sidebar.add_child(_faction_filter)

	_status_filter = OptionButton.new()
	_status_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for status in [STATUS_ALL, STATUS_AVAILABLE, STATUS_ACTIVE, STATUS_COMPLETED]:
		_status_filter.add_item(status)
	_status_filter.item_selected.connect(func(_idx): _refresh())
	sidebar.add_child(_status_filter)

	_quest_list = ItemList.new()
	_quest_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_quest_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quest_list.item_selected.connect(_on_quest_selected)
	sidebar.add_child(_quest_list)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(detail_scroll)

	_detail_panel = VBoxContainer.new()
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_panel.add_theme_constant_override("separation", 10)
	detail_scroll.add_child(_detail_panel)

	_empty_detail = Label.new()
	_empty_detail.text = "Select a quest to view objectives, rewards, and branches."
	_empty_detail.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail_panel.add_child(_empty_detail)

func _populate_all() -> void:
	_refresh()

func _refresh() -> void:
	_refresh_faction_filter()
	_refresh_quest_list()
	if _selected_quest_id == "" and _quest_rows.size() > 0:
		_selected_quest_id = str(_quest_rows[0].get("id", ""))
	if _selected_quest_id != "":
		_select_row_for_quest(_selected_quest_id)
	_show_detail(_selected_quest_id)

func _refresh_faction_filter() -> void:
	var selected := _current_faction_filter()
	var factions: Array[String] = [STATUS_ALL]
	for row in _all_quest_rows():
		var quest: Dictionary = row.get("quest", {})
		var faction := _quest_faction(quest)
		if faction not in factions:
			factions.append(faction)
	_faction_filter.clear()
	for faction in factions:
		_faction_filter.add_item(faction)
	var selected_index := factions.find(selected)
	_faction_filter.select(maxi(selected_index, 0))

func _refresh_quest_list() -> void:
	_quest_rows = _filtered_quests()
	_quest_list.clear()
	var selected_still_visible := false
	for row in _quest_rows:
		var quest_id := str(row.get("id", ""))
		var status := str(row.get("status", STATUS_AVAILABLE))
		var quest := row.get("quest", {})
		var label := "[%s] %s" % [status, quest.get("name", quest_id)]
		var index := _quest_list.add_item(label)
		_quest_list.set_item_metadata(index, quest_id)
		if quest_id == _selected_quest_id:
			selected_still_visible = true
	if not selected_still_visible:
		_selected_quest_id = ""
	if _selected_quest_id == "" and _quest_rows.size() > 0:
		_selected_quest_id = str(_quest_rows[0].get("id", ""))

func _filtered_quests() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var faction_filter := _current_faction_filter()
	var status_filter := _current_status_filter()
	for row in _all_quest_rows():
		var status := str(row.get("status", STATUS_AVAILABLE))
		if status_filter != STATUS_ALL and status != status_filter:
			continue
		var quest: Dictionary = row.get("quest", {})
		var faction := _quest_faction(quest)
		if faction_filter != STATUS_ALL and faction != faction_filter:
			continue
		rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary):
		var a_quest: Dictionary = a.get("quest", {})
		var b_quest: Dictionary = b.get("quest", {})
		var a_key := "%s:%s:%s" % [a.get("status", ""), _quest_faction(a_quest), a_quest.get("name", "")]
		var b_key := "%s:%s:%s" % [b.get("status", ""), _quest_faction(b_quest), b_quest.get("name", "")]
		return a_key < b_key
	)
	return rows

func _all_quest_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for quest in QuestManager.get_available_quests():
		_add_quest_row(rows, quest, STATUS_AVAILABLE)
	for quest_id in QuestManager.get_active_quest_ids():
		var quest := QuestManager.get_quest(quest_id)
		if not quest.is_empty():
			_add_quest_row(rows, quest, STATUS_ACTIVE)
	for quest_id in QuestManager.get_completed_quest_ids():
		var quest := QuestManager.get_quest(quest_id)
		if not quest.is_empty():
			_add_quest_row(rows, quest, STATUS_COMPLETED)
	return rows

func _add_quest_row(rows: Array[Dictionary], quest: Dictionary, status: String) -> void:
	rows.append({"id": str(quest.get("id", "")), "status": status, "quest": quest})

func _on_quest_selected(index: int) -> void:
	var metadata = _quest_list.get_item_metadata(index)
	_selected_quest_id = str(metadata)
	_show_detail(_selected_quest_id)

func _select_row_for_quest(quest_id: String) -> void:
	for index in range(_quest_list.item_count):
		if str(_quest_list.get_item_metadata(index)) == quest_id:
			_quest_list.select(index)
			return

func _show_detail(quest_id: String) -> void:
	_clear(_detail_panel)
	if quest_id == "":
		_detail_panel.add_child(_empty_label("No quests match these filters."))
		return
	var quest := QuestManager.get_quest(quest_id)
	if quest.is_empty():
		_detail_panel.add_child(_empty_label("Quest data is unavailable."))
		return

	var status := _quest_status(quest_id)
	_add_title_row(quest, status)
	_add_description(quest)
	_add_objectives(quest, status)
	_add_rewards(quest)
	_add_branches(quest)
	_add_actions(quest_id, status)

func _add_title_row(quest: Dictionary, status: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_panel.add_child(row)

	var title := Label.new()
	title.text = quest.get("name", "Unknown Quest")
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

	var badge := Label.new()
	badge.text = "%s / %s" % [status, _quest_faction(quest)]
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(badge)

func _add_description(quest: Dictionary) -> void:
	var desc := Label.new()
	desc.text = quest.get("desc", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.modulate = Color(0.78, 0.78, 0.78)
	_detail_panel.add_child(desc)

func _add_objectives(quest: Dictionary, status: String) -> void:
	_detail_panel.add_child(_section_label("Objectives"))
	var progress := _quest_progress(quest, status)
	for objective in quest.get("objectives", []):
		var objective_id := str(objective.get("id", ""))
		var target := int(objective.get("target", 1))
		var current := int(progress.get(objective_id, 0))
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		_detail_panel.add_child(box)

		var row := HBoxContainer.new()
		box.add_child(row)

		var check := CheckBox.new()
		check.disabled = true
		check.button_pressed = current >= target
		row.add_child(check)

		var label := Label.new()
		label.text = "%s (%d/%d)" % [objective.get("desc", objective_id), current, target]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = maxf(float(target), 1.0)
		bar.value = clampf(float(current), 0.0, bar.max_value)
		bar.show_percentage = false
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(bar)

func _add_rewards(quest: Dictionary) -> void:
	_detail_panel.add_child(_section_label("Rewards"))
	var reward_text := _format_rewards(quest.get("rewards", {}))
	_detail_panel.add_child(_body_label(reward_text if reward_text != "" else "No listed rewards."))

func _add_branches(quest: Dictionary) -> void:
	var branches: Dictionary = quest.get("branches", {})
	if branches.is_empty():
		return
	_detail_panel.add_child(_section_label("Branches"))
	for stage_name in branches.keys():
		var stage_branches: Dictionary = branches[stage_name]
		if stage_branches.size() < 2:
			continue
		var stage_label := Label.new()
		stage_label.text = str(stage_name)
		stage_label.add_theme_font_size_override("font_size", 13)
		_detail_panel.add_child(stage_label)
		var branch_row := HBoxContainer.new()
		branch_row.add_theme_constant_override("separation", 8)
		_detail_panel.add_child(branch_row)
		for branch_id in stage_branches.keys():
			var branch_data: Dictionary = stage_branches[branch_id]
			var card := PanelContainer.new()
			card.custom_minimum_size = Vector2(180, 80)
			branch_row.add_child(card)
			var body := VBoxContainer.new()
			card.add_child(body)
			body.add_child(_body_label(str(branch_id).replace("_", " ").capitalize()))
			var rewards := _format_rewards(branch_data.get("rewards", {}))
			if rewards != "":
				var rewards_label := _body_label(rewards)
				rewards_label.modulate = Color(1.0, 0.9, 0.35)
				body.add_child(rewards_label)

func _add_actions(quest_id: String, status: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_detail_panel.add_child(row)

	if status == STATUS_AVAILABLE:
		var accept_btn := Button.new()
		accept_btn.text = "Accept Quest"
		accept_btn.pressed.connect(func():
			if QuestManager.accept(quest_id):
				quest_accepted_from_ui.emit(quest_id)
				_refresh()
		)
		row.add_child(accept_btn)
	elif status == STATUS_ACTIVE:
		var abandon_btn := Button.new()
		abandon_btn.text = "Abandon Quest"
		abandon_btn.pressed.connect(func():
			if QuestManager.abandon(quest_id):
				_refresh()
		)
		row.add_child(abandon_btn)

func _quest_progress(quest: Dictionary, status: String) -> Dictionary:
	if status == STATUS_ACTIVE:
		return QuestManager.get_progress(str(quest.get("id", "")))
	if status == STATUS_COMPLETED:
		var complete_progress: Dictionary = {}
		for objective in quest.get("objectives", []):
			complete_progress[str(objective.get("id", ""))] = int(objective.get("target", 1))
		return complete_progress
	return {}

func _quest_status(quest_id: String) -> String:
	if QuestManager.is_complete(quest_id):
		return STATUS_COMPLETED
	if QuestManager.is_active(quest_id):
		return STATUS_ACTIVE
	return STATUS_AVAILABLE

func _quest_faction(quest: Dictionary) -> String:
	if quest.has("faction"):
		return str(quest.get("faction", "Factionless"))
	var rewards: Dictionary = quest.get("rewards", {})
	var faction_rep: Dictionary = rewards.get("faction_rep", {})
	if not faction_rep.is_empty():
		return str(faction_rep.keys()[0])
	var quest_type := int(quest.get("type", -1))
	if quest_type == QuestManager.QuestType.FACTION:
		return "Factionless"
	return "All Factions"

func _current_faction_filter() -> String:
	if _faction_filter == null or _faction_filter.item_count == 0 or _faction_filter.selected < 0:
		return STATUS_ALL
	return _faction_filter.get_item_text(_faction_filter.selected)

func _current_status_filter() -> String:
	if _status_filter == null or _status_filter.item_count == 0 or _status_filter.selected < 0:
		return STATUS_ALL
	return _status_filter.get_item_text(_status_filter.selected)

func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	return label

func _body_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	return label

func _empty_label(text: String) -> Label:
	var label := _body_label(text)
	label.modulate = Color(0.7, 0.7, 0.7)
	return label

func _clear(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

func _format_rewards(rewards: Dictionary) -> String:
	if rewards.is_empty():
		return ""
	var parts: Array = []
	var coins := int(rewards.get("coins", rewards.get("currency", 0)))
	if coins != 0:
		parts.append("%d coins" % coins)
	var xp := int(rewards.get("xp", 0))
	if xp != 0:
		parts.append("%d XP" % xp)
	var gems := int(rewards.get("gems", 0))
	if gems != 0:
		parts.append("%d gems" % gems)
	if rewards.has("companion_unlock"):
		parts.append("Companion: %s" % str(rewards["companion_unlock"]))
	if rewards.has("ability_unlock"):
		parts.append("Ability: %s" % str(rewards["ability_unlock"]).replace("_", " ").capitalize())
	var faction_rep: Dictionary = rewards.get("faction_rep", {})
	for faction in faction_rep.keys():
		parts.append("%s %+d rep" % [faction, int(faction_rep[faction])])
	return " | ".join(parts)

func _register_faction_quests() -> void:
	if not FileAccess.file_exists(FACTION_QUESTS_PATH):
		push_warning("[QuestUI] Missing faction quest data: " + FACTION_QUESTS_PATH)
		return
	var file := FileAccess.open(FACTION_QUESTS_PATH, FileAccess.READ)
	if file == null:
		push_warning("[QuestUI] Could not open faction quest data: " + FACTION_QUESTS_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Array):
		push_warning("[QuestUI] Faction quest data must be an array.")
		return
	for raw in parsed:
		if raw is Dictionary:
			QuestManager.register_quest(_convert_faction_quest(raw))

func _convert_faction_quest(raw: Dictionary) -> Dictionary:
	var objectives: Array[Dictionary] = []
	var branches: Dictionary = {}
	var stages: Array = raw.get("stages", [])
	for index in range(stages.size()):
		var stage = stages[index]
		if not (stage is Dictionary):
			continue
		var stage_title := str(stage.get("title", "Stage %d" % (index + 1)))
		var stage_objectives: Dictionary = stage.get("objectives", {})
		for objective_id in stage_objectives.keys():
			var objective_data: Dictionary = stage_objectives[objective_id]
			objectives.append({
				"id": str(objective_id),
				"desc": "%s: %s" % [stage_title, str(objective_id).replace("_", " ").capitalize()],
				"target": int(objective_data.get("target", 1)),
				"type": str(objective_data.get("type", "")),
				"stage": stage_title,
			})
		var stage_branches: Dictionary = stage.get("branches", {})
		if not stage_branches.is_empty():
			branches[stage_title] = stage_branches.duplicate(true)
	var prereq: Array[String] = []
	var prerequisites: Dictionary = raw.get("prerequisites", {})
	for quest_id in prerequisites.get("requires_quests", []):
		prereq.append(str(quest_id))
	return {
		"id": str(raw.get("id", "")),
		"type": QuestManager.QuestType.FACTION,
		"name": str(raw.get("title", raw.get("id", ""))),
		"desc": str(raw.get("description", "")),
		"objectives": objectives,
		"rewards": _normalize_rewards(raw.get("rewards", {})),
		"prereq": prereq,
		"faction": str(raw.get("faction", "Factionless")),
		"branches": branches,
	}

func _normalize_rewards(raw_rewards: Dictionary) -> Dictionary:
	var rewards := raw_rewards.duplicate(true)
	if rewards.has("currency") and not rewards.has("coins"):
		rewards["coins"] = int(rewards["currency"])
	return rewards
