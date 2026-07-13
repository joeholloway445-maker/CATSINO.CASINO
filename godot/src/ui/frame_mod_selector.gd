extends Control
class_name FrameModSelector
## Standalone frame/mod loadout widget, sourced from the canonical OmniDex
## registry (OmniDexRegistry.FRAMES: 20 Periliminal identity frames = our
## classes; MorphRigData.RIGS: 20 morphological mods = physical body plans
## with a bonus/drawback pair that drive combat math and mobility).
## Not currently instantiated by any scene — kept in sync with the canon
## data so it's safe to wire up later (e.g. a post-creation respec screen).

signal loadout_changed(frame_id: String, mod_id: String)

var _frame_options: OptionButton
var _mod_options: OptionButton
var _frame_stats_label: Label
var _mod_stats_label: Label
var _preview_label: Label

var _frame_ids: Array[String] = []
var _mod_ids: Array[String] = []
var _selected_frame: String = ""
var _selected_mod: String = ""

func _ready() -> void:
	OmniDexRegistry.assert_invariants()
	_frame_ids.clear()
	for f in OmniDexRegistry.FRAMES:
		_frame_ids.append(str(f.id))
	_mod_ids.clear()
	for m in MorphRigData.RIGS:
		_mod_ids.append(str(m.id))
	_build_ui()
	_populate_options()
	_select_defaults()
	_update_preview()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var title := Label.new()
	title.text = "FRAME / MOD LOADOUT"
	title.add_theme_font_size_override("font_size", 18)
	root.add_child(title)

	var frame_row := HBoxContainer.new()
	root.add_child(frame_row)

	var frame_lbl := Label.new()
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
	_frame_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(_frame_stats_label)

	var mod_row := HBoxContainer.new()
	root.add_child(mod_row)

	var mod_lbl := Label.new()
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
	_mod_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(_mod_stats_label)

	var sep := HSeparator.new()
	root.add_child(sep)

	_preview_label = Label.new()
	_preview_label.text = "Select a frame and mod to see loadout details"
	_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(_preview_label)

	var confirm_btn := Button.new()
	confirm_btn.text = "Apply Loadout"
	confirm_btn.pressed.connect(_emit_loadout_changed)
	root.add_child(confirm_btn)

func _populate_options() -> void:
	_frame_options.clear()
	for frame_id in _frame_ids:
		_frame_options.add_item(OmniDexRegistry.frame_display_name(frame_id))

	_mod_options.clear()
	for mod_id in _mod_ids:
		_mod_options.add_item(OmniDexRegistry.mod_display_name(mod_id))

func _select_defaults() -> void:
	if not _frame_ids.is_empty():
		_selected_frame = _frame_ids[0]
		_frame_options.select(0)
		_frame_stats_label.text = _format_frame(OmniDexRegistry.frame_by_id(_selected_frame))
	if not _mod_ids.is_empty():
		_selected_mod = _mod_ids[0]
		_mod_options.select(0)
		_mod_stats_label.text = _format_mod(MorphRigData.by_id(_selected_mod))

func _on_frame_selected(index: int) -> void:
	if index < 0 or index >= _frame_ids.size():
		_selected_frame = ""
		_frame_stats_label.text = ""
	else:
		_selected_frame = _frame_ids[index]
		_frame_stats_label.text = _format_frame(OmniDexRegistry.frame_by_id(_selected_frame))
	_update_preview()
	_emit_loadout_changed()

func _on_mod_selected(index: int) -> void:
	if index < 0 or index >= _mod_ids.size():
		_selected_mod = ""
		_mod_stats_label.text = ""
	else:
		_selected_mod = _mod_ids[index]
		_mod_stats_label.text = _format_mod(MorphRigData.by_id(_selected_mod))
	_update_preview()
	_emit_loadout_changed()

func _update_preview() -> void:
	if _selected_frame.is_empty() and _selected_mod.is_empty():
		_preview_label.text = "No loadout selected"
		return

	var frame_name := "None"
	var frame_role := ""
	if not _selected_frame.is_empty():
		var frame: Dictionary = OmniDexRegistry.frame_by_id(_selected_frame)
		frame_name = str(frame.get("name", _selected_frame.capitalize()))
		frame_role = str(frame.get("role", ""))

	var mod_name := "None"
	var mod_bonus := ""
	var mod_drawback := ""
	if not _selected_mod.is_empty():
		var mod: Dictionary = MorphRigData.by_id(_selected_mod)
		mod_name = str(mod.get("name", _selected_mod.capitalize()))
		mod_bonus = str(mod.get("bonus", ""))
		mod_drawback = str(mod.get("drawback", ""))

	_preview_label.text = "%s (%s) + %s\n%s / %s" % [
		frame_name,
		frame_role,
		mod_name,
		mod_bonus,
		mod_drawback,
	]

func _format_frame(frame: Dictionary) -> String:
	return "%s — %s class\n%s" % [
		frame.get("name", ""),
		frame.get("role", ""),
		frame.get("type", ""),
	]

func _format_mod(mod: Dictionary) -> String:
	return "%s\nBonus: %s | Drawback: %s\n%s" % [
		mod.get("name", ""),
		mod.get("bonus", ""),
		mod.get("drawback", ""),
		mod.get("desc", ""),
	]

func _dictionary_keys(source: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for key in source.keys():
		ids.append(str(key))
	return ids

func _emit_loadout_changed() -> void:
	loadout_changed.emit(_selected_frame, _selected_mod)
