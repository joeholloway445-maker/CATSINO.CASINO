class_name SpaceVehicle
extends RigidBody3D
## True 6DOF thruster model, no gravity, no "up" — forward/reverse thrust,
## yaw, pitch (vertical thrust, since there's no lift concept in vacuum),
## and roll. Unlike air/land, no auto-leveling or drag: real inertia,
## momentum carries until you thrust against it, matching how space
## traversal should feel different from atmospheric flight.

const THRUST := 16.0
const VERTICAL_THRUST := 12.0
const YAW_TORQUE := 5.0
const ROLL_TORQUE := 5.0
const DAMPING := 0.02

var seat: VehicleSeat

func _ready() -> void:
	gravity_scale = 0.0
	linear_damp = DAMPING
	angular_damp = DAMPING * 4.0
	_build_body()
	var cam := _build_camera()
	seat = VehicleSeat.new(self, cam)
	_build_interaction_zone()

func _build_body() -> void:
	var visual := AssetLibrary.instance_or("vehicle_spacecraft_body", func() -> Node3D:
		var mesh := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(2.2, 1.2, 4.0)
		mesh.mesh = prism
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.55, 0.65)
		mat.metallic = 0.6
		mesh.material_override = mat
		return mesh
	)
	add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.2, 1.2, 4.0)
	collision.shape = shape
	add_child(collision)

func _build_camera() -> Camera3D:
	var spring := SpringArm3D.new()
	spring.spring_length = 9.0
	spring.rotation.x = deg_to_rad(-10)
	add_child(spring)
	var camera := Camera3D.new()
	spring.add_child(camera)
	return camera

func _build_interaction_zone() -> void:
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.5
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(seat.on_body_entered)
	area.body_exited.connect(seat.on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	seat.try_toggle(event)

func _physics_process(_delta: float) -> void:
	seat.update_world_discovery()
	if seat.driver == null:
		return

	var thrust := VehicleSeat.throttle_axis()
	var yaw := VehicleSeat.turn_axis()
	var vertical := VehicleSeat.vertical_axis()
	var roll := VehicleSeat.roll_axis()

	apply_central_force(-global_transform.basis.z * THRUST * thrust)
	apply_central_force(global_transform.basis.y * VERTICAL_THRUST * vertical)
	apply_torque(global_transform.basis.y * YAW_TORQUE * yaw)
	apply_torque(-global_transform.basis.z * ROLL_TORQUE * roll)
