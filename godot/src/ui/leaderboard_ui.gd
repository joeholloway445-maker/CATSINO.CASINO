extends Control

const TAB_NAMES: Array[String] = ["weekly_coins", "all_time_wins", "tournament_champion", "racing_lap_times"]
const REFRESH_INTERVAL: float = 60.0

var _current_tab: String = "weekly_coins"
var _tab_bar: TabBar
var _list_container: VBoxContainer
var _refresh_timer: Timer
var _current_player_username: String = ""

func _ready() -> void:
	_current_player_username = AccountManager.get_username() if AccountManager and AccountManager.has_method("get_username") else ""
	_build_ui()
	_start_auto_refresh()
	refresh_leaderboard(_current_tab)
	UINav.add_back_button(self)

func _build_ui() -> void:
	var layout = VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	_tab_bar = TabBar.new()
	_tab_bar.custom_minimum_size = Vector2(0, 40)
	for tab in TAB_NAMES:
		_tab_bar.add_tab(tab.replace("_", " ").capitalize())
	_tab_bar.tab_changed.connect(_on_tab_changed)
	layout.add_child(_tab_bar)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	_list_container = VBoxContainer.new()
	_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_container)

func _start_auto_refresh() -> void:
	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = REFRESH_INTERVAL
	_refresh_timer.autostart = true
	_refresh_timer.timeout.connect(func(): refresh_leaderboard(_current_tab))
	add_child(_refresh_timer)

func refresh_leaderboard(tab: String) -> void:
	_current_tab = tab
	var response = await CasinoHTTPClient.get_leaderboard(tab)
	if response == null:
		_render_error("Failed to load leaderboard")
		return
	var entries: Array = response.get("records", [])
	_render_entries(entries, response.get("caller_rank", -1))

func _render_entries(entries: Array, caller_rank: int) -> void:
	for child in _list_container.get_children():
		child.queue_free()
	for i in range(entries.size()):
		var entry = entries[i]
		var row = _build_row(i + 1, entry, caller_rank)
		_list_container.add_child(row)

func _build_row(rank: int, entry: Dictionary, caller_rank: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	var username: String = entry.get("username", "Unknown")
	var is_current_player: bool = (username == _current_player_username or rank == caller_rank)
	if is_current_player:
		var bg = ColorRect.new()
		bg.color = Color(1.0, 0.9, 0.0, 0.15)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.add_child(bg)

	var rank_label = Label.new()
	rank_label.text = "#%d" % rank
	rank_label.custom_minimum_size = Vector2(60, 0)
	row.add_child(rank_label)

	var name_label = Label.new()
	name_label.text = username
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_current_player:
		name_label.add_theme_color_override("font_color", Color.YELLOW)
	row.add_child(name_label)

	var score_label = Label.new()
	score_label.text = str(entry.get("score", 0))
	score_label.custom_minimum_size = Vector2(120, 0)
	row.add_child(score_label)

	var faction: String = entry.get("faction", "Factionless")
	var badge = ColorRect.new()
	badge.custom_minimum_size = Vector2(20, 20)
	badge.color = _faction_color(faction)
	row.add_child(badge)

	return row

func _faction_color(faction: String) -> Color:
	match faction:
		"SovereignCrown": return Color.GOLD
		"VeiledCurrent": return Color.DARK_CYAN
		"WildlandsAscendant": return Color.FOREST_GREEN
		_: return Color.GRAY

func _render_error(msg: String) -> void:
	for child in _list_container.get_children():
		child.queue_free()
	var lbl = Label.new()
	lbl.text = msg
	_list_container.add_child(lbl)

func _on_tab_changed(index: int) -> void:
	if index < TAB_NAMES.size():
		refresh_leaderboard(TAB_NAMES[index])
