extends Node3D
## Shared behavior for every reality-layer / district scene: shows the
## layer name/description, provides a way back to the hub, and — if
## portal_world_ids is set — spawns one navigation button per listed
## WorldRegistry entry (used by hub scenes like Arlington and the Space
## Station to link out to sub-districts and gated worlds in-lore).

@export var world_id: String = ""
@export var portal_world_ids: Array[String] = []
@export var back_target: String = "res://hdv_lore/scenes/worlds/world_select.tscn"

@onready var title_label: Label = $UI/Title
@onready var desc_label: Label = $UI/Description
@onready var ui: CanvasLayer = $UI

func _ready() -> void:
	var world := WorldRegistry.by_id(world_id)
	if world.is_empty():
		return
	title_label.text = world.get("name", world_id)
	desc_label.text = world.get("description", "")
	if world_id == "supraliminal_spire":
		_discover_spawn_chunk()
	if not portal_world_ids.is_empty():
		_build_portals()

## Lays out one button per portal_world_ids entry beneath the back button,
## respecting age-verification gating and external (not-yet-built) worlds
## the same way world_select.gd does for the top-level world list.
func _build_portals() -> void:
	var y := 190.0
	for portal_id in portal_world_ids:
		var world := WorldRegistry.by_id(portal_id)
		if world.is_empty():
			continue
		var button := Button.new()
		var label := world.get("name", portal_id)
		if world.get("requires_age_verification", false):
			label += " [18+]"
		button.text = label
		button.offset_left = 30.0
		button.offset_right = 260.0
		button.offset_top = y
		button.offset_bottom = y + 35.0
		button.pressed.connect(_on_portal_pressed.bind(portal_id))
		ui.add_child(button)
		y += 45.0

func _on_portal_pressed(portal_id: String) -> void:
	var world := WorldRegistry.by_id(portal_id)
	if world.is_empty():
		return
	if world.get("requires_age_verification", false) and not GameData.age_verified:
		push_warning("'%s' requires age verification — not yet wired up here." % world["name"])
		return
	if world.get("external", false):
		var repo: String = world.get("external_repo", "")
		if not ExternalGameLauncher.launch(repo, "local_player", world_id):
			push_warning("'%s' lives in an external project (%s) — launch it separately for now." % [world["name"], repo])
		return
	if world.get("scene_path", "") != "" and ResourceLoader.exists(world["scene_path"]):
		get_tree().change_scene_to_file(world["scene_path"])
	else:
		push_warning("'%s' has no scene built yet." % world["name"])

## Demo wiring for the discover mechanic: the lone local player "discovers"
## whatever chunk they spawn into. Real parties will call
## DiscoveryManager.register_party_visit() with every member's pack as they
## move between chunks.
func _discover_spawn_chunk() -> void:
	var coord := DiscoveryManager.world_pos_to_chunk(global_position)
	var pack := GameData.build_influence_pack("local_player")
	DiscoveryManager.register_party_visit(coord, [pack])
	var chunk := DiscoveryManager.get_or_generate_chunk(coord)
	if chunk.is_hub:
		desc_label.text += "\n[Hub: %s]" % chunk.hub_id
	else:
		desc_label.text += "\n[Wild chunk %s — biome: %s]" % [coord, chunk.biome.get("biome", "?")]

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(back_target)
