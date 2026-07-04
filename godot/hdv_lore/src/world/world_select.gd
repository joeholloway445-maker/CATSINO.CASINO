extends Control
## Boots the multiverse hub UI: lists worlds accessible to the current player
## (respecting age-verification gating) and lets them pick one to enter.

@onready var world_list: ItemList = $WorldList

func _ready() -> void:
	_populate_world_list()

func _populate_world_list() -> void:
	world_list.clear()
	var worlds := WorldRegistry.accessible_worlds(GameData.age_verified)
	for world in worlds:
		var label := "%s (%s)" % [world["name"], world["reality_layer"]]
		if world["requires_age_verification"]:
			label += " [18+]"
		world_list.add_item(label)

func _on_world_list_item_activated(index: int) -> void:
	var worlds := WorldRegistry.accessible_worlds(GameData.age_verified)
	var world: Dictionary = worlds[index]
	if world["external"]:
		var repo: String = world.get("external_repo", "")
		if not ExternalGameLauncher.launch(repo, "local_player", world["id"]):
			push_warning("World '%s' lives in an external project (%s) — launch it separately for now." % [world["name"], repo])
		return
	if world["scene_path"] != "" and ResourceLoader.exists(world["scene_path"]):
		get_tree().change_scene_to_file(world["scene_path"])
	else:
		push_warning("World '%s' has no scene built yet." % world["name"])

func _on_game_modes_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/game_mode_store.tscn")

func _on_character_creator_pressed() -> void:
	get_tree().change_scene_to_file("res://hdv_lore/scenes/ui/character_creator.tscn")
