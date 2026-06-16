extends Control
class_name CharacterCreator
# First-time character creation — pick race, faction, frame, name

signal character_created(config: Dictionary)

var _name_field: LineEdit
var _race_selector: OptionButton
var _faction_selector: OptionButton
var _frame_selector: OptionButton
var _preview_label: Label

const RACES = [
	"Nyx", "Ember", "Glacial", "Tempest", "Void", "Photon", "Bloom", "Aqua",
	"Aether", "Shadow", "Crimson", "Bolt", "Prism", "Verdant", "Flame",
	"Storm", "Lunar", "Obsidian", "Radiant", "Quantum",
]

const FACTIONS = ["Factionless", "SovereignCrown", "WildlandsAscendant", "VeiledCurrent"]

const STARTER_FRAMES = ["veil", "zephyr", "viper", "bastion", "tremor", "phantom"]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var root = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title = Label.new()
	title.text = "CREATE YOUR CAT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Your name, race, and faction define your identity in Paw Vegas."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.7, 0.7, 0.7)
	root.add_child(subtitle)

	var form = VBoxContainer.new()
	form.custom_minimum_size = Vector2(400, 0)
	form.set_anchors_preset(Control.PRESET_CENTER)
	root.add_child(form)

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
	for race in RACES:
		_race_selector.add_item(race)
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
	for frame in STARTER_FRAMES:
		_frame_selector.add_item(frame.capitalize())
	frame_row.add_child(_frame_selector)

	# Preview
	_preview_label = Label.new()
	_preview_label.text = "Your cat: ?"
	_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_label.modulate = Color(0.8, 0.9, 1.0)
	form.add_child(_preview_label)

	# Create button
	var create_btn = Button.new()
	create_btn.text = "🐱 CREATE CAT"
	create_btn.add_theme_font_size_override("font_size", 18)
	create_btn.pressed.connect(_on_create_pressed)
	form.add_child(create_btn)

func _update_preview() -> void:
	var race = RACES[_race_selector.selected]
	var faction = FACTIONS[_faction_selector.selected]
	var frame = STARTER_FRAMES[_frame_selector.selected]
	_preview_label.text = "%s the %s (%s) in a %s frame" % [
		_name_field.text if not _name_field.text.is_empty() else "???",
		race, faction, frame,
	]

func _on_create_pressed() -> void:
	var cat_name = _name_field.text.strip_edges()
	if cat_name.is_empty():
		_preview_label.text = "⚠️ Enter a name first!"
		return

	var config = {
		"name": cat_name,
		"race": RACES[_race_selector.selected],
		"faction": FACTIONS[_faction_selector.selected],
		"frame": STARTER_FRAMES[_frame_selector.selected],
	}

	if PlayerProfile:
		PlayerProfile.username = config.name
		PlayerProfile.faction = config.faction
		PlayerProfile.selected_frame = config.frame

	character_created.emit(config)
