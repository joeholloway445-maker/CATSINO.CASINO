extends Node
## Autoloaded as "GameModeManager". Tracks which purchasable game modes
## (GameModeData) the player owns and which one is currently active.
## Ownership here is a placeholder boolean set — wiring this to a real store/
## entitlement check is a separate task once a storefront exists.

signal active_mode_changed(mode_id: String)

const GameModeData = preload("res://src/data/game_mode_data.gd")

var owned_mode_ids: Array[String] = ["persistent_aware"] # free by default
var active_mode_id: String = "persistent_aware"

func owns(mode_id: String) -> bool:
	return owned_mode_ids.has(mode_id)

func grant(mode_id: String) -> void:
	if not GameModeData.by_id(mode_id).is_empty() and not owns(mode_id):
		owned_mode_ids.append(mode_id)

func set_active(mode_id: String) -> bool:
	if not owns(mode_id):
		push_warning("Cannot activate '%s' — not owned." % mode_id)
		return false
	active_mode_id = mode_id
	active_mode_changed.emit(mode_id)
	return true

func active_mode() -> Dictionary:
	return GameModeData.by_id(active_mode_id)

func is_aware() -> bool:
	return active_mode().get("npc_awareness", "aware") == "aware"

func is_sandboxed() -> bool:
	return active_mode().get("sandboxed", false)
