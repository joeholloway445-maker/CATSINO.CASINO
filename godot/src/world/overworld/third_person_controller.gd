class_name ThirdPersonController
extends CharacterBody3D
## Third-person overworld controller. Movement feel (accel/deaccel constants,
## camera-relative input, sharp-turn handling) adapted from the Godot
## platformer/TPS demos, stripped of their scene-specific animation rigs so
## it runs on a procedurally-built capsule cat with zero imported assets.

signal chunk_changed(coord: Vector2i)

const MAX_SPEED := 6.0
const SPRINT_SPEED := 10.5
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

func _ready() -> void:
	_build_body()
	_build_camera()

func _build_body() -> void:
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
	add_child(_body_mesh)

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
		add_child(ear)

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_cam_yaw -= event.relative.x * MOUSE_SENSITIVITY
		_cam_pitch = clampf(_cam_pitch - event.relative.y * MOUSE_SENSITIVITY, -1.2, 0.4)
		_update_camera_rotation()

func _update_camera_rotation() -> void:
	_spring.rotation = Vector3(_cam_pitch, _cam_yaw, 0.0)

func _physics_process(delta: float) -> void:
	velocity.y -= _gravity * delta

	var input_2d := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var cam_basis := Basis(Vector3.UP, _cam_yaw)
	var dir := (cam_basis * Vector3(input_2d.x, 0.0, input_2d.y)).normalized()

	var target_speed := SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else MAX_SPEED
	var accel := (ACCEL if dir.dot(Vector3(velocity.x, 0, velocity.z)) > 0.0 else DEACCEL)
	if not is_on_floor():
		accel *= AIR_ACCEL_FACTOR

	var flat := Vector3(velocity.x, 0.0, velocity.z)
	flat = flat.move_toward(dir * target_speed, accel * delta)
	velocity.x = flat.x
	velocity.z = flat.z

	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY

	if dir.length() > 0.1 and is_instance_valid(_body_mesh):
		var target_yaw := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 10.0 * delta)
		_spring.rotation = Vector3(_cam_pitch, _cam_yaw - rotation.y, 0.0)

	move_and_slide()

	var coord := DiscoveryManager.world_pos_to_chunk(global_position)
	if coord != _last_chunk:
		_last_chunk = coord
		chunk_changed.emit(coord)

	# Fell through the world — recover to spawn height.
	if global_position.y < -50.0:
		global_position = Vector3(global_position.x, 30.0, global_position.z)
		velocity = Vector3.ZERO
