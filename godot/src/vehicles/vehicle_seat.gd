class_name VehicleSeat
extends RefCounted
## Shared enter/exit/camera-handoff logic used by all four vehicle types
## (LandVehicle, WaterVehicle, AirVehicle, SpaceVehicle). Not a node —
## a small helper composed into each vehicle via `var seat := VehicleSeat.new(self)`
## so the physics classes (VehicleBody3D vs RigidBody3D, different base
## types) don't need a shared inheritance chain.
##
## Interaction key follows the existing convention: doors/venues have no
## dedicated "interact" input action, they listen for raw KEY_E (see
## ThirdPersonController's TouchControls.consume_interact() -> replays
## KEY_E) — vehicles do the same so touch users get it for free.

## Must match ThirdPersonController's on-foot id (see overworld.gd/
## layer_world.gd's PLAYER_ID) so a player's world-discovery influence
## accumulates under one identity whether they're walking, driving,
## sailing, flying, or in space — not fragmented into separate trails.
const PLAYER_ID := "local_player"

## Same signature/purpose as ThirdPersonController.chunk_changed — lets
## layer_world.gd/overworld.gd drive terrain streaming (and bump the view
## radius/fog distance while piloting) from a vehicle exactly the way they
## already do for the on-foot controller.
signal chunk_changed(coord: Vector2i)
## Fired on successful enter/exit — world scripts use this to bump the
## streaming view radius + fog distance while a vehicle is piloted
## (covers ground faster than walking) and restore it on exit.
signal entered
signal exited

var owner_node: Node3D
var driver: Node3D = null
var nearby_player: Node3D = null
var _camera: Camera3D
var _last_chunk := Vector2i(2147483647, 2147483647)

func _init(owner: Node3D, camera: Camera3D) -> void:
	owner_node = owner
	_camera = camera

func on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		nearby_player = body

func on_body_exited(body: Node) -> void:
	if body == nearby_player:
		nearby_player = null

func try_toggle(event: InputEvent) -> bool:
	if not (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E):
		return false
	if driver == null:
		return _enter()
	else:
		_exit()
		return true

func _enter() -> bool:
	if nearby_player == null or driver != null:
		return false
	driver = nearby_player
	if driver.has_method("set_physics_process"):
		driver.set_physics_process(false)
	driver.set_process_unhandled_input(false)
	driver.visible = false
	_camera.current = true
	# Clear residual touch so boarding doesn't inherit a death-spiral stick.
	TouchControls.move_vector = Vector2.ZERO
	TouchControls.jump_held = false
	TouchControls.sprint_held = false
	TouchControls.roll_left_held = false
	TouchControls.roll_right_held = false
	TouchControls.look_delta = Vector2.ZERO
	if owner_node is RigidBody3D:
		var rb := owner_node as RigidBody3D
		rb.linear_velocity = Vector3.ZERO
		rb.angular_velocity = Vector3.ZERO
	entered.emit()
	NotificationUI.notify_info("Boarded — stick = fly, JUMP↑ SPRINT↓, E to exit.")
	return true

func _exit() -> void:
	if driver == null:
		return
	var exit_pos := owner_node.global_transform.origin + owner_node.global_transform.basis.x * 2.5
	exit_pos.y = owner_node.global_transform.origin.y
	driver.global_position = exit_pos
	driver.visible = true
	if driver.has_method("set_physics_process"):
		driver.set_physics_process(true)
	driver.set_process_unhandled_input(true)
	if driver.has_method("get_camera"):
		var cam: Camera3D = driver.get_camera()
		if cam != null:
			cam.current = true
	driver = null
	exited.emit()

## Call every physics frame while occupied (land/water/air/space alike) so
## piloted traversal keeps contributing to world discovery and each
## player's influence trace exactly like walking does — before this, the
## on-foot controller's chunk-tracking was disabled the moment a player
## boarded any vehicle (its whole _physics_process stops, see _enter()
## above), silently freezing discovery/influence for the entire trip.
## Reuses the exact same DiscoveryManager/PlayerInfluencePack/
## CharacterCreatorLogic pipeline overworld.gd's on-foot path already
## uses, on the SAME chunk grid (XZ cell) regardless of altitude — a
## chunk you fly over at 500m and one you walk through are the same
## record, not separate ones per vehicle type.
func update_world_discovery() -> void:
	if driver == null:
		return
	var coord := DiscoveryManager.world_pos_to_chunk(owner_node.global_position)
	if coord == _last_chunk:
		return
	_last_chunk = coord
	chunk_changed.emit(coord)

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

## ── Shared control-axis reading (keyboard + touch merged) ─────────────
## Every vehicle reads these instead of raw Input.get_action_strength(),
## so mobile works identically across land/water/air/space without each
## script re-implementing the merge (and risking drift/bugs between them).
## Mirrors the override pattern ThirdPersonController already uses for its
## own on-foot joystick: touch overrides keyboard once its stick exceeds a
## small deadzone, rather than blending both (avoids double-input jitter
## if a touch device also has a keyboard attached).

## Forward(+)/back(-). Touch: joystick pushed up = forward (screen Y-down
## convention, matching Input.get_vector's own up/down sign).
static func throttle_axis() -> float:
	if absf(TouchControls.move_vector.y) > 0.05:
		return clampf(-TouchControls.move_vector.y, -1.0, 1.0)
	return Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")

## Left(+)/right(-) turn/steer/roll-bank input.
static func turn_axis() -> float:
	if absf(TouchControls.move_vector.x) > 0.05:
		return clampf(-TouchControls.move_vector.x, -1.0, 1.0)
	return Input.get_action_strength("move_left") - Input.get_action_strength("move_right")

## Up(+)/down(-) vertical thrust (air/space ascend-descend). Touch reuses
## the jump/sprint buttons' HELD state (not the one-shot jump queue, which
## is on-foot-only) — see TouchControls.jump_held / sprint_held.
static func vertical_axis() -> float:
	var touch := (1.0 if TouchControls.jump_held else 0.0) - (1.0 if TouchControls.sprint_held else 0.0)
	if touch != 0.0:
		return touch
	return Input.get_action_strength("jump") - Input.get_action_strength("sprint")

## Right(+)/left(-) roll — space vehicles only.
static func roll_axis() -> float:
	var touch := (1.0 if TouchControls.roll_right_held else 0.0) - (1.0 if TouchControls.roll_left_held else 0.0)
	if touch != 0.0:
		return touch
	return Input.get_action_strength("roll_right") - Input.get_action_strength("roll_left")
