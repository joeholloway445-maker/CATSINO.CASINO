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
var _ability_kit: Array[String] = []
var _target_id: String = "target_dummy"

func _ready() -> void:
	add_to_group("player")
	_orientation = global_transform
	_orientation.origin = Vector3.ZERO
	_speed_multiplier = _mobility_multiplier_for_mod(mod_id)
	_spawn_identity()
	_refresh_ability_kit()
	if has_node("/root/PlayerProfile"):
		var profile := get_node("/root/PlayerProfile")
		# PlayerProfile has no dedicated faction-changed signal — set_faction()
		# emits the general profile_updated, so re-resolve the kit on every
		# profile update (cheap: a dictionary filter over 16 entries).
		if profile.has_signal("profile_updated") and not profile.profile_updated.is_connected(_refresh_ability_kit):
			profile.profile_updated.connect(_refresh_ability_kit)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_captured = true

func _refresh_ability_kit() -> void:
	var faction := "Factionless"
	if has_node("/root/PlayerProfile"):
		faction = str(get_node("/root/PlayerProfile").get("faction"))
	if faction == "":
		faction = "Factionless"
	_ability_kit = CombatSystemRealtime.abilities_for_faction(faction)
	if _ability_kit.is_empty():
		_ability_kit = CombatSystemRealtime.abilities_for_faction("Factionless")

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
	# CombatSystemRealtime models position abstractly as Vector2 (range/
	# distance only, not physics) — project our 3D forward-aim point onto
	# the XZ plane rather than changing that system's type and risking the
	# already-shipped combat_ui.gd, which reads it as Vector2 throughout.
	var aim_point := global_transform.origin + (-global_transform.basis.z * 3.0)
	var target_pos_2d := Vector2(aim_point.x, aim_point.z)
	combat.player_positions[actor_id] = Vector2(global_transform.origin.x, global_transform.origin.z)
	combat.use_ability(actor_id, ability_id, _target_id, target_pos_2d)

func _ability_id_for_slot(slot: int) -> String:
	# Slots are 1-indexed to match the input map (ability_1..ability_8) and
	# the hotbar UI; kits currently have 4 abilities (Factionless has 4,
	# each named faction has 4), so slots 5-8 are empty until multi-kit
	# loadouts (companion abilities, unlocked skills) land.
	var index := slot - 1
	if index < 0 or index >= _ability_kit.size():
		return ""
	return _ability_kit[index]

## Set by whatever spawns/targets this controller in a real encounter
## (combat trigger volume, lock-on system). Defaults to a placeholder id
## so ability presses don't silently no-op in the playtest arena.
func set_target(target_id: String) -> void:
	_target_id = target_id if target_id != "" else "target_dummy"

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
