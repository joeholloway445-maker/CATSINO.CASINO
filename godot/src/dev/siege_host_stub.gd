extends Node3D
## Headless stand-in for LayerWorld registration — used by gate5/gate6 smokes
## so GuildHideout sieges can prove hotbar/bite wiring without a full layer.
var entities: Dictionary = {}

func _register_world_entity(ent: WorldEntity) -> void:
	if ent == null:
		return
	entities[ent.get_instance_id()] = ent
