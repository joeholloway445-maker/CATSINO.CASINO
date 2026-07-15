extends Node
## Autoloaded as "LayerManager". Tracks which reality layer the player is in,
## enforces entry rules, and runs the Liminal wander timer that pulls players
## into the Periliminal.

signal layer_changed(from_id: String, to_id: String)
signal pulled_into_periliminal()

## No fixed threshold and no warning, on purpose: the whole point of the
## Periliminal is that you never know until it's too late. Consistency is
## what it rewards — not morality, race, gender, frame, mod, creed, or
## age — so the roll is per-visit and identical for everyone regardless
## of who they are; only HOW LONG you keep wandering the Liminal matters.
const WANDER_MIN_SECONDS := 420.0  # 7 min
const WANDER_MAX_SECONDS := 900.0  # 15 min
## Prototype / headless smoke only — NEVER used in shipped play unless
## `enable_prototype_mode()` is called explicitly (dev smoke + F5 playtest).
const PROTOTYPE_PULL_SECONDS := 8.0

var current_layer_id: String = "hyperliminal"
var _liminal_wander := 0.0
var _pull_threshold := 0.0
var _prototype_mode := false

func is_prototype_mode() -> bool:
	return _prototype_mode

## Shortens the Liminal→Periliminal pull and guarantees a Metroplex exit
## near spawn so the layer spine can be walked in one sitting. No UI labels
## about the pull (design invariant). Call from smoke scripts / title
## "Play Prototype" only.
func enable_prototype_mode(enabled: bool = true) -> void:
	_prototype_mode = enabled
	if enabled and current_layer_id == "liminal":
		_pull_threshold = PROTOTYPE_PULL_SECONDS
		_liminal_wander = 0.0

func pull_threshold() -> float:
	return _pull_threshold

func liminal_wander() -> float:
	return _liminal_wander

func _process(delta: float) -> void:
	if current_layer_id != "liminal":
		return
	# Currentborn (Veiled Current passive): the between tolerates you longer.
	var rate := 0.75 if PlayerProfile.faction == "VeiledCurrent" else 1.0
	_liminal_wander += delta * rate
	if _liminal_wander >= _pull_threshold:
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
	if layer_id == "liminal":
		# Re-rolled every time you step in — a fresh, unknowable threshold
		# each visit, same distribution for every player alive.
		_liminal_wander = 0.0
		if _prototype_mode:
			_pull_threshold = PROTOTYPE_PULL_SECONDS
		else:
			_pull_threshold = randf_range(WANDER_MIN_SECONDS, WANDER_MAX_SECONDS)
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
