extends Node

# ── Signals ────────────────────────────────────────────────────────────────────
signal district_transition_started(from: District, to: District)
signal district_loading_progress(progress: float)
signal district_loaded(district: District)
signal player_count_updated(district: District, count: int)

# ── Enums ──────────────────────────────────────────────────────────────────────
enum District {
	PAW_VEGAS,       # Casino hub
	NEON_ALLEY,      # Racing district
	CAT_COLISEUM,    # Sports arena
	ARCADE_GALAXY,   # Mini-game hub
	CAT_FOREST,      # Adventure zone
}

# ── Constants ──────────────────────────────────────────────────────────────────
const DISTRICT_SCENES: Dictionary = {
	District.PAW_VEGAS:     "res://scenes/world/paw_vegas_hub.tscn",
	District.NEON_ALLEY:    "res://scenes/world/neon_alley.tscn",
	District.CAT_COLISEUM:  "res://scenes/world/cat_coliseum.tscn",
	District.ARCADE_GALAXY: "res://scenes/world/arcade_galaxy.tscn",
	District.CAT_FOREST:    "res://scenes/world/cat_forest.tscn",
}

const DISTRICT_MUSIC: Dictionary = {
	District.PAW_VEGAS:     "res://assets/audio/music/paw_vegas_theme.ogg",
	District.NEON_ALLEY:    "res://assets/audio/music/neon_alley_theme.ogg",
	District.CAT_COLISEUM:  "res://assets/audio/music/coliseum_theme.ogg",
	District.ARCADE_GALAXY: "res://assets/audio/music/arcade_galaxy_theme.ogg",
	District.CAT_FOREST:    "res://assets/audio/music/cat_forest_theme.ogg",
}

const MAX_PLAYERS_PER_DISTRICT := 200

# ── State ──────────────────────────────────────────────────────────────────────
var current_district: District = District.PAW_VEGAS
var _current_scene_node: Node  = null
var _is_transitioning: bool    = false
var _player_counts: Dictionary = {
	District.PAW_VEGAS:     0,
	District.NEON_ALLEY:    0,
	District.CAT_COLISEUM:  0,
	District.ARCADE_GALAXY: 0,
	District.CAT_FOREST:    0,
}

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	pass

func initialize() -> void:
	_poll_player_counts()

# ── Public API ─────────────────────────────────────────────────────────────────
func get_current_district() -> District:
	return current_district

func get_district_name(district: District) -> String:
	return District.keys()[district].replace("_", " ").capitalize()

func get_player_count(district: District) -> int:
	return _player_counts.get(district, 0)

func is_district_full(district: District) -> bool:
	return _player_counts.get(district, 0) >= MAX_PLAYERS_PER_DISTRICT

func transition_to_district(district: District) -> void:
	if _is_transitioning:
		push_warning("DistrictManager: transition already in progress")
		return
	if district == current_district:
		return
	_is_transitioning = true
	var from := current_district
	emit_signal("district_transition_started", from, district)

	# Fade out (signal for UI to handle)
	emit_signal("district_loading_progress", 0.0)

	# Unload old scene
	if _current_scene_node and is_instance_valid(_current_scene_node):
		_current_scene_node.queue_free()
		_current_scene_node = null
	await get_tree().process_frame
	emit_signal("district_loading_progress", 0.25)

	# Load new scene
	var scene_path: String = DISTRICT_SCENES.get(district, "")
	if scene_path and ResourceLoader.exists(scene_path):
		var loader := ResourceLoader.load_threaded_request(scene_path)
		var progress := []
		while true:
			var status := ResourceLoader.load_threaded_get_status(scene_path, progress)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				break
			elif status == ResourceLoader.THREAD_LOAD_FAILED:
				push_error("DistrictManager: failed to load %s" % scene_path)
				break
			emit_signal("district_loading_progress", 0.25 + progress[0] * 0.60)
			await get_tree().process_frame
		var scene := ResourceLoader.load_threaded_get(scene_path) as PackedScene
		if scene:
			_current_scene_node = scene.instantiate()
			get_tree().current_scene.add_child(_current_scene_node)
	else:
		# Placeholder — district scene not yet created
		push_warning("DistrictManager: no scene for %s" % District.keys()[district])

	emit_signal("district_loading_progress", 0.90)
	current_district = district
	_is_transitioning = false
	emit_signal("district_loading_progress", 1.0)
	emit_signal("district_loaded", district)
	_fire_visit_quest_triggers(district)

## Advances both quest systems on arrival: the JSON quests' generic
## "visit_district" trigger, the built-in per-district objectives, and
## side_004's visit-all-districts counter (once per unique district).
var _visited_districts: Dictionary = {}

func _fire_visit_quest_triggers(district: District) -> void:
	QuestManager.update_progress("visit_district")
	match district:
		District.CAT_COLISEUM:  QuestManager.update_progress("visit_coliseum")
		District.ARCADE_GALAXY: QuestManager.update_progress("visit_arcade")
		District.NEON_ALLEY:    QuestManager.update_progress("visit_neon")
		District.CAT_FOREST:    QuestManager.update_progress("visit_forest")
		_: pass
	if not _visited_districts.has(district):
		_visited_districts[district] = true
		QuestManager.update_progress("visit_all_5")

# ── Private ────────────────────────────────────────────────────────────────────
func _poll_player_counts() -> void:
	# In a real implementation, query Nakama match presence
	# For now, simulate with random counts
	for district in _player_counts:
		_player_counts[district] = randi() % 150
		emit_signal("player_count_updated", district, _player_counts[district])

func update_player_count(district: District, count: int) -> void:
	_player_counts[district] = count
	emit_signal("player_count_updated", district, count)
