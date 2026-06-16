class_name NPCSpawner
extends Node3D
# Spawns NPCs from world_data/npcs.json via WorldLoader autoload.
# Non-coders: edit godot/world_data/npcs.json to add/change/remove NPCs.

@export var district_id: String = "paw_vegas"

const INTERACTION_RADIUS := 2.5

func _ready() -> void:
	if WorldLoader.districts.is_empty():
		await WorldLoader.world_loaded
	_spawn_npcs()

func _spawn_npcs() -> void:
	var npc_list := WorldLoader.get_npcs_in_district(district_id)
	for npc_data in npc_list:
		_create_npc(npc_data)

func _create_npc(data: Dictionary) -> void:
	var root := Node3D.new()
	root.name = data.get("id", "npc")
	root.position = Vector3(data.get("pos_x", 0.0), data.get("pos_y", 0.0), data.get("pos_z", 0.0))
	add_child(root)

	var label := Label3D.new()
	label.text = "%s\n%s" % [data.get("emoji", "🐱"), data.get("name", "NPC")]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.008
	label.position = Vector3(0, 1.8, 0)
	label.modulate = Color.WHITE
	root.add_child(label)

	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = INTERACTION_RADIUS
	shape.shape = sphere
	area.add_child(shape)
	root.add_child(area)

	var npc_id: String = data.get("id", "")
	area.body_entered.connect(func(body):
		if body.is_in_group("player"):
			var ui := get_tree().get_first_node_in_group("npc_dialogue_ui")
			if ui and ui.has_method("open_for_npc"):
				ui.open_for_npc(npc_id)
	)
