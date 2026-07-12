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

## OSM footprint build: explicit lot width/depth + floor count from real
## building tags (or OsmCityLayout heuristics), so downtown massing tracks
## the real city instead of a random procedural mix.
static func build_osm(profile_name: String, origin: Vector3, ground_y: float,
		accent: Color, rng: RandomNumberGenerator, sx: float, sz: float,
		floors: int) -> Node3D:
	var p := CityData.profile(profile_name)
	var real := AssetLibrary.instance(str(p.model_slot))
	if real != null:
		real.position = origin
		real.position.y = ground_y
		AssetLibrary._apply_lens(real, accent, 0.15)
		_register_real_windows(real, accent)
		return real
	var lot := maxf(sx, sz)
	# Force footprint fill close to the real OSM bbox; _procedural still
	# applies profile.footprint, so bump lot so the shell lands near sx/sz.
	var adjusted := lot / maxf(float(p.footprint), 0.5)
	var node := _procedural(p, profile_name, origin, ground_y, accent, rng,
		adjusted, floors, sx, sz)
	return node

static func _procedural(p: Dictionary, profile_name: String, origin: Vector3,
		ground_y: float, accent: Color, rng: RandomNumberGenerator, lot_size: float,
		force_floors: int = 0, force_w: float = 0.0, force_d: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "Bldg_%s" % profile_name
	root.position = origin
	root.position.y = ground_y

	var floors := force_floors if force_floors > 0 else rng.randi_range(int(p.min_floors), int(p.max_floors))
	var floor_h: float = p.floor_h
	var height := floors * floor_h
	var fw: float = force_w if force_w > 0.0 else lot_size * float(p.footprint) * rng.randf_range(0.85, 1.0)
	var fd: float = force_d if force_d > 0.0 else lot_size * float(p.footprint) * rng.randf_range(0.85, 1.0)

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
		# Per-floor window strips with deterministic lit/dark scatter — the
		# difference between "a glowing box" and "a building people are in".
		_add_floor_windows(root, seg_w, seg_d, built, seg_floors, floor_h, accent, float(p.window_glow), rng)
		# Corner pilasters: vertical trim that catches rim light and breaks
		# the flat-slab silhouette.
		_add_pilasters(root, seg_w, seg_d, built, seg_h, facade_mat)
		built += seg_h
		seg_w *= rng.randf_range(0.6, 0.8)
		seg_d *= rng.randf_range(0.6, 0.8)

	# Ground floor reads as street-level: taller glass storefront band.
	_add_storefront(root, fw, fd, floor_h, accent, rng)

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

## Per-floor window strips. Each strip is a thin emissive band just outside
## the shell; a deterministic scatter leaves some floors dark, some dim,
## some bright — the organic lit-office pattern every real skyline has.
## Tall towers band every other floor to keep node counts sane.
static func _add_floor_windows(root: Node3D, w: float, d: float, y0: float,
		floor_count: int, floor_h: float, accent: Color, glow: float,
		rng: RandomNumberGenerator) -> void:
	var step := 1 if floor_count <= 20 else 2
	for f in range(0, floor_count, step):
		var strip := MeshInstance3D.new()
		strip.name = "Windows"
		var box := BoxMesh.new()
		box.size = Vector3(w * 1.01, floor_h * 0.45, d * 1.01)
		strip.mesh = box
		strip.position.y = y0 + f * floor_h + floor_h * 0.55
		var mat := AssetLibrary.material("facade_glass", accent.darkened(0.45), 0.1, 0.2, 0.1)
		mat.emission_enabled = true
		mat.emission = accent
		mat.emission_energy_multiplier = 0.0 # CityLighting drives this
		strip.material_override = mat
		# Lit-floor scatter: ~15% dark, ~35% dim, the rest full.
		var roll := rng.randf()
		var floor_glow := 0.0 if roll < 0.15 else (glow * 0.35 if roll < 0.5 else glow)
		strip.set_meta("night_glow", floor_glow)
		root.add_child(strip)
		CityLighting.register_window(strip)

static func _add_pilasters(root: Node3D, w: float, d: float, y0: float,
		h: float, facade_mat: Material) -> void:
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var pil := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.6, h, 0.6)
		pil.mesh = box
		pil.position = Vector3(corner.x * (w / 2.0), y0 + h / 2.0, corner.y * (d / 2.0))
		pil.material_override = facade_mat
		root.add_child(pil)

## Street level: a taller glass band (the lobby/storefront) plus a thin
## colored awning line — makes the ground floor read as inhabited retail
## instead of tower-meets-dirt.
static func _add_storefront(root: Node3D, w: float, d: float, floor_h: float,
		accent: Color, rng: RandomNumberGenerator) -> void:
	var glass := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(w * 1.02, floor_h * 0.8, d * 1.02)
	glass.mesh = box
	glass.position.y = floor_h * 0.45
	var mat := AssetLibrary.material("facade_glass", Color(0.15, 0.17, 0.2), 0.1, 0.3, 0.05)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.95, 0.85)
	mat.emission_energy_multiplier = 0.0
	glass.material_override = mat
	glass.set_meta("night_glow", 0.9) # storefronts stay lit late
	root.add_child(glass)
	CityLighting.register_window(glass)
	var awning := MeshInstance3D.new()
	var abox := BoxMesh.new()
	abox.size = Vector3(w * 1.06, 0.25, d * 1.06)
	awning.mesh = abox
	awning.position.y = floor_h * 0.9
	var amat := AssetLibrary.material("neon", accent.lerp(Color.from_hsv(rng.randf(), 0.7, 0.9), 0.4), 0.0, 0.0, 0.4)
	amat.emission_enabled = true
	amat.emission = amat.albedo_color
	amat.emission_energy_multiplier = 1.2
	awning.material_override = amat
	root.add_child(awning)
	CityLighting.register_neon(awning, 1.2)

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
