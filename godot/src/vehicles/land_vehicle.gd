class_name LandVehicle
extends VehicleBody3D
## Real 4-wheel car physics via Godot's built-in VehicleBody3D/VehicleWheel3D
## (not custom wheel math). Steering/throttle model adapted from the
## official godotengine/godot-demo-projects "truck_town" sample (MIT) —
## same publisher/license family as the base player controller. Body/wheel
## meshes are procedural placeholders; drop a real model into
## assets/models/vehicle_car_body.glb (see AssetLibrary) to upgrade with
## zero code changes.

const STEER_SPEED := 1.5
const STEER_LIMIT := 0.5
const ENGINE_FORCE := 60.0
const BRAKE_STRENGTH := 2.0

var _steer_target := 0.0
var seat: VehicleSeat

func _ready() -> void:
	center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.3, 0)
	_build_body()
	_build_wheels()
	var cam := _build_camera()
	seat = VehicleSeat.new(self, cam)
	_build_interaction_zone()

func _build_body() -> void:
	# Deterministic per spawn point — same hub always gets the same car,
	# same as every other seeded/world-placed thing in this codebase.
	var vrng := RandomNumberGenerator.new()
	vrng.seed = hash(position)
	var visual := AssetLibrary.instance_variant_or("vehicle_car_body", vrng, func() -> Node3D:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.8, 0.9, 4.2)
		mesh.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.75, 0.15, 0.15)
		mesh.material_override = mat
		mesh.position.y = 0.5
		return mesh
	)
	add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.8, 1.0, 4.2)
	collision.shape = shape
	collision.position.y = 0.5
	add_child(collision)

func _build_wheels() -> void:
	var positions := {
		"WheelFL": Vector3(0.9, 0.0, 1.4), "WheelFR": Vector3(-0.9, 0.0, 1.4),
		"WheelRL": Vector3(0.9, 0.0, -1.4), "WheelRR": Vector3(-0.9, 0.0, -1.4),
	}
	for wheel_name in positions:
		var wheel := VehicleWheel3D.new()
		wheel.name = wheel_name
		wheel.position = positions[wheel_name]
		wheel.use_as_traction = true
		wheel.use_as_steering = wheel_name.ends_with("FL") or wheel_name.ends_with("FR")
		wheel.wheel_radius = 0.4
		wheel.wheel_friction_slip = 2.0
		wheel.suspension_travel = 0.3
		wheel.suspension_stiffness = 40.0
		wheel.damping_compression = 0.85
		add_child(wheel)
		var mesh := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.4
		cyl.bottom_radius = 0.4
		cyl.height = 0.3
		mesh.mesh = cyl
		mesh.rotation.z = deg_to_rad(90)
		wheel.add_child(mesh)

func _build_camera() -> Camera3D:
	var spring := SpringArm3D.new()
	spring.spring_length = 8.0
	spring.position.y = 2.0
	spring.rotation.x = deg_to_rad(-15)
	add_child(spring)
	var camera := Camera3D.new()
	spring.add_child(camera)
	return camera

func _build_interaction_zone() -> void:
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.0
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
		engine_force = 0.0
		brake = 1.0
		return
	brake = 0.0

	_steer_target = VehicleSeat.turn_axis() * STEER_LIMIT
	steering = move_toward(steering, _steer_target, STEER_SPEED * delta)

	var throttle_axis := VehicleSeat.throttle_axis()
	if throttle_axis > 0.0:
		engine_force = ENGINE_FORCE * throttle_axis
	elif throttle_axis < 0.0:
		engine_force = ENGINE_FORCE * BRAKE_STRENGTH * throttle_axis
	else:
		engine_force = 0.0
