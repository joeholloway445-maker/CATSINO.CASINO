extends Control

const CATEGORY_COLORS: Dictionary = {
	"games": Color(0.0, 0.96, 1.0),
	"economy": Color(1.0, 0.84, 0.0),
	"companions": Color(0.69, 0.15, 1.0),
	"factions": Color(1.0, 0.27, 0.0),
	"world": Color(0.22, 0.55, 0.13),
	"racing": Color(1.0, 0.58, 0.0),
	"social": Color(1.0, 0.17, 0.84),
	"battlepass": Color(0.5, 0.83, 1.0),
	"coliseum": Color(1.0, 0.84, 0.0),
	"combat": Color(0.88, 0.06, 0.06),
}

var _container: VBoxContainer
var _progress_label: Label
var _filter_tabs: HBoxContainer
var _current_filter: String = "all"

func _ready() -> void:
	_build_ui()
	_populate()
	if AchievementManager and AchievementManager.has_signal("achievement_unlocked"):
		AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	UINav.add_back_button(self)

func _build_ui() -> void:
	var root = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 48)
	root.add_child(header)

	var title = Label.new()
	title.text = "ACHIEVEMENTS"
	title.add_theme_font_size_override("font_size", 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_progress_label = Label.new()
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_progress_label)

	_filter_tabs = HBoxContainer.new()
	root.add_child(_filter_tabs)
	_add_filter_tab("all", "All")
	for cat in CATEGORY_COLORS.keys():
		_add_filter_tab(cat, cat.capitalize())

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	_container = VBoxContainer.new()
	_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_container)

func _add_filter_tab(id: String, label_text: String) -> void:
	var btn = Button.new()
	btn.text = label_text
	btn.pressed.connect(func(): _set_filter(id))
	_filter_tabs.add_child(btn)

func _set_filter(filter: String) -> void:
	_current_filter = filter
	_populate()

func _populate() -> void:
	for child in _container.get_children():
		child.queue_free()
	var achievements = AchievementManager.get_all_achievements()
	var total = achievements.size()
	var unlocked = achievements.filter(func(a): return a.unlocked).size()
	_progress_label.text = "%d / %d" % [unlocked, total]

	for a in achievements:
		if _current_filter != "all" and a.get("category", "") != _current_filter:
			continue
		var card = _build_achievement_card(a)
		_container.add_child(card)

func _build_achievement_card(a: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 60)
	if not a.get("unlocked", false):
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.03, 0.1, 0.8)
		panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	var icon = Label.new()
	icon.text = a.get("icon", "🏆")
	icon.custom_minimum_size = Vector2(48, 0)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 24)
	if not a.get("unlocked", false):
		icon.modulate = Color(0.3, 0.3, 0.3)
	hbox.add_child(icon)

	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var name_lbl = Label.new()
	name_lbl.text = a.get("name", "")
	var cat = a.get("category", "games")
	var col = CATEGORY_COLORS.get(cat, Color.WHITE)
	name_lbl.modulate = col if a.get("unlocked", false) else Color(0.5, 0.5, 0.5)
	text_vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = a.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.modulate = Color(0.7, 0.7, 0.7)
	text_vbox.add_child(desc_lbl)

	var xp_lbl = Label.new()
	xp_lbl.text = "+%d XP" % a.get("xp", 0)
	xp_lbl.add_theme_font_size_override("font_size", 10)
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	xp_lbl.custom_minimum_size = Vector2(60, 0)
	xp_lbl.modulate = Color(0.8, 1.0, 0.8) if a.get("unlocked", false) else Color(0.4, 0.4, 0.4)
	hbox.add_child(xp_lbl)

	return panel

func _on_achievement_unlocked(achievement: Dictionary) -> void:
	_populate()
