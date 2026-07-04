extends Node3D
## Hosts a CharacterRig and rebuilds it from a (race_id, frame_id, mod_id)
## selection. Ported from THE-HDV-CORE's character_preview.gd, rewired off
## RaceDataCharacter/FrameModData instead of HDV's GameData autoload since
## the two repos use different race/frame data shapes.

@onready var rig: Node3D = $CharacterRig

var race_id: String = ""
var frame_id: String = ""
var mod_id: String = ""

func _ready() -> void:
	refresh()

func refresh() -> void:
	var loadout := CharacterCreatorLogic.build_loadout(race_id, frame_id, mod_id)
	rig.build_from_loadout(loadout.race, loadout.frame, loadout.mod)

func preview(new_race_id: String, new_frame_id: String, new_mod_id: String = "") -> void:
	race_id = new_race_id
	frame_id = new_frame_id
	mod_id = new_mod_id
	refresh()
