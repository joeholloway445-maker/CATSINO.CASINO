extends Node3D
## Shared scene script for the explorable layers. Reuses the overworld kit
## (ProceduralTerrain + DayNightSky + ThirdPersonController) with per-layer
## rules from RealityLayers. One script, five moods:
##  - supraliminal: persistent chunks (DiscoveryManager), hubs PvE, wilds PvP
##  - liminal: NEVER static — chunks dissolve behind you; wander timer runs
##  - periliminal: generated-then-static from the run's recorded seed
##  - extraliminal/subliminal get placeholder grounds until their bespoke
##    scenes land (landmark overlay / apartment interior).

@export var layer_id: String = "supraliminal"

var _terrain: ProceduralTerrain
var _sky: DayNightSky
var _player: ThirdPersonController

func _ready() -> void:
	LayerManager.current_layer_id = layer_id

	_terrain = ProceduralTerrain.new()
	add_child(_terrain)

	_sky = DayNightSky.new()
	match layer_id:
		"liminal":
			_sky.day_length_seconds = 90.0 # time slides wrong here
		"periliminal":
			_sky.day_length_seconds = 999999.0
			_sky.start_hour = 3.0 # permanent dead-of-night
	IdentityLens.tune_sky(_sky)
	add_child(_sky)

	_player = ThirdPersonController.new()
	add_child(_player)

	var spawn := _spawn_point()
	_terrain.stream_around(DiscoveryManager.world_pos_to_chunk(spawn))
	spawn.y = _terrain.height_at(spawn.x, spawn.z) + 2.0
	_player.global_position = spawn
	_player.chunk_changed.connect(_on_chunk_changed)
	_build_hud()

func _spawn_point() -> Vector3:
	match layer_id:
		"supraliminal":
			# Factionless start in Arlington's center; faction players in
			# their own hub (Dallas/Fort Worth/Denton).
			var hub_id := {
				"SovereignCrown": "dallas",
				"VeiledCurrent": "fort_worth",
				"WildlandsAscendant": "denton",
			}.get(PlayerProfile.faction, "arlington")
			var hub := HubRegionData.by_id(hub_id)
			var b: Dictionary = hub["chunk_bounds"]
			var size := float(HubRegionData.CHUNK_SIZE)
			return Vector3((b.x + b.w / 2.0) * size, 0, (b.y + b.h / 2.0) * size)
		_:
			return Vector3.ZERO

const HubRegionData = preload("res://src/data/hub_region_data.gd")

var _prev_chunk := Vector2i(2147483647, 0)

func _on_chunk_changed(coord: Vector2i) -> void:
	_terrain.stream_around(coord)
	match layer_id:
		"supraliminal":
			_supraliminal_enter(coord)
		"liminal":
			_liminal_enter(coord)
		"periliminal":
			PeriliminalRuns.advance_depth()
	_prev_chunk = coord

func _supraliminal_enter(coord: Vector2i) -> void:
	var already_known := DiscoveryManager.has_chunk(coord)
	var chunk := DiscoveryManager.get_or_generate_chunk(coord)
	if chunk.is_hub:
		NotificationUI.notify_info("Entering %s — PvE sanctuary." % chunk.hub_id.capitalize())
		return
	var loadout := CharacterCreatorLogic.build_loadout(
		PlayerProfile.selected_race_id, PlayerProfile.selected_frame)
	var pack := PlayerInfluencePack.from_loadout("local_player", loadout, 1)
	DiscoveryManager.register_party_visit(coord, [pack])
	if not already_known:
		QuestManager.update_progress("discover_chunk")
		CrownManager.add_score("Top Terrain Explored", "local_player", 1)
	var owner := TerritoryControl.claim_owner(coord)
	if owner != "" and owner != PlayerProfile.faction:
		NotificationUI.notify_info("⚔️ %s territory — you are fair game here." % owner)

func _liminal_enter(coord: Vector2i) -> void:
	# Never static: the chunk you just left stops existing. Erase its
	# record so re-entering regenerates it differently (fresh prop seed
	# via a new WorldChunk), and harvest a little essence for the risk.
	if DiscoveryManager.has_chunk(_prev_chunk) and _prev_chunk != coord:
		DiscoveryManager._chunks.erase(_prev_chunk)
	EconomyManager.earn_currency("fragments", 1, "liminal_wandering")

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var back := Button.new()
	back.text = "⬅ Catsino"
	back.position = Vector2(10, 10)
	back.pressed.connect(func():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		LayerManager.transition_to("hyperliminal"))
	layer.add_child(back)

	var name_lbl := Label.new()
	name_lbl.text = RealityLayers.by_id(layer_id).get("name", layer_id)
	name_lbl.position = Vector2(10, 44)
	name_lbl.modulate = Color(1, 1, 1, 0.7)
	layer.add_child(name_lbl)

	if layer_id == "liminal":
		var timer_lbl := Label.new()
		timer_lbl.name = "WanderTimer"
		timer_lbl.position = Vector2(10, 68)
		timer_lbl.modulate = Color(0.8, 0.6, 1.0)
		layer.add_child(timer_lbl)

func _process(_delta: float) -> void:
	if layer_id == "liminal":
		var lbl: Label = get_node_or_null("CanvasLayer/WanderTimer")
		if lbl == null:
			for child in get_children():
				if child is CanvasLayer:
					lbl = child.get_node_or_null("WanderTimer")
		if lbl:
			lbl.text = "The Periliminal notices you in %d s" % int(LayerManager.wander_seconds_left())
