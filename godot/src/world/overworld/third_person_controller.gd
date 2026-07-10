class_name ThirdPersonController
extends CharacterBody3D
## Third-person overworld controller. Movement feel (accel/deaccel constants,
## camera-relative input, sharp-turn handling) adapted from the Godot
## platformer/TPS demos, stripped of their scene-specific animation rigs so
## it runs on a procedurally-built capsule cat with zero imported assets.

signal chunk_changed(coord: Vector2i)

const MAX_SPEED := 6.0
const SPRINT_SPEED := 10.5
const CROUCH_SPEED := 2.6
const ACCEL := 14.0
const DEACCEL := 14.0
const AIR_ACCEL_FACTOR := 0.5
const JUMP_VELOCITY := 9.0
const CAM_DISTANCE := 5.0
const CAM_HEIGHT := 2.2
const MOUSE_SENSITIVITY := 0.004

var _cam_yaw := 0.0
var _cam_pitch := -0.35
var _last_chunk := Vector2i(2147483647, 2147483647)

@onready var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var _spring: SpringArm3D
var _camera: Camera3D
var _body_mesh: MeshInstance3D
var _visual: Node3D
var _crouched := false

func _ready() -> void:
	_build_body()
	_build_camera()

func _build_body() -> void:
	# All visuals hang off one root so posture changes (crouching) can
	# squash the body without touching the physics capsule.
	_visual = Node3D.new()
	add_child(_visual)
	var real := AssetLibrary.instance("player_cat")
	if real != null:
		_visual.add_child(real)
		var cshape := CollisionShape3D.new()
		var ccap := CapsuleShape3D.new()
		ccap.radius = 0.4
		ccap.height = 1.2
		cshape.shape = ccap
		cshape.position.y = 0.6
		add_child(cshape)
		return
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.2
	shape.shape = capsule
	shape.position.y = 0.6
	add_child(shape)

	_body_mesh = MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.4
	mesh.height = 1.2
	_body_mesh.mesh = mesh
	_body_mesh.position.y = 0.6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.6, 0.25) # tabby orange
	mat.roughness = 0.8
	_body_mesh.material_override = mat
	_visual.add_child(_body_mesh)

	# Ears — two small cones so the capsule reads as a cat from a distance.
	for side in [-1.0, 1.0]:
		var ear := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.12
		cone.height = 0.3
		ear.mesh = cone
		ear.material_override = mat
		ear.position = Vector3(0.18 * side, 1.3, 0.0)
		_visual.add_child(ear)

func _build_camera() -> void:
	_spring = SpringArm3D.new()
	_spring.spring_length = CAM_DISTANCE
	_spring.position.y = CAM_HEIGHT
	_spring.collision_mask = 1
	add_child(_spring)

	_camera = Camera3D.new()
	_camera.current = true
	_spring.add_child(_camera)
	_update_camera_rotation()

const TOUCH_LOOK_SENSITIVITY := 0.006

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not TouchControls.active():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_cam_yaw -= event.relative.x * MOUSE_SENSITIVITY
		_cam_pitch = clampf(_cam_pitch - event.relative.y * MOUSE_SENSITIVITY, -1.2, 0.4)
		_update_camera_rotation()

## Touch look — read once a frame from TouchControls.look_delta, so mobile
## can pan the camera with a right-thumb drag without ever needing mouse
## capture. Consumed here so no other reader competes for the same drag.
func _apply_touch_look() -> void:
	if not TouchControls.active():
		return
	var d := TouchControls.consume_look_delta()
	if d.length_squared() < 1.0:
		return
	_cam_yaw -= d.x * TOUCH_LOOK_SENSITIVITY
	_cam_pitch = clampf(_cam_pitch - d.y * TOUCH_LOOK_SENSITIVITY, -1.2, 0.4)
	_update_camera_rotation()

func _update_camera_rotation() -> void:
	_spring.rotation = Vector3(_cam_pitch, _cam_yaw, 0.0)

func _physics_process(delta: float) -> void:
	_apply_touch_look()
	velocity.y -= _gravity * delta

	var input_2d := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# Touch devices: the virtual joystick overrides/merges with keys.
	if TouchControls.move_vector.length() > 0.05:
		input_2d = TouchControls.move_vector
	var cam_basis := Basis(Vector3.UP, _cam_yaw)
	var dir := (cam_basis * Vector3(input_2d.x, 0.0, input_2d.y)).normalized()

	# Crouch: hold Ctrl/C (or the touch posture button). Slower, lower.
	var want_crouch := Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_C) \
		or TouchControls.crouch_held
	if want_crouch != _crouched:
		_crouched = want_crouch
		if is_instance_valid(_visual):
			var tw := create_tween()
			tw.tween_property(_visual, "scale:y", 0.55 if _crouched else 1.0, 0.12)

	var sprinting := Input.is_key_pressed(KEY_SHIFT) or TouchControls.sprint_held
	var target_speed := SPRINT_SPEED if sprinting else MAX_SPEED
	if _crouched:
		target_speed = CROUCH_SPEED
	var accel := (ACCEL if dir.dot(Vector3(velocity.x, 0, velocity.z)) > 0.0 else DEACCEL)
	if not is_on_floor():
		accel *= AIR_ACCEL_FACTOR

	var flat := Vector3(velocity.x, 0.0, velocity.z)
	flat = flat.move_toward(dir * target_speed, accel * delta)
	velocity.x = flat.x
	velocity.z = flat.z

	if is_on_floor() and not _crouched \
			and (Input.is_action_just_pressed("ui_accept") or TouchControls.consume_jump()):
		velocity.y = JUMP_VELOCITY
	# Touch E: replay as a real key event so every venue/door/hideout
	# interaction hears it without knowing about touch.
	if TouchControls.consume_interact():
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)

	if dir.length() > 0.1 and is_instance_valid(_body_mesh):
		var target_yaw := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 10.0 * delta)
		_spring.rotation = Vector3(_cam_pitch, _cam_yaw - rotation.y, 0.0)

	move_and_slide()

	# Body memory: gait, turns and posture feed Proprioception every frame.
	Proprioception.feed(delta, _cam_yaw,
		Vector2(velocity.x, velocity.z).length(),
		input_2d.y > 0.5, input_2d.y < -0.5,
		_crouched, is_on_floor())

	var coord := DiscoveryManager.world_pos_to_chunk(global_position)
	if coord != _last_chunk:
		_last_chunk = coord
		chunk_changed.emit(coord)

	# Fell through the world — recover to spawn height.
	if global_position.y < -50.0:
		global_position = Vector3(global_position.x, 30.0, global_position.z)
		velocity = Vector3.ZERO
