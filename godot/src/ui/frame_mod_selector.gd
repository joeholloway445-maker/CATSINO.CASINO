extends Control
class_name FrameModSelector
# UI for selecting frame and mod loadout

signal loadout_changed(frame_id: String, mod_id: String)

var _frame_options: OptionButton
var _mod_options: OptionButton
var _frame_stats_label: Label
var _mod_stats_label: Label
var _preview_label: Label

var _selected_frame: String = ""
var _selected_mod: String = ""

func _ready() -> void:
	_build_ui()
	_populate_options()

func _build_ui() -> void:
	var root = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title = Label.new()
	title.text = "LOADOUT SELECTOR"
	title.add_theme_font_size_override("font_size", 18)
	root.add_child(title)

	var frame_row = HBoxContainer.new()
	root.add_child(frame_row)

	var frame_lbl = Label.new()
	frame_lbl.text = "Frame:"
	frame_lbl.custom_minimum_size = Vector2(60, 0)
	frame_row.add_child(frame_lbl)

	_frame_options = OptionButton.new()
	_frame_options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_frame_options.item_selected.connect(_on_frame_selected)
	frame_row.add_child(_frame_options)

	_frame_stats_label = Label.new()
	_frame_stats_label.add_theme_font_size_override("font_size", 11)
	_frame_stats_label.modulate = Color(0.7, 0.9, 0.7)
	root.add_child(_frame_stats_label)

	var mod_row = HBoxContainer.new()
	root.add_child(mod_row)

	var mod_lbl = Label.new()
	mod_lbl.text = "Mod:"
	mod_lbl.custom_minimum_size = Vector2(60, 0)
	mod_row.add_child(mod_lbl)

	_mod_options = OptionButton.new()
	_mod_options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mod_options.item_selected.connect(_on_mod_selected)
	mod_row.add_child(_mod_options)

	_mod_stats_label = Label.new()
	_mod_stats_label.add_theme_font_size_override("font_size", 11)
	_mod_stats_label.modulate = Color(0.7, 0.7, 0.9)
	root.add_child(_mod_stats_label)

	var sep = HSeparator.new()
	root.add_child(sep)

	_preview_label = Label.new()
	_preview_label.text = "Select frame and mod to see combined stats"
	_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(_preview_label)

	var confirm_btn = Button.new()
	confirm_btn.text = "Confirm Loadout"
	confirm_btn.pressed.connect(_on_confirm)
	root.add_child(confirm_btn)

func _populate_options() -> void:
	_frame_options.clear()
	_frame_options.add_item("(none)")
	for frame in FrameModData.FRAMES:
		_frame_options.add_item(frame.name)

	_mod_options.clear()
	_mod_options.add_item("(none)")
	for mod in FrameModData.MODS:
		_mod_options.add_item(mod.name)

func _on_frame_selected(index: int) -> void:
	if index == 0:
		_selected_frame = ""
		_frame_stats_label.text = ""
	else:
		var frame = FrameModData.FRAMES[index - 1]
		_selected_frame = frame.id
		var bonus = frame.get("stat_bonus", {})
		_frame_stats_label.text = _format_bonus(bonus)
	_update_preview()

func _on_mod_selected(index: int) -> void:
	if index == 0:
		_selected_mod = ""
		_mod_stats_label.text = ""
	else:
		var mod = FrameModData.MODS[index - 1]
		_selected_mod = mod.id
		var bonus = mod.get("stat_bonus", {})
		_mod_stats_label.text = _format_bonus(bonus)
	_update_preview()

func _update_preview() -> void:
	if _selected_frame.is_empty() and _selected_mod.is_empty():
		_preview_label.text = "No loadout selected"
		return

	var combined = {}
	if not _selected_frame.is_empty():
		var f = FrameModData.get_frame(_selected_frame)
		for stat in f.get("stat_bonus", {}):
			combined[stat] = combined.get(stat, 0) + f["stat_bonus"][stat]
	if not _selected_mod.is_empty():
		var m = FrameModData.get_mod(_selected_mod)
		for stat in m.get("stat_bonus", {}):
			combined[stat] = combined.get(stat, 0) + m["stat_bonus"][stat]

	_preview_label.text = "Combined: " + _format_bonus(combined)

func _format_bonus(bonus: Dictionary) -> String:
	var parts = []
	for key in bonus:
		parts.append("%s: %+d" % [key.to_upper(), bonus[key]])
	return ", ".join(parts) if not parts.is_empty() else "No stat bonus"

func _on_confirm() -> void:
	loadout_changed.emit(_selected_frame, _selected_mod)
