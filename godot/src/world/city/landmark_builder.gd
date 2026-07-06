class_name LandmarkBuilder
## The skyline anchors: procedural homages to each real city's most
## recognizable silhouettes, placed at fixed spots in each hub so the
## skyline reads as THAT city at a glance — same bones as the real thing,
## differing only through the texture/light/sound packs and the per-race
## identity lens. Every landmark checks AssetLibrary for a real model
## first (slot "landmark_<id>"); the procedural build is the fallback.
##
## These are original constructions evoking public skyline silhouettes —
## geometry is ours, names are ours; only the shapes rhyme with reality.

## hub_id -> landmarks: {id, cell (local city cell), builder args}
const CITY_LANDMARKS := {
	"dallas": [ # New Dallas
		{"id": "reunion_spire", "cell": Vector2(1.5, 1.5)},   # lit sphere on a column
		{"id": "emerald_slab", "cell": Vector2(5.0, 1.0)},    # green-edged monolith tower
		{"id": "veil_arch", "cell": Vector2(0.0, 5.5)},       # the great white bridge arch
	],
	"fort_worth": [ # Hell's Half Acre
		{"id": "acre_clocktower", "cell": Vector2(1.5, 1.5)}, # red-stone courthouse clock
		{"id": "longhorn_gate", "cell": Vector2(4.0, 1.0)},   # stockyards brick gateway
	],
	"denton": [ # Sky Fjord
		{"id": "fjord_dome", "cell": Vector2(1.5, 1.5)},      # domed courthouse-on-the-square
		{"id": "sky_tank", "cell": Vector2(4.5, 4.0)},        # the water tower over the trees
	],
	"arlington": [ # Soulless Sanctuary — ONLY city with these three
		{"id": "sanctuary_dome", "cell": Vector2(1.0, 5.0)},  # the vast arched-roof stadium (the ARENA)
		{"id": "star_bowl", "cell": Vector2(4.5, 5.0)},       # the open-crown stadium bowl
		{"id": "space_station", "cell": Vector2(6.5, 2.0)},   # orbital gate spire + ring
		{"id": "college_hall", "cell": Vector2(6.5, 5.5)},    # the College (university)
	],
}

static func place_all(city_root: Node3D, hub_id: String, accent: Color, base_y: float) -> void:
	for lm in CITY_LANDMARKS.get(hub_id, []):
		var pos := Vector3(float(lm.cell.x) * CityData.CELL, base_y, float(lm.cell.y) * CityData.CELL)
		var node := AssetLibrary.instance("landmark_%s" % lm.id)
		if node == null:
			node = _build(str(lm.id), accent)
		node.position = pos
		city_root.add_child(node)

