extends Node3D
## Hosts a CharacterRig and refreshes it from GameData's current loadout.
## Attach to scenes/character/character_preview.tscn.

@onready var rig: Node3D = $CharacterRig

func _ready() -> void:
	refresh()

func refresh() -> void:
	var loadout := GameData.current_loadout()
	rig.build_from_loadout(loadout.get("race", {}), loadout.get("frame", {}), loadout.get("mod", {}))

func preview(race_id: String, frame_id: String, mod_id: String = "") -> void:
	GameData.selected_race_id = race_id
	GameData.selected_frame_id = frame_id
	GameData.selected_mod_id = mod_id
	refresh()
