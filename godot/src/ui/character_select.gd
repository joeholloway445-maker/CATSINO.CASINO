extends Control

class_name CharacterSelectUI

signal character_confirmed(data: CharacterData)

const STEP_RACE := 0
const STEP_FRAME := 1
const STEP_MOD := 2
const STEP_CONFIRM := 3
const STAT_KEYS: Array[String] = ["pow", "res", "spd", "lck"]

const LEGACY_RACE_VALUES := [
	CharacterData.Race.KETH,
	CharacterData.Race.LUMARI,
	CharacterData.Race.VEX,
	CharacterData.Race.FEROX,
	CharacterData.Race.AZHUL,
	CharacterData.Race.SYLVA,
	CharacterData.Race.GEARA,
	CharacterData.Race.NYX,
	CharacterData.Race.AQUIS,
	CharacterData.Race.IGNI,
	CharacterData.Race.KRYOS,
	CharacterData.Race.MYCO,
	CharacterData.Race.VOLT,
	CharacterData.Race.PETRA,
	CharacterData.Race.SANGUIS,
	CharacterData.Race.CHIMERA,
	CharacterData.Race.ASTRA,
	CharacterData.Race.FERROS,
	CharacterData.Race.ETHEREA,
	CharacterData.Race.GLYPHE,
]

const LEGACY_FRAME_VALUES := [
	CharacterData.Frame.VEIL,
	CharacterData.Frame.ZEPHYR,
	CharacterData.Frame.VIPER,
	CharacterData.Frame.PHANTOM,
	CharacterData.Frame.CRIMSON,
	CharacterData.Frame.GLACIAL,
	CharacterData.Frame.BOLT,
	CharacterData.Frame.SOUL,
	CharacterData.Frame.CINDER,
	CharacterData.Frame.FLUX,
	CharacterData.Frame.BASTION,
	CharacterData.Frame.TREMOR,
	CharacterData.Frame.BEHEMOTH,
	CharacterData.Frame.BULWARK,
	CharacterData.Frame.IGNIS,
	CharacterData.Frame.GLACI,
	CharacterData.Frame.SURGE,
	CharacterData.Frame.SIEGE,
	CharacterData.Frame.BLIGHT,
	CharacterData.Frame.OSSIAN,
]

const LEGACY_MOD_VALUES := [
	CharacterData.Mod.CATALYST,
	CharacterData.Mod.RESONANCE,
	CharacterData.Mod.PHASE,
	CharacterData.Mod.OVERDRIVE,
	CharacterData.Mod.SINGULARITY,
	CharacterData.Mod.ECHO,
	CharacterData.Mod.PRISM,
	CharacterData.Mod.ENTROPY,
	CharacterData.Mod.ZENITH,
	CharacterData.Mod.APEX,
	CharacterData.Mod.KINETIC,
	CharacterData.Mod.VOLATILE,
	CharacterData.Mod.STATIC,
	CharacterData.Mod.HARMONIC,
	CharacterData.Mod.VOID_CORE,
	CharacterData.Mod.NULL,
	CharacterData.Mod.PRIME,
	CharacterData.Mod.ALPHA,
	CharacterData.Mod.OMEGA,
	CharacterData.Mod.VECTOR,
]

var _identity_system: CharacterIdentitySystem
var _race_ids: Array[String] = []
var _frame_ids: Array[String] = []
var _mod_ids: Array[String] = []

var _step := STEP_RACE
var _selected_race_id := ""
var _selected_frame_id := ""
var _selected_mod_id := ""
var _character_name := ""

var _step_label: Label
var _content: VBoxContainer
var _preview: RichTextLabel
var _back_button: Button
var _next_button: Button
var _name_input: LineEdit

func _ready() -> void:
	_identity_system = CharacterIdentitySystem.new()
	_race_ids = _dictionary_keys(CharacterIdentitySystem.RACES)
	_frame_ids = _dictionary_keys(CharacterIdentitySystem.FRAMES)
	_mod_ids = _dictionary_keys(CharacterIdentitySystem.MODS)
	_build_ui()
	_render_step()
	_refresh_preview()

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 24)
	margin.add_child(layout)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	layout.add_child(left)

	var title := Label.new()
	title.text = "CREATE YOUR VENTURE"
	title.add_theme_font_size_override("font_size", 28)
	left.add_child(title)

	_step_label = Label.new()
	_step_label.add_theme_font_size_override("font_size", 16)
	_step_label.modulate = Color(0.78, 0.86, 1.0)
	left.add_child(_step_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 12)
	left.add_child(nav)

	_back_button = Button.new()
	_back_button.text = "Back"
	_back_button.pressed.connect(_go_back)
	nav.add_child(_back_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(spacer)

	_next_button = Button.new()
	_next_button.text = "Next"
	_next_button.pressed.connect(_go_next)
	nav.add_child(_next_button)

	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(420, 0)
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(preview_panel)

	var preview_margin := MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 18)
	preview_margin.add_theme_constant_override("margin_top", 18)
	preview_margin.add_theme_constant_override("margin_right", 18)
	preview_margin.add_theme_constant_override("margin_bottom", 18)
	preview_panel.add_child(preview_margin)

	_preview = RichTextLabel.new()
	_preview.bbcode_enabled = true
	_preview.fit_content = false
	_preview.scroll_active = true
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_margin.add_child(_preview)

