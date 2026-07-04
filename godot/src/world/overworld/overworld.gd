extends Node3D
## The explorable 3D overworld: procedural terrain + day/night sky + a
## third-person cat. Walking into a chunk you've never generated before
## fires the discover mechanic (influence painting) and advances the
## "Cartographer's Call" quest — same rules as cat_forest_scene's
## explore_chunk(), just driven by actually walking around.

const PLAYER_ID := "local_player"

var _terrain: ProceduralTerrain
var _sky: DayNightSky
var _player: ThirdPersonController

func _ready() -> void:
	_terrain = ProceduralTerrain.new()
	add_child(_terrain)

	_sky = DayNightSky.new()
	IdentityLens.tune_sky(_sky)
	add_child(_sky)

	_player = ThirdPersonController.new()
	add_child(_player)

	# Spawn just outside the Arlington hub bounds so wild chunks are a short
	# walk away, standing on (not inside) the terrain.
	var spawn := Vector3(-40.0, 0.0, -40.0)
	_terrain.stream_around(DiscoveryManager.world_pos_to_chunk(spawn))
	spawn.y = _terrain.height_at(spawn.x, spawn.z) + 2.0
	_player.global_position = spawn

	_player.chunk_changed.connect(_on_player_chunk_changed)
	add_child(SensoriumAmbience.new())
	_build_hud()

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var back := Button.new()
	back.text = "⬅ Menu"
	back.position = Vector2(10, 10)
	back.pressed.connect(func():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	layer.add_child(back)

	var hint := Label.new()
	hint.text = "Click to look • WASD/arrows move • Shift sprint • Space jump • Esc frees mouse"
	hint.position = Vector2(10, 44)
	hint.modulate = Color(1, 1, 1, 0.6)
	layer.add_child(hint)

func _on_player_chunk_changed(coord: Vector2i) -> void:
	_terrain.stream_around(coord)

	var already_known := DiscoveryManager.has_chunk(coord)
	var chunk := DiscoveryManager.get_or_generate_chunk(coord)
	if chunk.is_hub:
		return

	var loadout := CharacterCreatorLogic.build_loadout(
		PlayerProfile.selected_race_id, PlayerProfile.selected_frame)
	var pack := PlayerInfluencePack.from_loadout(PLAYER_ID, loadout, 1)
	DiscoveryManager.register_party_visit(coord, [pack])

	if not already_known:
		QuestManager.update_progress("discover_chunk")
		NotificationUI.notify_info("Discovered %s terrain! 🗺️" % str(chunk.biome.get("biome", "unknown")))