static func _build(id: String, accent: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Landmark_%s" % id
	match id:
		"reunion_spire":
			# Slim column, geodesic light-ball crown — the skyline's period.
			_cyl(root, 0.9, 0.9, 64.0, Vector3(0, 32, 0), "facade_concrete", Color(0.6, 0.6, 0.65), 0.4, 0.6)
			var ball := _sphere(root, 7.5, Vector3(0, 68, 0), "facade_glass", Color(0.25, 0.25, 0.3), 0.4, 0.2)
			_glow_shell(ball, accent, 0.35)
			for i in 24: # the dot-matrix lights the real one is famous for
				var lamp := OmniLight3D.new()
				var ang := TAU * i / 24.0
				lamp.position = Vector3(cos(ang) * 7.8, 68 + sin(ang * 3.0) * 4.0, sin(ang) * 7.8)
				lamp.light_color = accent
				lamp.light_energy = 0.0
				lamp.omni_range = 5.0
				root.add_child(lamp)
				CityLighting.register_streetlight(lamp)
		"emerald_slab":
			# The tall slab outlined in green argon — visible for miles.
			_box(root, Vector3(16, 92, 10), Vector3(0, 46, 0), "facade_glass", Color(0.2, 0.24, 0.28), 0.7, 0.15)
			_edge_tube(root, Vector3(16, 92, 10), Color(0.2, 1.0, 0.45))
		"veil_arch":
			# The single great white arch with its harp of cables.
			var arch_mat := AssetLibrary.material("facade_concrete", Color(0.92, 0.93, 0.95), 0.15, 0.1, 0.4)
			for i in 13:
				var t := float(i) / 12.0
				var seg := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 1.1
				cm.bottom_radius = 1.1
				cm.height = 9.0
				seg.mesh = cm
				var x := (t - 0.5) * 90.0
				var y := 40.0 * sin(t * PI)
				seg.position = Vector3(x, y, 0)
				seg.rotation.z = lerp_angle(-PI / 3.0, PI / 3.0, t)
				seg.material_override = arch_mat
				root.add_child(seg)
			_box(root, Vector3(96, 1.2, 10), Vector3(0, 8, 0), "asphalt", Color(0.1, 0.1, 0.11), 0.1, 0.9)
		"acre_clocktower":
			# Red-granite courthouse block with the lit clock tower.
			_box(root, Vector3(26, 16, 20), Vector3(0, 8, 0), "facade_brick", Color(0.55, 0.25, 0.2), 0.1, 0.7)
			_box(root, Vector3(8, 22, 8), Vector3(0, 27, 0), "facade_brick", Color(0.6, 0.28, 0.22), 0.1, 0.7)
			var clock := _box(root, Vector3(4.5, 4.5, 0.4), Vector3(0, 34, 4.2), "neon", Color(0.95, 0.92, 0.8), 0.0, 0.3)
			_make_emissive(clock, Color(1.0, 0.95, 0.75), 1.2)
		"longhorn_gate":
			# The brick gateway sign over the old stock pens.
			_box(root, Vector3(3, 12, 3), Vector3(-10, 6, 0), "facade_brick", Color(0.5, 0.3, 0.22), 0.1, 0.8)
			_box(root, Vector3(3, 12, 3), Vector3(10, 6, 0), "facade_brick", Color(0.5, 0.3, 0.22), 0.1, 0.8)
			var gate_sign := _box(root, Vector3(24, 4, 1.4), Vector3(0, 13, 0), "neon", Color(0.9, 0.75, 0.4), 0.0, 0.4)
			_make_emissive(gate_sign, Color(1.0, 0.8, 0.35), 1.6)
		"fjord_dome":
			# The domed stone courthouse holding the town square.
			_box(root, Vector3(24, 14, 24), Vector3(0, 7, 0), "facade_concrete", Color(0.75, 0.7, 0.6), 0.1, 0.6)
			_cyl(root, 6.0, 6.0, 10.0, Vector3(0, 19, 0), "facade_concrete", Color(0.78, 0.73, 0.62), 0.1, 0.6)
			var dome := _sphere(root, 6.5, Vector3(0, 26, 0), "facade_metal", Color(0.45, 0.55, 0.5), 0.6, 0.35)
			_glow_shell(dome, accent, 0.15)
		"sky_tank":
			# The stilted water tower every Texas town points home by.
			for i in 4:
				var ang := TAU * i / 4.0
				_cyl(root, 0.35, 0.35, 22.0, Vector3(cos(ang) * 4.0, 11, sin(ang) * 4.0), "facade_metal", Color(0.5, 0.52, 0.55), 0.7, 0.4)
			_sphere(root, 6.0, Vector3(0, 26, 0), "facade_metal", Color(0.6, 0.75, 0.85), 0.5, 0.4)
		"sanctuary_dome":
			# The colossal arch-roofed cathedral of sport — the ARENA venue.
			_box(root, Vector3(60, 24, 44), Vector3(0, 12, 0), "facade_glass", Color(0.35, 0.38, 0.42), 0.6, 0.25)
			for i in 9:
				var t := float(i) / 8.0
				var rib := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 1.4
				cm.bottom_radius = 1.4
				cm.height = 66.0
				rib.mesh = cm
				rib.position = Vector3(0, 24.0 + 14.0 * sin(t * PI), (t - 0.5) * 44.0)
				rib.rotation.z = PI / 2.0
				rib.material_override = AssetLibrary.material("facade_metal", Color(0.8, 0.8, 0.85), 0.2, 0.8, 0.3)
				root.add_child(rib)
		"star_bowl":
			# The open-crown bowl next door.
			for i in 20:
				var ang := TAU * i / 20.0
				_box(root, Vector3(6, 16 + 6 * sin(ang * 2.0), 3),
					Vector3(cos(ang) * 24.0, 8, sin(ang) * 20.0), "facade_concrete",
					Color(0.6, 0.58, 0.55), 0.2, 0.6).rotation.y = -ang
		"space_station":
			# The orbital gate: spire, halo ring, landing light column.
			_cyl(root, 2.5, 4.0, 70.0, Vector3(0, 35, 0), "facade_metal", Color(0.55, 0.6, 0.7), 0.8, 0.25)
			var ring := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 14.0
			tm.outer_radius = 17.0
			ring.mesh = tm
			ring.position = Vector3(0, 76, 0)
			ring.material_override = AssetLibrary.material("facade_metal", Color(0.5, 0.55, 0.65), 0.2, 0.85, 0.2)
			root.add_child(ring)
			_glow_shell(ring, accent, 0.2)
			var beam := OmniLight3D.new()
			beam.position = Vector3(0, 78, 0)
			beam.light_color = accent
			beam.light_energy = 0.0
			beam.omni_range = 40.0
			root.add_child(beam)
			CityLighting.register_streetlight(beam)
		"college_hall":
			# The College: colonnade hall with the lit rotunda.
			_box(root, Vector3(30, 12, 18), Vector3(0, 6, 0), "facade_concrete", Color(0.8, 0.76, 0.68), 0.1, 0.55)
			for i in 6:
				_cyl(root, 0.8, 0.8, 12.0, Vector3(-12.5 + i * 5.0, 6, 10), "facade_concrete", Color(0.85, 0.82, 0.75), 0.1, 0.5)
			var rotunda := _sphere(root, 5.0, Vector3(0, 15, 0), "facade_glass", Color(0.4, 0.42, 0.5), 0.4, 0.3)
			_glow_shell(rotunda, accent, 0.25)
		_:
			_box(root, Vector3(10, 30, 10), Vector3(0, 15, 0), "facade_concrete", Color(0.5, 0.5, 0.55), 0.3, 0.6)
	return root

# ---------------------------------------------------------------- helpers

static func _box(root: Node3D, size: Vector3, pos: Vector3, tex: String,
		color: Color, metallic: float, roughness: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.position = pos
	mi.material_override = AssetLibrary.material(tex, color, 0.25, metallic, roughness)
	root.add_child(mi)
	return mi

static func _cyl(root: Node3D, top: float, bottom: float, height: float, pos: Vector3,
		tex: String, color: Color, metallic: float, roughness: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	mi.mesh = m
	mi.position = pos
	mi.material_override = AssetLibrary.material(tex, color, 0.25, metallic, roughness)
	root.add_child(mi)
	return mi

static func _sphere(root: Node3D, radius: float, pos: Vector3, tex: String,
		color: Color, metallic: float, roughness: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	mi.mesh = m
	mi.position = pos
	mi.material_override = AssetLibrary.material(tex, color, 0.25, metallic, roughness)
	root.add_child(mi)
	return mi

## The argon-outline trick: thin emissive tubes tracing a box's vertical
## edges and crown, registered as neon so they bloom at night.
static func _edge_tube(root: Node3D, size: Vector3, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	var half_x := size.x / 2.0
	var half_z := size.z / 2.0
	for corner in [Vector2(-half_x, -half_z), Vector2(half_x, -half_z),
			Vector2(half_x, half_z), Vector2(-half_x, half_z)]:
		var tube := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.3
		cm.bottom_radius = 0.3
		cm.height = size.y
		tube.mesh = cm
		tube.position = Vector3(corner.x, size.y / 2.0, corner.y)
		tube.material_override = mat
		root.add_child(tube)
		CityLighting.register_neon(tube, 2.0)

## Add night-glow emission to an existing landmark surface, registered on
## the same day/night curve as every city window.
static func _make_emissive(mi: MeshInstance3D, color: Color, glow: float) -> void:
	var mat := mi.material_override
	if mat is StandardMaterial3D:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.0
		mi.set_meta("night_glow", glow)
		CityLighting.register_window(mi)

static func _glow_shell(mi: MeshInstance3D, accent: Color, glow: float) -> void:
	_make_emissive(mi, accent, glow)
