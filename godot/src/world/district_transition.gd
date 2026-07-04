extends Node
class_name DistrictTransition
# Handles moving the player between the 5 world districts

signal transition_started(from_district: String, to_district: String)
signal transition_finished(district: String)

const DISTRICT_SCENES = {
	"paw_vegas":     "res://scenes/world/main.tscn",
	"cat_coliseum":  "res://scenes/world/cat_coliseum.tscn",
	"neon_alley":    "res://scenes/world/neon_alley.tscn",
	"cat_forest":    "res://scenes/world/cat_forest.tscn",
	"arcade_galaxy": "res://scenes/world/arcade_galaxy.tscn",
}

const DISTRICT_NAMES = {
	"paw_vegas":     "Paw Vegas 🎰",
	"cat_coliseum":  "Cat Coliseum ⚔️",
	"neon_alley":    "Neon Alley 🏁",
	"cat_forest":    "Cat Forest 🌿",
	"arcade_galaxy": "Arcade Galaxy 👾",
}

const ENTRY_COSTS = {
	"paw_vegas":     0,
	"cat_coliseum":  0,
	"neon_alley":    0,
	"cat_forest":    0,
	"arcade_galaxy": 0,
}

var _current_district: String = "paw_vegas"
var _transitioning: bool = false

func get_current_district() -> String:
	return _current_district

func get_district_name(district_id: String) -> String:
	return DISTRICT_NAMES.get(district_id, district_id)

func can_enter(district_id: String) -> bool:
	if district_id not in DISTRICT_SCENES: return false
	var cost = ENTRY_COSTS.get(district_id, 0)
	if cost > 0 and EconomyManager:
		return EconomyManager.get_coins() >= cost
	return true

func travel_to(district_id: String) -> void:
	if _transitioning or district_id == _current_district: return
	if not can_enter(district_id):
		push_warning("Cannot enter district: " + district_id)
		return

	var cost = ENTRY_COSTS.get(district_id, 0)
	if cost > 0 and EconomyManager:
		EconomyManager.spend_coins(cost)

	_transitioning = true
	var from = _current_district
	transition_started.emit(from, district_id)

	# Fade out, load scene, fade in
	if HUD:
		HUD.show_event_banner("Traveling to %s..." % get_district_name(district_id), 2.0)

	await get_tree().create_timer(0.5).timeout

	var scene_path = DISTRICT_SCENES[district_id]
	get_tree().change_scene_to_file(scene_path)
	_current_district = district_id
	_transitioning = false
	transition_finished.emit(district_id)

	if HUD:
		HUD.set_district(get_district_name(district_id))

	if AchievementManager:
		AchievementManager.check("visit_district", 1)
