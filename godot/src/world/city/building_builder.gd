class_name BuildingBuilder
## Builds ONE mega-city building as real hard mesh. Asks AssetLibrary for a
## real model first (city_tower/city_lowrise/…); if none is installed it
## constructs a procedural tower whose every surface uses AssetLibrary
## texture-materials (interchangeable) and whose window bands are emissive
## strips wired to CityLighting so they glow at night and go dark by day.
##
## Returns a Node3D positioned at origin (its base sits on y=ground_y).

static func build(profile_name: String, origin: Vector3, ground_y: float,
		accent: Color, rng: RandomNumberGenerator, lot_size: float) -> Node3D:
	var p := CityData.profile(profile_name)
	var real := AssetLibrary.instance(str(p.model_slot))
	if real != null:
		real.position = origin
		real.position.y = ground_y
		AssetLibrary._apply_lens(real, accent, 0.15)
		# Even a real model gets its emissive windows registered if it tags
		# a "Windows" MeshInstance3D; otherwise it just renders as-is.
		_register_real_windows(real, accent)
		return real
	return _procedural(p, profile_name, origin, ground_y, accent, rng, lot_size)

static func _procedural(p: Dictionary, profile_name: String, origin: Vector3,
		ground_y: float, accent: Color, rng: RandomNumberGenerator, lot_size: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Bldg_%s" % profile_name
	root.position = origin
	root.position.y = ground_y

	var floors := rng.randi_range(int(p.min_floors), int(p.max_floors))
	var floor_h: float = p.floor_h
	var height := floors * floor_h
	var fw: float = lot_size * float(p.footprint) * rng.randf_range(0.85, 1.0)
	var fd: float = lot_size * float(p.footprint) * rng.randf_range(0.85, 1.0)

	# ---- shell: stacked to read as distinct floors, occasional setback ----
	var facade_mat := AssetLibrary.material(str(p.facade_tex),
		Color(0.5, 0.52, 0.58), 0.3, float(p.metallic), float(p.roughness))
	var seg_count := 1 + (1 if floors > 20 and rng.randf() < 0.6 else 0)
	var built := 0.0
	var seg_w := fw
	var seg_d := fd
	for s in seg_count:
		var seg_floors := floors if seg_count == 1 else (floors * (2 if s == 0 else 1)) / 3
		var seg_h := seg_floors * floor_h
		var shell := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(seg_w, seg_h, seg_d)
		shell.mesh = box
		shell.material_override = facade_mat
		shell.position.y = built + seg_h / 2.0
		root.add_child(shell)
		# window light band per segment (emissive; driven by CityLighting)
		_add_window_band(root, seg_w, seg_d, built, seg_h, accent, float(p.window_glow))
		built += seg_h
		seg_w *= rng.randf_range(0.6, 0.8)
		seg_d *= rng.randf_range(0.6, 0.8)

	# ---- roof feature ----
	_add_roof(root, str(p.roof), seg_w, seg_d, built, accent, rng)

	# ---- collision so the player can't walk through it ----
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = Vector3(fw, height, fd)
	cs.shape = col
	cs.position.y = height / 2.0
	body.add_child(cs)
	root.add_child(body)
	return root

## The emissive window strip — one MeshInstance3D wrapping the tower with a
## glass/neon material. Registered with CityLighting so its emission energy
## rides the day/night curve (bright at night, near-black at noon).
static func _add_window_band(root: Node3D, w: float, d: float, y0: float,
		h: float, accent: Color, glow: float) -> void:
	var band := MeshInstance3D.new()
	band.name = "Windows"
	var box := BoxMesh.new()
	box.size = Vector3(w * 1.005, h, d * 1.005) # skin just outside the shell
	band.mesh = box
	band.position.y = y0 + h / 2.0
	var mat := AssetLibrary.material("facade_glass",
		accent.darkened(0.4), 0.1, 0.2, 0.1)
	mat.emission_enabled = true
	mat.emission = accent
	mat.emission_energy_multiplier = 0.0 # CityLighting sets this
	band.material_override = mat
	band.set_meta("night_glow", glow)
	root.add_child(band)
	CityLighting.register_window(band)

static func _register_real_windows(node: Node, accent: Color) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and str(child.name).to_lower().contains("window"):
			var mi := child as MeshInstance3D
			var mat := mi.material_override
			if mat is StandardMaterial3D:
				mat.emission_enabled = true
				mat.emission = accent
				mi.set_meta("night_glow", 0.8)
				CityLighting.register_window(mi)
		_register_real_windows(child, accent)

static func _add_roof(root: Node3D, kind: String, w: float, d: float,
		y0: float, accent: Color, rng: RandomNumberGenerator) -> void:
	match kind:
		"antenna":
			var mast := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.08
			cyl.bottom_radius = 0.15
			cyl.height = rng.randf_range(4.0, 9.0)
			mast.mesh = cyl
			mast.position.y = y0 + cyl.height / 2.0
			mast.material_override = AssetLibrary.material("facade_metal", Color(0.3, 0.3, 0.34), 0.2, 0.8, 0.3)
			root.add_child(mast)
			# aircraft-warning beacon: a tiny always-on red light
			var beacon := OmniLight3D.new()
			beacon.light_color = Color(1.0, 0.2, 0.2)
			beacon.light_energy = 2.0
			beacon.omni_range = 6.0
			beacon.position.y = y0 + cyl.height
			root.add_child(beacon)
		"pitched":
			var roof := MeshInstance3D.new()
			var prism := PrismMesh.new()
			prism.size = Vector3(w, w * 0.4, d)
			roof.mesh = prism
			roof.position.y = y0 + w * 0.2
			roof.material_override = AssetLibrary.material("facade_brick", Color(0.4, 0.25, 0.2), 0.3, 0.0, 0.85)
			root.add_child(roof)
		"sawtooth":
			for i in 3:
				var tooth := MeshInstance3D.new()
				var pm := PrismMesh.new()
				pm.size = Vector3(w / 3.0, 1.4, d)
				tooth.mesh = pm
				tooth.position = Vector3((i - 1) * w / 3.0, y0 + 0.7, 0)
				tooth.material_override = AssetLibrary.material("facade_metal", Color(0.35, 0.37, 0.4), 0.2, 0.5, 0.5)
				root.add_child(tooth)
		_: # flat — rooftop utility box
			var hvac := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(w * 0.4, 1.2, d * 0.4)
			hvac.mesh = box
			hvac.position.y = y0 + 0.6
			hvac.material_override = AssetLibrary.material("facade_metal", Color(0.3, 0.3, 0.33), 0.2, 0.6, 0.5)
			root.add_child(hvac)
