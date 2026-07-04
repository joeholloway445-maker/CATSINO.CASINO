class_name PlayerInfluencePack
extends Resource
## A player's "texture/light/sound" signature — the thing that bleeds into a
## chunk's dominant_pack when that player is part of the party that first
## discovers (or keeps revisiting) it. Perception decides how much weight a
## given visit carries relative to the rest of the party.

@export var player_id: String = ""
@export var perception: int = 1
@export var texture_tint: Color = Color.WHITE
@export var light_color: Color = Color.WHITE
@export var light_energy_mult: float = 1.0
@export var ambient_sound_bus: String = "Master"

static func from_loadout(player_id: String, loadout: Dictionary, perception: int) -> PlayerInfluencePack:
	var pack := PlayerInfluencePack.new()
	pack.player_id = player_id
	pack.perception = max(perception, 1)
	var race: Dictionary = loadout.get("race", {})
	pack.texture_tint = race.get("primary_color", Color.WHITE)
	pack.light_color = race.get("primary_color", Color.WHITE)
	return pack
