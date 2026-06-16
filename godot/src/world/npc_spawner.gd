class_name NPCSpawner
extends Node3D

@export var district: String = "paw_vegas"

var _dialogue_ui: NPCDialogueUI

func _ready() -> void:
	_spawn_npcs()
	_dialogue_ui = preload("res://scenes/ui/npc_dialogue.tscn").instantiate()
	get_tree().current_scene.add_child(_dialogue_ui)
	_dialogue_ui.quest_accepted.connect(_on_quest_accepted)

func _spawn_npcs() -> void:
	var npcs := NPCData.get_npcs_in_district(district)
	for npc_data in npcs:
		var marker := Node3D.new()
		marker.position = npc_data.get("pos", Vector3.ZERO)
		marker.name = npc_data.get("id", "npc")
		marker.set_meta("npc_id", npc_data.get("id", ""))
		add_child(marker)
		_add_interaction_area(marker, npc_data)

func _add_interaction_area(parent: Node3D, npc_data: Dictionary) -> void:
	var label := Label3D.new()
	label.text = npc_data.get("name", "NPC")
	label.position = Vector3(0, 1.8, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)

	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.5
	shape.shape = sphere
	area.add_child(shape)
	area.body_entered.connect(func(body): _on_player_near(body, npc_data.get("id", "")))
	parent.add_child(area)

func _on_player_near(body: Node3D, npc_id: String) -> void:
	if body.is_in_group("player"):
		_dialogue_ui.show_npc(npc_id)

func _on_quest_accepted(quest_id: String) -> void:
	if QuestManager.has_method("accept_quest"):
		QuestManager.accept_quest(quest_id)
	NotificationUI.notify_win("Quest accepted: %s" % quest_id.replace("_", " ").capitalize())
