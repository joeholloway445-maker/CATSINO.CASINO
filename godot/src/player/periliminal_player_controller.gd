class_name PeriliminalPlayerController
extends CharacterBody3D
## The real, playable movement/camera baseline for Periliminal.Space —
## camera-relative motion + jump + gravity physics, adapted from the
## proven pattern in godotengine/tps-demo's player.gd (CC-BY 3.0,
## Juan Linietsky / Fernando Miguel Calabró — see
## godot/assets/models/ATTRIBUTION.md), rewritten single-player-first
## and stripped of the demo's gun-robot multiplayer/shooting scaffolding.
##
## Visual identity (race/frame/mod) comes from CharacterRig. Movement feel
## (speed/jump) is scaled by the equipped mod's body plan
## (MorphRigData bonus/drawback — e.g. Swiftburner: +Acceleration).
## Actions 1-8 call straight into CombatSystemRealtime, matching the
## ability hotbar already wired in the combat/HUD UI.

const BASE_SPEED := 5.0
const SPRINT_MULTIPLIER := 1.6
const JUMP_SPEED := 5.0
const ROTATION_INTERPOLATE_SPEED := 10.0
const MOTION_INTERPOLATE_SPEED := 10.0
const MIN_AIRBORNE_TIME := 0.1
const MOUSE_SENSITIVITY := 0.003
const CAMERA_PITCH_MIN := deg_to_rad(-80.0)
const CAMERA_PITCH_MAX := deg_to_rad(70.0)

@export var actor_id: String = "player"
@export var race_id: String = "tabby"
@export var frame_id: String = "skirmisher"
@export var mod_id: String = "centroid"

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var rig: CharacterRig = $CharacterRig

var _motion := Vector2.ZERO
var _orientation := Transform3D()
var _airborne_time := 100.0
var _speed_multiplier := 1.0
var _mouse_captured := false

func _ready() -> void:
	_orientation = global_transform
	_orientation.origin = Vector3.ZERO
	_speed_multiplier = _mobility_multiplier_for_mod(mod_id)
	_spawn_identity()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_captured = true

func _spawn_identity() -> void:
	if rig == null:
		return
	var race := RaceDataCharacter.get_race(race_id)
	var frame := OmniDexRegistry.frame_by_id(frame_id)
	var mod := MorphRigData.by_id(mod_id)
	rig.build_from_loadout(race, frame, mod)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_mouse_captured = true
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_mouse_captured = false

	if _mouse_captured and event is InputEventMouseMotion:
		camera_pivot.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		spring_arm.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, CAMERA_PITCH_MIN, CAMERA_PITCH_MAX)

	for i in range(1, 9):
		if event.is_action_pressed("ability_%d" % i):
			_use_ability_slot(i)

func _physics_process(delta: float) -> void:
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	_motion = _motion.lerp(input_dir.limit_length(1.0), MOTION_INTERPOLATE_SPEED * delta)

	var cam_basis := camera_pivot.global_transform.basis
	var cam_z := cam_basis.z
	cam_z.y = 0.0
	cam_z = cam_z.normalized()
	var cam_x := cam_basis.x
	cam_x.y = 0.0
	cam_x = cam_x.normalized()

	_airborne_time += delta
	if is_on_floor():
		_airborne_time = 0.0
	var on_air := _airborne_time > MIN_AIRBORNE_TIME

	if not on_air and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_SPEED
		_airborne_time = MIN_AIRBORNE_TIME

	var target := cam_x * _motion.x + cam_z * _motion.y
	if target.length() > 0.001:
		var q_from := _orientation.basis.get_rotation_quaternion()
		var q_to := Basis.looking_at(target).get_rotation_quaternion()
		_orientation.basis = Basis(q_from.slerp(q_to, delta * ROTATION_INTERPOLATE_SPEED))

	var sprinting := Input.is_action_pressed("sprint")
	var speed := BASE_SPEED * _speed_multiplier * (SPRINT_MULTIPLIER if sprinting else 1.0)
	var h_velocity := target * speed

	velocity.x = h_velocity.x
	velocity.z = h_velocity.z
	velocity += get_gravity() * delta
	move_and_slide()

	if rig != null:
		rig.global_transform.basis = _orientation.basis

	if global_transform.origin.y < -40.0:
		global_transform.origin = Vector3.ZERO
		velocity = Vector3.ZERO

func _use_ability_slot(slot: int) -> void:
	var combat := get_node_or_null("/root/CombatRealtime")
	if combat == null:
		return
	var ability_id := _ability_id_for_slot(slot)
	if ability_id == "":
		return
	var target_pos := global_transform.origin + (-global_transform.basis.z * 3.0)
	combat.use_ability(actor_id, ability_id, "target", target_pos)

func _ability_id_for_slot(slot: int) -> String:
	# TODO(kit): resolve from the player's actual faction ability kit
	# (FactionSystem.get_player_faction() -> CombatRealtime.ABILITY_DATABASE)
	# once inventory/loadout persistence lands; slot mapping stays stable.
	return ""

func _mobility_multiplier_for_mod(id: String) -> float:
	var rig_data := MorphRigData.by_id(id)
	if rig_data.is_empty():
		return 1.0
	var bonus := str(rig_data.get("bonus", ""))
	var drawback := str(rig_data.get("drawback", ""))
	var mult := 1.0
	if "Acceleration" in bonus or "Sprint Speed" in bonus or "Momentum" in bonus:
		mult += 0.2
	if "Momentum" in drawback or "Traction" in drawback:
		mult -= 0.2
	return clampf(mult, 0.6, 1.4)

func apply_loadout(new_race_id: String, new_frame_id: String, new_mod_id: String) -> void:
	race_id = new_race_id
	frame_id = new_frame_id
	mod_id = new_mod_id
	_speed_multiplier = _mobility_multiplier_for_mod(mod_id)
	_spawn_identity()
