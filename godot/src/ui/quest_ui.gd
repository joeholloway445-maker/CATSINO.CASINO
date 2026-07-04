extends Control

signal quest_accepted_from_ui(quest_id: String)

var _tabs: TabContainer
var _available_list: VBoxContainer
var _active_list: VBoxContainer
var _completed_list: VBoxContainer

func _ready() -> void:
	_build_ui()
	_populate_all()
	QuestManager.quest_accepted.connect(func(_id): _populate_all())
	QuestManager.quest_completed.connect(func(_id, _r): _populate_all())
	QuestManager.objective_progress.connect(func(_q, _o, _c, _t): _populate_active())

func _build_ui() -> void:
	var root = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title = Label.new()
	title.text = "QUESTS"
	title.add_theme_font_size_override("font_size", 20)
	root.add_child(title)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_tabs)

	var avail_scroll = ScrollContainer.new()
	avail_scroll.name = "Available"
	_tabs.add_child(avail_scroll)
	_available_list = VBoxContainer.new()
	_available_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	avail_scroll.add_child(_available_list)

	var active_scroll = ScrollContainer.new()
	active_scroll.name = "Active"
	_tabs.add_child(active_scroll)
	_active_list = VBoxContainer.new()
	_active_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	active_scroll.add_child(_active_list)

	var done_scroll = ScrollContainer.new()
	done_scroll.name = "Completed"
	_tabs.add_child(done_scroll)
	_completed_list = VBoxContainer.new()
	_completed_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	done_scroll.add_child(_completed_list)

func _populate_all() -> void:
	_populate_available()
	_populate_active()
	_populate_completed()

func _populate_available() -> void:
	for c in _available_list.get_children(): c.queue_free()
	for q in QuestManager.get_available_quests():
		var card = _build_quest_card(q, true)
		_available_list.add_child(card)

func _populate_active() -> void:
	for c in _active_list.get_children(): c.queue_free()
	for quest_id in QuestManager._active.keys():
		var q = QuestManager._find_quest(quest_id)
		if q.is_empty(): continue
		var progress = QuestManager._active[quest_id].get("progress", {})
		var card = _build_quest_card(q, false, progress)
		_active_list.add_child(card)

func _populate_completed() -> void:
	for c in _completed_list.get_children(): c.queue_free()
	for quest_id in QuestManager._completed:
		var q = QuestManager._find_quest(quest_id)
		if q.is_empty(): continue
		var lbl = Label.new()
		lbl.text = "✅ %s" % q.get("name", "")
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.modulate = Color(0.5, 0.8, 0.5)
		_completed_list.add_child(lbl)

func _build_quest_card(q: Dictionary, show_accept: bool, progress: Dictionary = {}) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 80)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var name_row = HBoxContainer.new()
	vbox.add_child(name_row)

	var name_lbl = Label.new()
	name_lbl.text = q.get("name", "")
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_lbl)

	if show_accept:
		var accept_btn = Button.new()
		accept_btn.text = "Accept"
		var qid = q.get("id", "")
		accept_btn.pressed.connect(func():
			QuestManager.accept(qid)
			quest_accepted_from_ui.emit(qid)
		)
		name_row.add_child(accept_btn)

	var desc_lbl = Label.new()
	desc_lbl.text = q.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.modulate = Color(0.7, 0.7, 0.7)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_lbl)

	if not progress.is_empty():
		for obj in q.get("objectives", []):
			var obj_row = HBoxContainer.new()
			vbox.add_child(obj_row)
			var cur = progress.get(obj.get("id", ""), 0)
			var tgt = obj.get("target", 1)
			var obj_lbl = Label.new()
			obj_lbl.text = "  • %s: %d/%d" % [obj.get("desc", ""), cur, tgt]
			obj_lbl.add_theme_font_size_override("font_size", 10)
			obj_lbl.modulate = Color(0.5, 1.0, 0.5) if cur >= tgt else Color(0.8, 0.8, 0.8)
			obj_row.add_child(obj_lbl)

	var reward = q.get("rewards", {})
	if not reward.is_empty():
		var reward_lbl = Label.new()
		var parts = []
		if reward.get("coins", 0) > 0: parts.append("🪙 %d" % reward["coins"])
		if reward.get("xp", 0) > 0: parts.append("⭐ %d XP" % reward["xp"])
		if reward.get("gems", 0) > 0: parts.append("💎 %d" % reward["gems"])
		reward_lbl.text = "Rewards: " + " | ".join(parts)
		reward_lbl.add_theme_font_size_override("font_size", 10)
		reward_lbl.modulate = Color(1.0, 0.9, 0.3)
		vbox.add_child(reward_lbl)

	return panel
