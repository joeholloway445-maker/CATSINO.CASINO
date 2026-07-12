extends Control
class_name PvPRankingUI

const SAVE_PATH := "user://pvp_arena_state.json"
const ROOT_NODE_PATH := "/root/PvPArena"
const LOCAL_PLAYER_ID := "local_player"

var _pvp: PvPArenaSystem
var _rating_label: Label
var _tier_label: Label
var _leaderboard_list: VBoxContainer
var _history_list: VBoxContainer

static func get_or_create_arena_system(owner: Node) -> PvPArenaSystem:
	var existing := owner.get_node_or_null(ROOT_NODE_PATH)
	if existing is PvPArenaSystem:
		return existing as PvPArenaSystem

	var system := PvPArenaSystem.new()
	system.name = "PvPArena"
	owner.get_tree().root.add_child(system)
	load_arena_state(system)
	return system

static func load_arena_state(system: PvPArenaSystem) -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		system.load_state(parsed)

static func save_arena_state(system: PvPArenaSystem) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(system.save_state()))
	file.close()

func _ready() -> void:
	_pvp = get_or_create_arena_system(self)
	if not _pvp.ranked_rating_updated.is_connected(_on_ranked_rating_updated):
		_pvp.ranked_rating_updated.connect(_on_ranked_rating_updated)
	if not _pvp.match_ended.is_connected(_on_match_ended):
		_pvp.match_ended.connect(_on_match_ended)

	_build_ui()
	refresh()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var header := Label.new()
	header.text = "PVP LADDER"
	header.add_theme_font_size_override("font_size", 24)
	root.add_child(header)

	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 16)
	root.add_child(summary)

	_rating_label = Label.new()
	_rating_label.add_theme_font_size_override("font_size", 18)
	summary.add_child(_rating_label)

	_tier_label = Label.new()
	_tier_label.add_theme_font_size_override("font_size", 18)
	_tier_label.modulate = Color(1.0, 0.85, 0.45)
	summary.add_child(_tier_label)

	var refresh_btn := Button.new()
	refresh_btn.text = "Refresh ladder"
	refresh_btn.pressed.connect(refresh)
	summary.add_child(refresh_btn)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 18)
	root.add_child(columns)

	var board_panel := _build_section("Leaderboard")
	columns.add_child(board_panel)
	_leaderboard_list = board_panel.find_child("List", true, false) as VBoxContainer

	var history_panel := _build_section("Recent matches")
	columns.add_child(history_panel)
	_history_list = history_panel.find_child("List", true, false) as VBoxContainer

func _build_section(title_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "List"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	return panel

func refresh() -> void:
	if _pvp == null:
		return

	var rating := _pvp.get_player_rating(LOCAL_PLAYER_ID)
	var tier := _pvp.get_player_tier(LOCAL_PLAYER_ID)
	_rating_label.text = "Rating: %d" % rating
	_tier_label.text = "Tier: %s" % tier.capitalize()

	_render_leaderboard(_pvp.get_leaderboard(50))
	_render_history(_pvp.get_match_history(LOCAL_PLAYER_ID, 20))

func _render_leaderboard(entries: Array[Dictionary]) -> void:
	_clear(_leaderboard_list)
	if entries.is_empty():
		_add_muted_label(_leaderboard_list, "No ranked results yet. Queue a ranked arena match to seed the ladder.")
		return

	for i in range(entries.size()):
		var entry := entries[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var rank := Label.new()
		rank.text = "#%d" % (i + 1)
		rank.custom_minimum_size = Vector2(48, 0)
		row.add_child(rank)

		var name := Label.new()
		name.text = _player_label(str(entry.get("player_id", "unknown")))
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if str(entry.get("player_id", "")) == LOCAL_PLAYER_ID:
			name.modulate = Color(1.0, 0.92, 0.45)
		row.add_child(name)

		var record := Label.new()
		record.text = "%s  %d  W:%d L:%d" % [
			str(entry.get("tier", "bronze")).capitalize(),
			int(entry.get("rating", 1500)),
			int(entry.get("wins", 0)),
			int(entry.get("losses", 0)),
		]
		record.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(record)

		_leaderboard_list.add_child(row)

func _render_history(entries: Array[Dictionary]) -> void:
	_clear(_history_list)
	if entries.is_empty():
		_add_muted_label(_history_list, "No completed PvP matches yet.")
		return

	for entry in entries:
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 2)

		var winner_id := str(entry.get("winner", "unknown"))
		var p1 := str(entry.get("player1_id", "player_1"))
		var p2 := str(entry.get("player2_id", "player_2"))
		var mode := str(entry.get("mode", "ranked")).capitalize()

		var title := Label.new()
		title.text = "%s: %s vs %s" % [mode, _player_label(p1), _player_label(p2)]
		card.add_child(title)

		var detail := Label.new()
		detail.text = "Winner: %s" % _player_label(winner_id)
		detail.modulate = Color(0.7, 0.85, 1.0) if winner_id == LOCAL_PLAYER_ID else Color(0.78, 0.78, 0.82)
		card.add_child(detail)

		_history_list.add_child(card)
		_history_list.add_child(HSeparator.new())

func _clear(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()

func _add_muted_label(container: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color(0.68, 0.68, 0.74)
	container.add_child(label)

func _player_label(player_id: String) -> String:
	if player_id == LOCAL_PLAYER_ID:
		return PlayerProfile.get_display_name() if PlayerProfile.has_method("get_display_name") else "You"
	return player_id.replace("_", " ").capitalize()

func _on_ranked_rating_updated(_player_id: String, _new_rating: int) -> void:
	refresh()
	if _pvp != null:
		save_arena_state(_pvp)

func _on_match_ended(_match_id: String, _winner_id: String) -> void:
	refresh()
	if _pvp != null:
		save_arena_state(_pvp)
