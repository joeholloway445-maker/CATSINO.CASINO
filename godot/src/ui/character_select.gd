extends Control

class_name CharacterSelectUI

# Character select uses OmniDex registry names exclusively.
# Races show canon Periliminal names; frames are the 20 OmniDex identity
# frames; mods are the 20 morphological rigs.

signal character_confirmed(data: CharacterData)

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

var _current_data: CharacterData = null
var _race_ids: Array[String] = []
var _frame_ids: Array[String] = []
var _mod_ids: Array[String] = []

func _ready() -> void:
	OmniDexRegistry.assert_invariants()
	_race_ids.clear()
	for r in RaceDataCharacter.RACES:
		_race_ids.append(str(r.id))
		race_list.add_item(OmniDexRegistry.race_display_name(str(r.id)))
	_frame_ids.clear()
	for f in OmniDexRegistry.FRAMES:
		_frame_ids.append(str(f.id))
		frame_list.add_item(str(f.name))
	_mod_ids.clear()
	for m in MorphRigData.RIGS:
		_mod_ids.append(str(m.id))
		mod_list.add_item(str(m.name))

	race_list.item_selected.connect(_on_selection_changed)
	frame_list.item_selected.connect(_on_selection_changed)
	mod_list.item_selected.connect(_on_selection_changed)
	name_input.text_changed.connect(_on_name_changed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	_refresh_preview()

func _refresh_preview() -> void:
	var race_id := _race_ids[race_list.selected]
	var frame_id := _frame_ids[frame_list.selected]
	var mod_id := _mod_ids[mod_list.selected]
	var race_name := OmniDexRegistry.race_display_name(race_id)
	var frame_name := OmniDexRegistry.frame_display_name(frame_id)
	var mod_name := OmniDexRegistry.mod_display_name(mod_id)
	var char_name := name_input.text.strip_edges()
	if char_name.is_empty():
		char_name = "%s Wanderer" % race_name

	_current_data = CharacterData.new()
	_current_data.character_name = char_name
	_current_data.race = race_list.selected as CharacterData.Race
	# Map OmniDex frame index onto sensorium enum when possible; otherwise VEIL.
	_current_data.frame = (frame_list.selected % CharacterData.Frame.size()) as CharacterData.Frame
	_current_data.mod = (mod_list.selected % CharacterData.Mod.size()) as CharacterData.Mod

	preview_name.text = char_name
	preview_race.text = "Race: %s" % race_name
	preview_frame.text = "Frame: %s" % frame_name
	preview_mod.text = "Mod: %s" % mod_name

	var stats := _current_data.compute_total_stats()
	stat_pow.text = "POW %d" % stats.get("pow", 0)
	stat_res.text = "RES %d" % stats.get("res", 0)
	stat_spd.text = "SPD %d" % stats.get("spd", 0)
	stat_lck.text = "LCK %d" % stats.get("lck", 0)
	stat_sty.text = "STY %d" % stats.get("sty", 0)

	var synergy: float = float(stats.get("synergy_bonus", 0.0))
	if synergy > 0.0:
		synergy_label.text = "✦ Synergy Bonus: +%.0f%%" % (synergy * 100.0)
		synergy_label.modulate = Color(1.0, 0.85, 0.2)
	else:
		synergy_label.text = "No synergy bonus"
		synergy_label.modulate = Color(0.7, 0.7, 0.7)

	var breed := RaceDataCharacter.get_race(race_id)
	lore_label.text = "[b]%s[/b]  (casino skin: %s)\n\n[i]Frame %s · Mod %s[/i]\n\n%s" % [
		race_name,
		str(breed.get("name", race_id)),
		frame_name,
		mod_name,
		str(breed.get("lore", "")),
	]

func _on_selection_changed(_index: int) -> void:
	_refresh_preview()

func _on_name_changed(_new_text: String) -> void:
	_refresh_preview()

func _on_confirm_pressed() -> void:
	if _current_data == null:
		return
	var race_name := OmniDexRegistry.race_display_name(_race_ids[race_list.selected])
	var char_name := name_input.text.strip_edges()
	if char_name.is_empty():
		char_name = "%s Wanderer" % race_name
	_current_data.character_name = char_name
	AccountManager.save_character_data(_current_data)
	character_confirmed.emit(_current_data)
	GameManager.transition_to(GameManager.State.WORLD)
