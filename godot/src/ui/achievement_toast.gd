extends CanvasLayer

const TOAST_SIZE := Vector2(360, 96)
const MARGIN := 24.0
const SLIDE_TIME := 0.28
const DISPLAY_TIME := 3.0

var _panel: PanelContainer
var _icon_label: Label
var _name_label: Label
var _desc_label: Label
var _queue: Array[Dictionary] = []
var _showing := false
var _toast_tween: Tween

func _ready() -> void:
	layer = 80
	_build_ui()
	if not AchievementManager.achievement_unlocked.is_connected(_on_achievement_unlocked):
		AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = TOAST_SIZE
	_panel.visible = false
	add_child(_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.035, 0.12, 0.94)
	style.border_color = Color(1.0, 0.78, 0.25, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	_panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	_icon_label = Label.new()
	_icon_label.text = "*"
	_icon_label.custom_minimum_size = Vector2(42, 0)
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_label.add_theme_font_size_override("font_size", 28)
	row.add_child(_icon_label)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)

	var kicker := Label.new()
	kicker.text = "ACHIEVEMENT UNLOCKED"
	kicker.modulate = Color(1.0, 0.82, 0.35)
	kicker.add_theme_font_size_override("font_size", 11)
	text_box.add_child(kicker)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 17)
	text_box.add_child(_name_label)

	_desc_label = Label.new()
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.modulate = Color(0.78, 0.78, 0.84)
	_desc_label.add_theme_font_size_override("font_size", 12)
	text_box.add_child(_desc_label)

func _on_achievement_unlocked(achievement: Dictionary) -> void:
	_queue.append(achievement)
	if not _showing:
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		return

	_showing = true
	var achievement := _queue.pop_front()
	_icon_label.text = str(achievement.get("icon", "*"))
	_name_label.text = str(achievement.get("name", "Achievement"))
	_desc_label.text = str(achievement.get("desc", "Unlocked."))

	var viewport_size := get_viewport().get_visible_rect().size
	var hidden_x := viewport_size.x + MARGIN
	var visible_x := viewport_size.x - TOAST_SIZE.x - MARGIN
	_panel.position = Vector2(hidden_x, MARGIN)
	_panel.visible = true

	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_panel, "position:x", visible_x, SLIDE_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_toast_tween.tween_interval(DISPLAY_TIME)
	_toast_tween.tween_property(_panel, "position:x", hidden_x, SLIDE_TIME).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_toast_tween.tween_callback(func():
		_panel.visible = false
		_showing = false
		_show_next())
