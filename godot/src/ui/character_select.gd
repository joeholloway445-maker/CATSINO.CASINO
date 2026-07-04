extends Control

class_name CharacterSelectUI

# ─── Signals ─────────────────────────────────────────────────────────────────
signal character_confirmed(data: CharacterData)

# ─── Race / Frame / Mod data ─────────────────────────────────────────────────
const RACES: Array[String] = [
	"Keth", "Lumari", "Vex", "Ferox", "Azhul", "Sylva", "Geara", "Nyx",
	"Aquis", "Igni", "Kryos", "Myco", "Volt", "Petra", "Sanguis", "Chimera",
	"Astra", "Ferros", "Etherea", "Glyphe"
]

const FRAMES: Array[String] = [
	"Sleek", "Heavy", "Agile", "Arcane", "Psionic", "Bio", "Mech",
	"Spectral", "Tidal", "Inferno"
]

const MODS: Array[String] = [
	"None", "Neon Whiskers", "Chrome Tail", "Void Eyes", "Storm Paws",
	"Crystal Spine", "Iron Plating", "Phase Fur", "Magma Core", "Root Bind"
]

# ─── Child node references ────────────────────────────────────────────────────
@onready var race_list: OptionButton = $Layout/LeftPanel/RaceOption
@onready var frame_list: OptionButton = $Layout/LeftPanel/FrameOption
@onready var mod_list: OptionButton = $Layout/LeftPanel/ModOption
@onready var name_input: LineEdit = $Layout/LeftPanel/NameInput
@onready var confirm_button: Button = $Layout/LeftPanel/ConfirmButton
@onready var preview_name: Label = $Layout/RightPanel/PreviewPanel/NameLabel
@onready var preview_race: Label = $Layout/RightPanel/PreviewPanel/RaceLabel
@onready var preview_frame: Label = $Layout/RightPanel/PreviewPanel/FrameLabel
@onready var preview_mod: Label = $Layout/RightPanel/PreviewPanel/ModLabel
@onready var stat_pow: Label = $Layout/RightPanel/StatsPanel/PowLabel
@onready var stat_res: Label = $Layout/RightPanel/StatsPanel/ResLabel
@onready var stat_spd: Label = $Layout/RightPanel/StatsPanel/SpdLabel
@onready var stat_lck: Label = $Layout/RightPanel/StatsPanel/LckLabel
@onready var stat_sty: Label = $Layout/RightPanel/StatsPanel/StyLabel
@onready var synergy_label: Label = $Layout/RightPanel/StatsPanel/SynergyLabel
@onready var lore_label: RichTextLabel = $Layout/RightPanel/LorePanel/LoreText

# ─── Working data ─────────────────────────────────────────────────────────────
var _current_data: CharacterData = null

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	_populate_option_button(race_list, RACES)
	_populate_option_button(frame_list, FRAMES)
	_populate_option_button(mod_list, MODS)

	race_list.item_selected.connect(_on_selection_changed)
	frame_list.item_selected.connect(_on_selection_changed)
	mod_list.item_selected.connect(_on_selection_changed)
	name_input.text_changed.connect(_on_name_changed)
	confirm_button.pressed.connect(_on_confirm_pressed)

	_refresh_preview()

# ─── Population helpers ───────────────────────────────────────────────────────
func _populate_option_button(btn: OptionButton, items: Array[String]) -> void:
	btn.clear()
	for item in items:
		btn.add_item(item)

# ─── Preview refresh ─────────────────────────────────────────────────────────
func _refresh_preview() -> void:
	var race_name := RACES[race_list.selected]
	var frame_name := FRAMES[frame_list.selected]
	var mod_name := MODS[mod_list.selected]
	var char_name := name_input.text.strip_edges()

	if char_name.is_empty():
		char_name = race_name + " Cat"

	# Build a working CharacterData resource
	_current_data = CharacterData.new()
	_current_data.character_name = char_name
	_current_data.race = race_name
	_current_data.frame = frame_name
	_current_data.mod = mod_name

	# Update UI labels
	preview_name.text = char_name
	preview_race.text = "Race: %s" % race_name
	preview_frame.text = "Frame: %s" % frame_name
	preview_mod.text = "Mod: %s" % mod_name

	# Display computed stats
	var stats := _current_data.get_base_stats()
	stat_pow.text = "POW %d" % stats.get("pow", 0)
	stat_res.text = "RES %d" % stats.get("res", 0)
	stat_spd.text = "SPD %d" % stats.get("spd", 0)
	stat_lck.text = "LCK %d" % stats.get("lck", 0)
	stat_sty.text = "STY %d" % stats.get("sty", 0)

	# Synergy bonus
	var synergy: int = _current_data.compute_synergy_bonus()
	if synergy > 0:
		synergy_label.text = "✦ Synergy Bonus: +%d" % synergy
		synergy_label.modulate = Color(1.0, 0.85, 0.2)
	else:
		synergy_label.text = "No synergy bonus"
		synergy_label.modulate = Color(0.7, 0.7, 0.7)

	# Lore blurb
	var lore := RaceLore.get_lore(race_name)
	lore_label.text = "[b]%s[/b]\n\n[i]%s[/i]\n\n%s" % [
		lore.get("name", race_name),
		lore.get("homeworld", "Unknown"),
		lore.get("lore_blurb", "")
	]

# ─── Signal handlers ─────────────────────────────────────────────────────────
func _on_selection_changed(_index: int) -> void:
	_refresh_preview()

func _on_name_changed(_new_text: String) -> void:
	_refresh_preview()

func _on_confirm_pressed() -> void:
	if _current_data == null:
		return

	var char_name := name_input.text.strip_edges()
	if char_name.is_empty():
		char_name = RACES[race_list.selected] + " Cat"
	_current_data.character_name = char_name

	# Save to AccountManager and transition state
	AccountManager.save_character_data(_current_data)
	character_confirmed.emit(_current_data)
	GameManager.transition_to(GameManager.State.WORLD)
