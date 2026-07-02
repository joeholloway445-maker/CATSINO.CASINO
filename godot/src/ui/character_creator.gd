extends Control
class_name CharacterCreator
# First-time character creation — pick race, faction, frame, name.
# Wired to RaceDataCharacter/FrameModData/CharacterCreatorLogic (the real
# stat/lore data layer) and renders a live 3D preview via CharacterRig
# (ported from THE-HDV-CORE) instead of a static placeholder label.

signal character_created(config: Dictionary)

const CharacterPreviewScene := preload("res://scenes/character/character_preview.tscn")

var _name_field: LineEdit
var _race_selector: OptionButton
var _faction_selector: OptionButton
var _frame_selector: OptionButton
var _lore_label: Label
var _preview: Node3D
var _preview_viewport: SubViewport

const FACTIONS = ["Factionless", "SovereignCrown", "WildlandsAscendant", "VeiledCurrent"]

const STARTER_FRAMES = ["veil", "zephyr", "viper", "bastion", "tremor", "phantom"]

func _ready() -> void:
	_build_ui()
	_update_preview()

func _build_ui() -> void:
	var root = HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var left = VBoxContainer.new()
	left.custom_minimum_size = Vector2(440, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(left)

	var title = Label.new()
	title.text = "CREATE YOUR CAT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	left.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Your name, race, and faction define your identity in Paw Vegas."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.7, 0.7, 0.7)
	left.add_child(subtitle)

	var form = VBoxContainer.new()
	form.custom_minimum_size = Vector2(400, 0)
	form.set_anchors_preset(Control.PRESET_CENTER)
	left.add_child(form)

	# Name
	var name_row = HBoxContainer.new()
	form.add_child(name_row)
	var name_lbl = Label.new()
	name_lbl.text = "Name:"
	name_lbl.custom_minimum_size = Vector2(100, 0)
	name_row.add_child(name_lbl)
	_name_field = LineEdit.new()
	_name_field.placeholder_text = "Enter cat name..."
	_name_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_field.max_length = 20
	name_row.add_child(_name_field)

	# Race
	var race_row = HBoxContainer.new()
	form.add_child(race_row)
	var race_lbl = Label.new()
	race_lbl.text = "Race:"
	race_lbl.custom_minimum_size = Vector2(100, 0)
	race_row.add_child(race_lbl)
	_race_selector = OptionButton.new()
	_race_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for race in RaceDataCharacter.RACES:
		_race_selector.add_item(race.name)
	_race_selector.item_selected.connect(func(_i): _update_preview())
	race_row.add_child(_race_selector)

	# Faction
	var faction_row = HBoxContainer.new()
	form.add_child(faction_row)
	var faction_lbl = Label.new()
	faction_lbl.text = "Faction:"
	faction_lbl.custom_minimum_size = Vector2(100, 0)
	faction_row.add_child(faction_lbl)
	_faction_selector = OptionButton.new()
	_faction_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for faction in FACTIONS:
		_faction_selector.add_item(faction)
	_faction_selector.item_selected.connect(func(_i): _update_preview())
	faction_row.add_child(_faction_selector)

	# Starter frame
	var frame_row = HBoxContainer.new()
	form.add_child(frame_row)
	var frame_lbl = Label.new()
	frame_lbl.text = "Frame:"
	frame_lbl.custom_minimum_size = Vector2(100, 0)
	frame_row.add_child(frame_lbl)
	_frame_selector = OptionButton.new()
	_frame_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for frame_id in STARTER_FRAMES:
		var frame_data := FrameModData.get_frame(frame_id)
		_frame_selector.add_item(frame_data.get("name", frame_id.capitalize()))
	_frame_selector.item_selected.connect(func(_i): _update_preview())
	frame_row.add_child(_frame_selector)

	# Lore / stats readout
	_lore_label = Label.new()
	_lore_label.text = ""
	_lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_lore_label.custom_minimum_size = Vector2(400, 80)
	_lore_label.modulate = Color(0.8, 0.9, 1.0)
	form.add_child(_lore_label)

	# Create button
	var create_btn = Button.new()
	create_btn.text = "🐱 CREATE CAT"
	create_btn.add_theme_font_size_override("font_size", 18)
	create_btn.pressed.connect(_on_create_pressed)
	form.add_child(create_btn)

	# Live 3D preview (right side), ported from THE-HDV-CORE
	_preview_viewport = SubViewport.new()
	_preview_viewport.size = Vector2i(480, 480)
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_preview = CharacterPreviewScene.instantiate()
	_preview_viewport.add_child(_preview)

	var preview_container = SubViewportContainer.new()
	preview_container.stretch = true
	preview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_container.add_child(_preview_viewport)
	root.add_child(preview_container)

func _selected_race_id() -> String:
	return RaceDataCharacter.RACES[_race_selector.selected].id

func _update_preview() -> void:
	var race_id := _selected_race_id()
	var faction = FACTIONS[_faction_selector.selected]
	var frame_id = STARTER_FRAMES[_frame_selector.selected]
	var race_data := RaceDataCharacter.get_race(race_id)
	var stats := CharacterCreatorLogic.build_starting_stats(race_id, faction, frame_id)
	var sensorium := FrameSensorium.of(frame_id)
	_lore_label.text = "%s\n\n%s\n\nPOW %d  RES %d  SPD %d  LCK %d  STY %d\n\nYou will be 1 in %d. No one else's world will look or sound like yours." % [
		race_data.get("lore", ""), sensorium.desc,
		stats.pow, stats.res, stats.spd, stats.lck, stats.sty,
		IdentityLens.BASE_BUILDS,
	]
	if _preview:
		_preview.preview(race_id, frame_id)

func _on_create_pressed() -> void:
	var cat_name = _name_field.text.strip_edges()
	if not CharacterCreatorLogic.validate_name(cat_name):
		_lore_label.text = "⚠️ Enter a valid name (2-20 letters/numbers, no spaces)."
		return

	var race_id := _selected_race_id()
	var faction = FACTIONS[_faction_selector.selected]
	var frame_id = STARTER_FRAMES[_frame_selector.selected]

	var config = {
		"name": cat_name,
		"race": race_id,
		"faction": faction,
		"frame": frame_id,
	}

	CharacterCreatorLogic.apply_creation(race_id, faction, frame_id, cat_name)
	character_created.emit(config)
