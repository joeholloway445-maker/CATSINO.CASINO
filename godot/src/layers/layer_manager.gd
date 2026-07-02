extends Node
## Autoloaded as "LayerManager". Tracks which reality layer the player is in,
## enforces entry rules, and runs the Liminal wander timer that pulls players
## into the Periliminal.

signal layer_changed(from_id: String, to_id: String)
signal periliminal_pull_warning(seconds_left: float)
signal pulled_into_periliminal()

const WANDER_PULL_SECONDS := 600.0 # 10 min of liminal wandering
const WANDER_WARN_SECONDS := 120.0 # warn for the last 2 min

var current_layer_id: String = "hyperliminal"
var _liminal_wander := 0.0
var _warned := false

func _process(delta: float) -> void:
	if current_layer_id != "liminal":
		return
	_liminal_wander += delta
	var left := WANDER_PULL_SECONDS - _liminal_wander
	if left <= WANDER_WARN_SECONDS and not _warned:
		_warned = true
		periliminal_pull_warning.emit(left)
		NotificationUI.notify_info("The walls are getting thinner... 👁️")
	if left <= 0.0:
		pulled_into_periliminal.emit()
		transition_to("periliminal", true)

func can_enter(layer_id: String) -> Dictionary:
	var layer := RealityLayers.by_id(layer_id)
	if layer.is_empty():
		return {ok=false, reason="Unknown layer"}
	match str(layer.entry):
		"invite":
			if not SubliminalManager.has_apartment_access():
				return {ok=false, reason="The Subliminal is invite-only."}
		"liminal_wander":
			return {ok=false, reason="The Periliminal cannot be entered. It enters you — wander the Liminal long enough."}
		_:
			pass
	return {ok=true, reason=""}

## `pulled` bypasses entry rules (the Periliminal taking you is not a choice).
func transition_to(layer_id: String, pulled: bool = false) -> bool:
	if not pulled:
		var check := can_enter(layer_id)
		if not check.ok:
			NotificationUI.notify_error(check.reason)
			return false
	var from := current_layer_id
	current_layer_id = layer_id
	if layer_id != "liminal":
		_liminal_wander = 0.0
		_warned = false
	layer_changed.emit(from, layer_id)
	var scene: String = str(RealityLayers.by_id(layer_id).get("scene", ""))
	if scene != "" and ResourceLoader.exists(scene):
		get_tree().change_scene_to_file(scene)
	return true

## PvP rules resolve per-layer; supraliminal defers to TerritoryControl
## (PvE inside hub bounds, PvP everywhere else).
func is_pvp_here(world_pos: Vector3 = Vector3.ZERO) -> bool:
	match current_layer_id:
		"liminal": return true
		"supraliminal": return TerritoryControl.is_pvp_at(world_pos)
		_: return false

func wander_seconds_left() -> float:
	return maxf(WANDER_PULL_SECONDS - _liminal_wander, 0.0)