func _render_step() -> void:
	_clear_container(_content)
	_name_input = null
	match _step:
		STEP_RACE:
			_render_races()
		STEP_FRAME:
			_render_frames()
		STEP_MOD:
			_render_mods()
		STEP_CONFIRM:
			_render_confirm()
	_sync_navigation()

func _render_races() -> void:
	_step_label.text = "Step 1 of 4 - Choose a race"
	_add_help("Race drives texture, fur pattern, size, color, and base stat lean.")
	var grid := _choice_grid(2)
	_content.add_child(grid)
	for race_id in _race_ids:
		var race: Dictionary = CharacterIdentitySystem.RACES[race_id]
		var stats: Dictionary = race.get("base_stats", {})
		var body := "%s\n%s coat | %s\nSize x%.2f\n%s" % [
			race.get("cat_type", ""),
			race.get("fur_pattern", ""),
			race.get("texture_type", ""),
			float(race.get("size_modifier", 1.0)),
			_format_stats(stats),
		]
		var choice_id := race_id
		_add_choice_button(
			grid,
			str(race.get("name", race_id.capitalize())),
			body,
			choice_id == _selected_race_id,
			_select_race.bind(choice_id)
		)

func _render_frames() -> void:
	_step_label.text = "Step 2 of 4 - Choose a frame"
	_add_help("Frame sets light, sound theme, class abilities, and class stat bonuses.")
	var grid := _choice_grid(2)
	_content.add_child(grid)
	for frame_id in _frame_ids:
		var frame: Dictionary = CharacterIdentitySystem.FRAMES[frame_id]
		var light_color: Color = frame.get("light_color", Color.WHITE)
		var body := "%s\nLight %s x%.2f\nAbilities: %s\n%s" % [
			frame.get("description", ""),
			_color_hex(light_color),
			float(frame.get("light_intensity", 1.0)),
			_join_strings(frame.get("class_abilities", [])),
			_format_stats(frame.get("stat_bonuses", {})),
		]
		var choice_id := frame_id
		_add_choice_button(
			grid,
			str(frame.get("name", frame_id.capitalize())),
			body,
			choice_id == _selected_frame_id,
			_select_frame.bind(choice_id)
		)

func _render_mods() -> void:
	_step_label.text = "Step 3 of 4 - Choose a mod"
	_add_help("Mod controls combat multipliers, mobility, armor visuals, and final stat modifiers.")
	var grid := _choice_grid(2)
	_content.add_child(grid)
	for mod_id in _mod_ids:
		var mod: Dictionary = CharacterIdentitySystem.MODS[mod_id]
		var body := "%s\n%s\n%s\nArmor: %s" % [
			mod.get("description", ""),
			_format_multipliers(mod),
			_format_stats(mod.get("stat_modifiers", {})),
			mod.get("armor_visual", "none"),
		]
		var choice_id := mod_id
		_add_choice_button(
			grid,
			str(mod.get("name", mod_id.capitalize())),
			body,
			choice_id == _selected_mod_id,
			_select_mod.bind(choice_id)
		)

func _render_confirm() -> void:
	_step_label.text = "Step 4 of 4 - Confirm"
	_add_help("Name the character and confirm the Race -> Frame -> Mod identity.")
	_name_input = LineEdit.new()
	_name_input.placeholder_text = _default_character_name()
	_name_input.text = _character_name
	_name_input.text_changed.connect(func(new_text: String) -> void:
		_character_name = new_text
		_refresh_preview()
		_sync_navigation()
	)
	_content.add_child(_name_input)

	var summary := RichTextLabel.new()
	summary.bbcode_enabled = true
	summary.fit_content = true
	summary.text = _confirmation_summary()
	_content.add_child(summary)

