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

var owner_node: Node3D
var driver: Node3D = null
var nearby_player: Node3D = null
var _camera: Camera3D

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
