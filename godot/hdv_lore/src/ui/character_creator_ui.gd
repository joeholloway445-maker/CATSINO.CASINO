extends Control
## In-Godot character creation screen — cycles through RaceData/FrameData/
## ModData and previews the result live via CharacterPreview, then commits
## the choice to GameData. Godot-native counterpart to the three.js
## character-creation page on the web client; same data sources, same
## GameData fields, so a character built here matches one built there.

const RaceData = preload("res://hdv_lore/src/data/race_data.gd")
const FrameData = preload("res://hdv_lore/src/data/frame_data.gd")
const ModData = preload("res://hdv_lore/src/data/mod_data.gd")

@onready var preview: Node3D = $PreviewViewportContainer/SubViewport/CharacterPreview
@onready var race_label: Label = $RaceLabel
@onready var frame_label: Label = $FrameLabel
@onready var mod_label: Label = $ModLabel
@onready var info_label: Label = $InfoLabel

var _race_index: int = 0
var _frame_index: int = 0
var _mod_index: int = -1 # -1 == "no mod"

func _ready() -> void:
	_race_index = max(0, RaceData.RACES.find_custom(func(r): return r["id"] == GameData.selected_race_id))
	_frame_index = max(0, FrameData.FRAMES.find_custom(func(f): return f["id"] == GameData.selected_frame_id))
	_mod_index = ModData.MODS.find_custom(func(m): return m["id"] == GameData.selected_mod_id)
	_refresh()

func _cycle(list_size: int, index: int, delta: int) -> int:
	return (index + delta + list_size) % list_size

func _on_race_prev() -> void: _race_index = _cycle(RaceData.RACES.size(), _race_index, -1); _refresh()
func _on_race_next() -> void: _race_index = _cycle(RaceData.RACES.size(), _race_index, 1); _refresh()
func _on_frame_prev() -> void: _frame_index = _cycle(FrameData.FRAMES.size(), _frame_index, -1); _refresh()
func _on_frame_next() -> void: _frame_index = _cycle(FrameData.FRAMES.size(), _frame_index, 1); _refresh()

func _on_mod_prev() -> void:
	_mod_index = -1 if _mod_index <= -1 else _cycle(ModData.MODS.size() + 1, _mod_index + 1, -1) - 1
	_refresh()

func _on_mod_next() -> void:
	_mod_index = -1 if _mod_index >= ModData.MODS.size() - 1 else _mod_index + 1
	_refresh()

func _refresh() -> void:
	var race: Dictionary = RaceData.RACES[_race_index]
	var frame: Dictionary = FrameData.FRAMES[_frame_index]
	var mod: Dictionary = ModData.MODS[_mod_index] if _mod_index >= 0 else {}
	race_label.text = "Race: %s (%s)" % [race["name"], race["faction"]]
	frame_label.text = "Frame: %s — %s" % [frame["name"], frame["role"]]
	mod_label.text = "Mod: %s" % (mod.get("name", "None"))
	info_label.text = "%s\n%s" % [race.get("passive_effect", ""), frame.get("combat_style", "")]
	preview.preview(race["id"], frame["id"], mod.get("id", ""))

## GameData.selected_race_id/frame_id/mod_id are already kept current by
## preview.preview() on every cycle, so confirming is just a navigation step.
func _on_confirm_pressed() -> void:
	get_tree().change_scene_to_file("res://hdv_lore/scenes/worlds/world_select.tscn")