func _add_help(text: String) -> void:
	var help := Label.new()
	help.text = text
	help.autowrap_mode = TextServer.AUTOWRAP_WORD
	help.modulate = Color(0.76, 0.76, 0.82)
	_content.add_child(help)

func _choice_grid(columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	return grid

func _add_choice_button(parent: GridContainer, title: String, body: String, selected: bool, callback: Callable) -> void:
	var button := Button.new()
	button.text = "%s\n%s" % [title.to_upper(), body]
	button.toggle_mode = true
	button.button_pressed = selected
	button.custom_minimum_size = Vector2(310, 136)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.modulate = Color(1.0, 0.92, 0.62) if selected else Color.WHITE
	button.pressed.connect(callback)
	parent.add_child(button)

func _refresh_preview() -> void:
	if _preview == null:
		return
	var lines: Array[String] = ["[b]LIVE PREVIEW[/b]", ""]
	if _selected_race_id.is_empty():
		lines.append("[color=#9aa0aa]Choose a race to begin.[/color]")
		_preview.text = "\n".join(lines)
		return

	var race: Dictionary = CharacterIdentitySystem.RACES.get(_selected_race_id, {})
	lines.append("[b]Race:[/b] %s" % race.get("name", _selected_race_id.capitalize()))
	lines.append("Texture %s | Fur %s | Size x%.2f" % [
		race.get("texture_type", ""),
		race.get("fur_pattern", ""),
		float(race.get("size_modifier", 1.0)),
	])

	if not _selected_frame_id.is_empty():
		var frame: Dictionary = CharacterIdentitySystem.FRAMES.get(_selected_frame_id, {})
		var light_color: Color = frame.get("light_color", Color.WHITE)
		lines.append("")
		lines.append("[b]Frame:[/b] %s" % frame.get("name", _selected_frame_id.capitalize()))
		lines.append("%s | light %s x%.2f" % [
			frame.get("sound_theme", ""),
			_color_hex(light_color),
			float(frame.get("light_intensity", 1.0)),
		])
		lines.append("Abilities: %s" % _join_strings(frame.get("class_abilities", [])))

	if not _selected_mod_id.is_empty():
		var mod: Dictionary = CharacterIdentitySystem.MODS.get(_selected_mod_id, {})
		lines.append("")
		lines.append("[b]Mod:[/b] %s" % mod.get("name", _selected_mod_id.capitalize()))
		lines.append(_format_multipliers(mod))
		lines.append("Armor visual: %s" % mod.get("armor_visual", "none"))

	if _has_complete_selection():
		var complete := _identity_system.get_complete_character(_selected_race_id, _selected_frame_id, _selected_mod_id)
		var stats := _calculate_identity_stats()
		lines.append("")
		lines.append("[b]%s[/b]" % complete.get("name", _default_character_name()))
		lines.append("[color=#ffd88a]POW %d  RES %d  SPD %d  LCK %d[/color]" % [
			stats.get("pow", 0),
			stats.get("res", 0),
			stats.get("spd", 0),
			stats.get("lck", 0),
		])
		lines.append("Mobility x%.2f | Damage x%.2f | Defense x%.2f" % [
			float(complete.get("mobility_multiplier", 1.0)),
			float(complete.get("damage_multiplier", 1.0)),
			float(complete.get("defense_multiplier", 1.0)),
		])
	else:
		lines.append("")
		lines.append("[color=#9aa0aa]Complete each step to see final stats.[/color]")

	_preview.text = "\n".join(lines)

func _go_back() -> void:
	if _step <= STEP_RACE:
		return
	_step -= 1
	_render_step()
	_refresh_preview()

func _select_race(race_id: String) -> void:
	_selected_race_id = race_id
	_render_step()
	_refresh_preview()

func _select_frame(frame_id: String) -> void:
	_selected_frame_id = frame_id
	_render_step()
	_refresh_preview()

func _select_mod(mod_id: String) -> void:
	_selected_mod_id = mod_id
	_render_step()
	_refresh_preview()

func _go_next() -> void:
	if not _can_continue():
		return
	if _step == STEP_CONFIRM:
		character_confirmed.emit(_build_character_data())
		return
	_step += 1
	_render_step()
	_refresh_preview()

func _sync_navigation() -> void:
	if _back_button == null or _next_button == null:
		return
	_back_button.disabled = _step == STEP_RACE
	_next_button.text = "Confirm" if _step == STEP_CONFIRM else "Next"
	_next_button.disabled = not _can_continue()

func _can_continue() -> bool:
	match _step:
		STEP_RACE:
			return not _selected_race_id.is_empty()
		STEP_FRAME:
			return not _selected_frame_id.is_empty()
		STEP_MOD:
			return not _selected_mod_id.is_empty()
		STEP_CONFIRM:
			return _has_complete_selection()
	return false

func _has_complete_selection() -> bool:
	return not _selected_race_id.is_empty() and not _selected_frame_id.is_empty() and not _selected_mod_id.is_empty()

func _build_character_data() -> CharacterData:
	var data := CharacterData.new()
	data.character_name = _character_name.strip_edges()
	if data.character_name.is_empty():
		data.character_name = _default_character_name()
	data.identity_race_id = _selected_race_id
	data.identity_frame_id = _selected_frame_id
	data.identity_mod_id = _selected_mod_id
	data.race = _legacy_value_for_id(_race_ids, LEGACY_RACE_VALUES, _selected_race_id, CharacterData.Race.KETH)
	data.frame = _legacy_value_for_id(_frame_ids, LEGACY_FRAME_VALUES, _selected_frame_id, CharacterData.Frame.VEIL)
	data.mod = _legacy_value_for_id(_mod_ids, LEGACY_MOD_VALUES, _selected_mod_id, CharacterData.Mod.CATALYST)

	var stats := _calculate_identity_stats()
	data.base_pow = int(stats.get("pow", data.base_pow))
	data.base_res = int(stats.get("res", data.base_res))
	data.base_spd = int(stats.get("spd", data.base_spd))
	data.base_lck = int(stats.get("lck", data.base_lck))
	return data

func _calculate_identity_stats() -> Dictionary:
	var totals := {"pow": 10, "res": 10, "spd": 10, "lck": 10}
	if not _selected_race_id.is_empty():
		var race: Dictionary = CharacterIdentitySystem.RACES.get(_selected_race_id, {})
		_add_stats(totals, race.get("base_stats", {}))
	if not _selected_frame_id.is_empty():
		var frame: Dictionary = CharacterIdentitySystem.FRAMES.get(_selected_frame_id, {})
		_add_stats(totals, frame.get("stat_bonuses", {}))
	if not _selected_mod_id.is_empty():
		var mod: Dictionary = CharacterIdentitySystem.MODS.get(_selected_mod_id, {})
		_add_stats(totals, mod.get("stat_modifiers", {}))
	return totals

func _add_stats(target: Dictionary, delta: Dictionary) -> void:
	for key in STAT_KEYS:
		target[key] = int(target.get(key, 0)) + int(delta.get(key, 0))

func _confirmation_summary() -> String:
	if not _has_complete_selection():
		return "[color=#9aa0aa]Make selections in each step before confirming.[/color]"
	var complete := _identity_system.get_complete_character(_selected_race_id, _selected_frame_id, _selected_mod_id)
	var stats := _calculate_identity_stats()
	return "[b]%s[/b]\n\nRace ID: %s\nFrame ID: %s\nMod ID: %s\n\nPOW %d  RES %d  SPD %d  LCK %d" % [
		complete.get("name", _default_character_name()),
		_selected_race_id,
		_selected_frame_id,
		_selected_mod_id,
		stats.get("pow", 0),
		stats.get("res", 0),
		stats.get("spd", 0),
		stats.get("lck", 0),
	]

func _default_character_name() -> String:
	if _selected_race_id.is_empty():
		return "Unnamed"
	var race: Dictionary = CharacterIdentitySystem.RACES.get(_selected_race_id, {})
	return "%s Cat" % str(race.get("name", _selected_race_id.capitalize()))

func _format_stats(stats: Dictionary) -> String:
	var parts: Array[String] = []
	for key in STAT_KEYS:
		if stats.has(key):
			parts.append("%s %+d" % [key.to_upper(), int(stats.get(key, 0))])
	return " ".join(parts) if not parts.is_empty() else "No stat shift"

func _format_multipliers(mod: Dictionary) -> String:
	return "Mobility x%.2f | Damage x%.2f | Defense x%.2f" % [
		float(mod.get("mobility_multiplier", 1.0)),
		float(mod.get("damage_multiplier", 1.0)),
		float(mod.get("defense_multiplier", 1.0)),
	]

func _join_strings(values) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(str(value))
	return ", ".join(parts)

func _color_hex(color: Color) -> String:
	return "#%s" % color.to_html(false)

func _dictionary_keys(source: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for key in source.keys():
		ids.append(str(key))
	return ids

func _legacy_value_for_id(ids: Array[String], values: Array, id: String, fallback: int) -> int:
	var index := ids.find(id)
	if index < 0 or index >= values.size():
		return fallback
	return int(values[index])

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
