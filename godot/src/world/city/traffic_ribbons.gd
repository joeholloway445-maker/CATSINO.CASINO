class_name TrafficRibbons
extends Node3D
## The night-traffic effect every AAA city shot leans on: streaks of
## head/taillight gliding along the street grid. Each ribbon is a small
## emissive capsule moving down a road lane, white one way, red the other,
## brightness riding the same day/night curve as the rest of the city —
## by day they're nearly invisible, at night the grid comes alive.

var grid: Vector2i = Vector2i(4, 4)
var base_y := 0.0
var sky: DayNightSky

const RIBBONS_PER_DISTRICT := 8
const SPEED_MIN := 9.0
const SPEED_MAX := 16.0

var _ribbons: Array = [] # {mesh, mat, axis, lane, t, speed, headlight}

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name) + grid.x * 7 + grid.y * 13
	for i in RIBBONS_PER_DISTRICT:
		var mesh := MeshInstance3D.new()
		var caps := CapsuleMesh.new()
		caps.radius = 0.25
		caps.height = 2.6
		mesh.mesh = caps
		var headlight := rng.randf() < 0.5
		var col := Color(1.0, 0.97, 0.85) if headlight else Color(1.0, 0.25, 0.2)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 0.0
		mesh.material_override = mat
		add_child(mesh)
		_ribbons.append({
			"mesh": mesh, "mat": mat,
			"axis": rng.randi() % 2, # 0 = along X streets, 1 = along Z
			"lane": rng.randi_range(0, (grid.y if rng.randi() % 2 == 0 else grid.x)),
			"t": rng.randf(),
			"speed": rng.randf_range(SPEED_MIN, SPEED_MAX) * (1.0 if headlight else -1.0),
			"headlight": headlight,
		})

func _process(delta: float) -> void:
	var night := _night_factor()
	var span_x := grid.x * CityData.CELL
	var span_z := grid.y * CityData.CELL
	for r in _ribbons:
		var length := span_x if r.axis == 0 else span_z
		r.t = fposmod(r.t + (r.speed * delta) / maxf(length, 1.0), 1.0)
		var lane_off := float(r.lane) * CityData.CELL - CityData.STREET_WIDTH / 2.0
		# two lanes per street: headlights one side, taillights the other
		var side := -1.6 if r.headlight else 1.6
		var mesh: MeshInstance3D = r.mesh
		if r.axis == 0:
			mesh.position = Vector3(r.t * span_x, base_y + 0.5, lane_off + side)
			mesh.rotation = Vector3(0, 0, PI / 2.0)
		else:
			mesh.position = Vector3(lane_off + side, base_y + 0.5, r.t * span_z)
			mesh.rotation = Vector3(PI / 2.0, 0, 0)
		r.mat.emission_energy_multiplier = night * 2.6
		mesh.visible = night > 0.08

func _night_factor() -> float:
	var hour := sky.current_hour() if is_instance_valid(sky) else 21.0
	var day := clampf(sin((hour - 6.0) / 24.0 * TAU) * 0.5 + 0.5, 0.0, 1.0)
	return clampf(1.0 - day, 0.0, 1.0)
