class_name WaterVehicle
extends RigidBody3D
## Boat physics: real (if simple) buoyancy via four corner floatation
## points, not a scripted hover hack — each point applies an upward force
## proportional to how far it's submerged below WATER_LEVEL_Y, so the hull
## naturally settles, pitches, and rolls with uneven load instead of
## floating rigidly flat. No engine-native buoyancy node exists in Godot
## (unlike VehicleBody3D for land), so this is a standard from-scratch
## arcade model — every Godot boat project does some version of this.
##
## WATER_LEVEL_Y is a flat-plane placeholder until a real ocean/water body
## exists in the world; swap it for a per-position height query once one
## does (see docs/VISUAL_DIRECTION_ESO.md's Terrain3D section for where
## that would plug in).

const WATER_LEVEL_Y := 0.0
const BUOYANCY_FORCE := 12.0
const WATER_DRAG := 1.5
const ENGINE_FORCE := 18.0
const TURN_TORQUE := 6.0

var _float_points: Array[Vector3] = [
	Vector3(1.0, 0.0, 2.0), Vector3(-1.0, 0.0, 2.0),
	Vector3(1.0, 0.0, -2.0), Vector3(-1.0, 0.0, -2.0),
]
var seat: VehicleSeat

func _ready() -> void:
	gravity_scale = 1.0
	_build_hull()
	var cam := _build_camera()
	seat = VehicleSeat.new(self, cam)
	_build_interaction_zone()

func _build_hull() -> void:
	var visual := AssetLibrary.instance_or("vehicle_boat_body", func() -> Node3D:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.4, 0.8, 4.5)
		mesh.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.85, 0.9)
		mesh.material_override = mat
		return mesh
	)
	add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 0.8, 4.5)
	collision.shape = shape
	add_child(collision)

func _build_camera() -> Camera3D:
	var spring := SpringArm3D.new()
	spring.spring_length = 9.0
	spring.position.y = 2.5
	spring.rotation.x = deg_to_rad(-15)
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

func _physics_process(delta: float) -> void:
	_apply_buoyancy(delta)
	seat.update_world_discovery()
	if seat.driver == null:
		return
	var throttle := VehicleSeat.throttle_axis()
	var turn := VehicleSeat.turn_axis()
	apply_central_force(-global_transform.basis.z * ENGINE_FORCE * throttle)
	apply_torque(Vector3.UP * TURN_TORQUE * turn * -1.0)
	# Water drag: bleed lateral/vertical velocity so the boat doesn't slide
	# like it's on ice, without a full hydrodynamics model.
	linear_velocity -= linear_velocity * WATER_DRAG * delta * 0.3

func _apply_buoyancy(delta: float) -> void:
	for local_point in _float_points:
		var world_point := global_transform * local_point
		var depth := WATER_LEVEL_Y - world_point.y
		if depth <= 0.0:
			continue
		var force := Vector3.UP * BUOYANCY_FORCE * depth
		apply_force(force * delta * 60.0, world_point - global_transform.origin)
