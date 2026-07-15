class_name AirVehicle
extends RigidBody3D
## Arcade flight model — thrust + speed-proportional lift + drag + banked
## turns (roll induces yaw, like Star Fox-style flight, not a full 6DOF
## attitude sim). Godot has no built-in flight physics node, so this is a
## standard from-scratch model. Honest scope: no fine pitch-attitude
## control — climb/descend is direct vertical thrust rather than simulated
## angle-of-attack, which keeps it fun and controllable without needing a
## real flight-sim-grade autopilot to stay level. Good enough for GTA-style
## low-altitude traversal; not a substitute for a dedicated flight sim.

const FORWARD_THRUST := 22.0
const VERTICAL_THRUST := 14.0
const LIFT_COEFF := 1.1
const STALL_SPEED := 6.0
const DRAG := 0.35
const ROLL_TORQUE := 4.0
const YAW_COUPLING := 0.6
const LEVEL_CORRECT_SPEED := 2.0

var seat: VehicleSeat

func _ready() -> void:
	gravity_scale = 1.0
	_build_body()
	var cam := _build_camera()
	seat = VehicleSeat.new(self, cam)
	_build_interaction_zone()

func _build_body() -> void:
	var visual := AssetLibrary.instance_or("vehicle_aircraft_body", func() -> Node3D:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(6.0, 0.6, 2.2)
		mesh.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.7, 0.85)
		mesh.material_override = mat
		return mesh
	)
	add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(6.0, 0.6, 2.2)
	collision.shape = shape
	add_child(collision)

func _build_camera() -> Camera3D:
	var spring := SpringArm3D.new()
	spring.spring_length = 10.0
	spring.position.y = 2.0
	spring.rotation.x = deg_to_rad(-12)
	add_child(spring)
	var camera := Camera3D.new()
	spring.add_child(camera)
	return camera

func _build_interaction_zone() -> void:
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 4.0
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(seat.on_body_entered)
	area.body_exited.connect(seat.on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	seat.try_toggle(event)

func _physics_process(delta: float) -> void:
	seat.update_world_discovery()
	if seat.driver == null:
		return

	var throttle_axis := VehicleSeat.throttle_axis()
	# Reverse thrust is weaker than forward — planes don't really have
	# full-power reverse.
	var throttle := throttle_axis if throttle_axis > 0.0 else throttle_axis * 0.5
	var roll_input := VehicleSeat.turn_axis()
	var vertical := VehicleSeat.vertical_axis()

	apply_central_force(-global_transform.basis.z * FORWARD_THRUST * throttle)
	apply_central_force(Vector3.UP * VERTICAL_THRUST * vertical)

	var speed := linear_velocity.length()
	if speed > STALL_SPEED:
		apply_central_force(Vector3.UP * LIFT_COEFF * (speed - STALL_SPEED))

	apply_torque(-global_transform.basis.z * ROLL_TORQUE * roll_input)
	apply_torque(Vector3.UP * ROLL_TORQUE * YAW_COUPLING * -roll_input)

	# Gentle auto-level on pitch/roll when no input, so the plane doesn't
	# tumble uncontrollably — an assist, not full stabilization.
	if is_zero_approx(roll_input):
		var current_roll := global_transform.basis.get_euler().z
		apply_torque(-global_transform.basis.z * -current_roll * LEVEL_CORRECT_SPEED)

	linear_velocity -= linear_velocity * DRAG * delta * 0.2
