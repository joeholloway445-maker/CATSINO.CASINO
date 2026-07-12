extends Control
class_name FrameModSelector

signal loadout_changed(frame_id: String, mod_id: String)

var _frame_options: OptionButton
var _mod_options: OptionButton
var _frame_stats_label: Label
var _mod_stats_label: Label
var _preview_label: Label

var _identity_system: CharacterIdentitySystem
var _frame_ids: Array[String] = []
var _mod_ids: Array[String] = []
var _selected_frame: String = ""
var _selected_mod: String = ""

func _ready() -> void:
	_identity_system = CharacterIdentitySystem.new()
	_frame_ids = _dictionary_keys(CharacterIdentitySystem.FRAMES)
	_mod_ids = _dictionary_keys(CharacterIdentitySystem.MODS)
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
		var frame: Dictionary = CharacterIdentitySystem.FRAMES[frame_id]
		_frame_options.add_item(str(frame.get("name", frame_id.capitalize())))

	_mod_options.clear()
	for mod_id in _mod_ids:
		var mod: Dictionary = CharacterIdentitySystem.MODS[mod_id]
		_mod_options.add_item(str(mod.get("name", mod_id.capitalize())))

func _select_defaults() -> void:
	if not _frame_ids.is_empty():
		_selected_frame = _frame_ids[0]
		_frame_options.select(0)
		_frame_stats_label.text = _format_frame(CharacterIdentitySystem.FRAMES[_selected_frame])
	if not _mod_ids.is_empty():
		_selected_mod = _mod_ids[0]
		_mod_options.select(0)
		_mod_stats_label.text = _format_mod(CharacterIdentitySystem.MODS[_selected_mod])

func _on_frame_selected(index: int) -> void:
	if index < 0 or index >= _frame_ids.size():
		_selected_frame = ""
		_frame_stats_label.text = ""
	else:
		_selected_frame = _frame_ids[index]
		_frame_stats_label.text = _format_frame(CharacterIdentitySystem.FRAMES[_selected_frame])
	_update_preview()
	_emit_loadout_changed()

func _on_mod_selected(index: int) -> void:
	if index < 0 or index >= _mod_ids.size():
		_selected_mod = ""
		_mod_stats_label.text = ""
	else:
		_selected_mod = _mod_ids[index]
		_mod_stats_label.text = _format_mod(CharacterIdentitySystem.MODS[_selected_mod])
	_update_preview()
	_emit_loadout_changed()

func _update_preview() -> void:
	if _selected_frame.is_empty() and _selected_mod.is_empty():
		_preview_label.text = "No loadout selected"
		return

	var combined := {"pow": 0, "res": 0, "spd": 0, "lck": 0}
	if not _selected_frame.is_empty():
		var frame: Dictionary = CharacterIdentitySystem.FRAMES.get(_selected_frame, {})
		_add_stats(combined, frame.get("stat_bonuses", {}))
	if not _selected_mod.is_empty():
		var mod: Dictionary = CharacterIdentitySystem.MODS.get(_selected_mod, {})
		_add_stats(combined, mod.get("stat_modifiers", {}))

	var frame_name := "None"
	if not _selected_frame.is_empty():
		frame_name = str(CharacterIdentitySystem.FRAMES.get(_selected_frame, {}).get("name", _selected_frame.capitalize()))
	var mod_name := "None"
	if not _selected_mod.is_empty():
		mod_name = str(CharacterIdentitySystem.MODS.get(_selected_mod, {}).get("name", _selected_mod.capitalize()))
	_preview_label.text = "%s + %s\nCombined bonuses: %s" % [
		frame_name,
		mod_name,
		_format_stats(combined),
	]

func _format_frame(frame: Dictionary) -> String:
	var light_color: Color = frame.get("light_color", Color.WHITE)
	return "%s\nLight #%s x%.2f | Sound: %s\nAbilities: %s\nBonuses: %s" % [
		frame.get("description", ""),
		light_color.to_html(false),
		float(frame.get("light_intensity", 1.0)),
		frame.get("sound_theme", ""),
		_join_strings(frame.get("class_abilities", [])),
		_format_stats(frame.get("stat_bonuses", {})),
	]

func _format_mod(mod: Dictionary) -> String:
	return "%s\nMobility x%.2f | Damage x%.2f | Defense x%.2f\nStats: %s | Armor: %s" % [
		mod.get("description", ""),
		float(mod.get("mobility_multiplier", 1.0)),
		float(mod.get("damage_multiplier", 1.0)),
		float(mod.get("defense_multiplier", 1.0)),
		_format_stats(mod.get("stat_modifiers", {})),
		mod.get("armor_visual", "none"),
	]

func _format_stats(stats: Dictionary) -> String:
	var parts: Array[String] = []
	for key in ["pow", "res", "spd", "lck"]:
		if stats.has(key) and int(stats.get(key, 0)) != 0:
			parts.append("%s %+d" % [key.to_upper(), int(stats.get(key, 0))])
	return ", ".join(parts) if not parts.is_empty() else "No stat bonus"

func _add_stats(target: Dictionary, delta: Dictionary) -> void:
	for key in ["pow", "res", "spd", "lck"]:
		target[key] = int(target.get(key, 0)) + int(delta.get(key, 0))

func _join_strings(values) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(str(value))
	return ", ".join(parts)

func _dictionary_keys(source: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for key in source.keys():
		ids.append(str(key))
	return ids

func _emit_loadout_changed() -> void:
	loadout_changed.emit(_selected_frame, _selected_mod)
