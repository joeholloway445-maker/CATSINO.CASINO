class_name MegaCityBuilder
## Builds a full, functional mega-city for a DFW hub from the CityData
## blueprint: a road grid, sidewalks, a building on each block (real asset
## or procedural shell), streetlights and neon signage wired to the
## day/night light rig, ambient props, and a per-district sound bed.
##
## Every hard-mesh surface routes through AssetLibrary.material() (so the
## race lens + any installed texture pack apply) or AssetLibrary.instance()
## (so any installed model pack applies). Deterministic per hub — the same
## city rebuilds identically every visit.
##
##   var city := MegaCityBuilder.build("dallas", origin, sky, height_at)
##   add_child(city)

static func build(hub_id: String, origin: Vector3, sky: DayNightSky,
		height_at: Callable) -> Node3D:
	var layout: Dictionary = CityData.HUB_LAYOUT.get(hub_id, CityData.HUB_LAYOUT["arlington"])
	var faction := str(layout.faction)
	var accent := CityData.accent_for(faction)

	var root := Node3D.new()
	root.name = "MegaCity_%s" % hub_id
	root.position = origin

	# One light-rig driver + one ambience node for the whole city.
	var lighting := CityLighting.begin(sky)
	root.add_child(lighting)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("city_" + hub_id)

	for entry in layout.districts:
		var dcell: Vector2i = entry.cell
		# Local offset under `root` (which is already at world `origin`); the
		# world position is only needed for terrain-height sampling.
		var local := Vector3(dcell.x * CityData.CELL, 0, dcell.y * CityData.CELL)
		var world := origin + local
		_build_district(root, str(entry.type), local, world, accent, rng, height_at)

	# Ambience follows the FIRST/most-prominent district's bed (the hub's
	# dominant character); each district also has its own local sound.
	var amb := CityAmbience.new()
	root.add_child(amb)
	amb.setup(str(layout.districts[0].type))
	return root

static func _build_district(root: Node3D, dtype: String, local: Vector3,
		world: Vector3, accent: Color, rng: RandomNumberGenerator,
		height_at: Callable) -> void:
	var d := CityData.district(dtype)
	var grid: Vector2i = d.grid
	# Terrain height is sampled in WORLD space; the pad flattens the district
	# onto that height so the city sits clean on the hub ground.
	var base_y: float = _sample(height_at, world.x, world.z)

	# Everything for this district is built in local space under `holder`,
	# which is positioned at the district's local offset within the city.
	var holder := Node3D.new()
	holder.name = "District_%s" % dtype
	holder.position = local
	root.add_child(holder)

	# ---- ground plaza plate under the district (flat pad) ----
	var span := Vector2(grid.x * CityData.CELL, grid.y * CityData.CELL)
	var ground := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(span.x, 0.4, span.y)
	ground.mesh = gm
	ground.position = Vector3(span.x / 2.0, base_y - 0.2, span.y / 2.0)
	ground.material_override = AssetLibrary.material(str(d.ground_tex),
		Color(0.12, 0.12, 0.14), 0.2, 0.0, 0.9)
	holder.add_child(ground)

	# ---- road grid: strips between blocks ----
	_build_roads(holder, grid, base_y)

	# ---- one building per block + streetlights + neon ----
	for gx in grid.x:
		for gy in grid.y:
			var block_center := Vector3(
				gx * CityData.CELL + CityData.CELL / 2.0, base_y,
				gy * CityData.CELL + CityData.CELL / 2.0)
			# Occasional plaza gap keeps it from being a wall of towers.
			if rng.randf() < 0.12:
				_build_plaza(holder, block_center, accent, rng)
			else:
				var pname := CityData.pick_profile(d.mix, rng)
				var b := BuildingBuilder.build(pname, block_center, base_y,
					accent, rng, CityData.BLOCK_SIZE)
				holder.add_child(b)
				if rng.randf() < float(d.neon_density):
					_add_neon(b, accent, rng)

	# ---- streetlights along the road grid ----
	_build_streetlights(holder, grid, base_y, int(d.streetlight_spacing))

	# ---- district sound bed (local, position-independent stereo) ----
	var amb := CityAmbience.new()
	holder.add_child(amb)
	amb.setup(dtype)

static func _build_roads(holder: Node3D, grid: Vector2i, base_y: float) -> void:
	var road_mat := AssetLibrary.material("asphalt", Color(0.08, 0.08, 0.09), 0.15, 0.0, 0.85)
	# vertical + horizontal streets on the block seams
	for gx in range(grid.x + 1):
		var x := gx * CityData.CELL - CityData.STREET_WIDTH / 2.0
		var strip := _road_strip(Vector3(x, base_y - 0.15, grid.y * CityData.CELL / 2.0),
			Vector3(CityData.STREET_WIDTH, 0.1, grid.y * CityData.CELL), road_mat)
		holder.add_child(strip)
	for gy in range(grid.y + 1):
		var z := gy * CityData.CELL - CityData.STREET_WIDTH / 2.0
		var strip := _road_strip(Vector3(grid.x * CityData.CELL / 2.0, base_y - 0.15, z),
			Vector3(grid.x * CityData.CELL, 0.1, CityData.STREET_WIDTH), road_mat)
		holder.add_child(strip)

static func _road_strip(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	return mi

static func _build_streetlights(holder: Node3D, grid: Vector2i, base_y: float, spacing: int) -> void:
	var post_mat := AssetLibrary.material("streetlight", Color(0.15, 0.15, 0.17), 0.2, 0.7, 0.4)
	for gx in range(0, grid.x + 1, maxi(spacing, 1)):
		for gy in range(0, grid.y + 1, maxi(spacing, 1)):
			var pos := Vector3(gx * CityData.CELL - CityData.STREET_WIDTH / 2.0, base_y,
				gy * CityData.CELL - CityData.STREET_WIDTH / 2.0)
			_streetlight(holder, pos, post_mat)

static func _streetlight(holder: Node3D, pos: Vector3, post_mat: Material) -> void:
	var real := AssetLibrary.instance("streetlight")
	var post: Node3D
	if real != null:
		post = real
	else:
		post = MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.12
		cyl.height = 5.0
		(post as MeshInstance3D).mesh = cyl
		(post as MeshInstance3D).material_override = post_mat
	post.position = pos + Vector3(0, 2.5, 0)
	holder.add_child(post)
	# the actual light — CityLighting switches it on at dusk
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.85, 0.6)
	lamp.omni_range = 12.0
	lamp.light_energy = 0.0
	lamp.position = pos + Vector3(0, 5.2, 0)
	holder.add_child(lamp)
	CityLighting.register_streetlight(lamp)
	# a little emissive bulb so it reads as a lamp head
	var bulb := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.44
	bulb.mesh = sm
	bulb.position = pos + Vector3(0, 5.0, 0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(1.0, 0.9, 0.7)
	bmat.emission_enabled = true
	bmat.emission = Color(1.0, 0.85, 0.6)
	bmat.emission_energy_multiplier = 0.5
	bulb.material_override = bmat
	bulb.set_meta("night_glow", 1.0)
	holder.add_child(bulb)
	CityLighting.register_window(bulb) # rides the same night curve

static func _add_neon(building: Node3D, accent: Color, rng: RandomNumberGenerator) -> void:
	var hue := accent.lerp(Color.from_hsv(rng.randf(), 0.85, 1.0), rng.randf_range(0.2, 0.6))
	var pos := Vector3(rng.randf_range(-2.0, 2.0), rng.randf_range(6.0, 22.0), CityData.BLOCK_SIZE * 0.36)
	var real := AssetLibrary.instance("neon_sign")
	if real != null:
		# Real signage model: place it, and register its first mesh child so
		# its emission still rides the night curve.
		real.position = pos
		building.add_child(real)
		var mesh := _first_mesh(real)
		if mesh != null and mesh.material_override is StandardMaterial3D:
			CityLighting.register_neon(mesh, 2.0)
		return
	var sign := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(rng.randf_range(3.0, 6.0), rng.randf_range(1.2, 2.4), 0.3)
	sign.mesh = box
	var mat := AssetLibrary.material("neon", hue, 0.0, 0.0, 0.3)
	mat.emission_enabled = true
	mat.emission = hue
	mat.emission_energy_multiplier = 2.0
	sign.material_override = mat
	sign.position = pos
	building.add_child(sign)
	CityLighting.register_neon(sign, 2.0)

static func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _first_mesh(child)
		if found != null:
			return found
	return null

static func _build_plaza(holder: Node3D, center: Vector3, accent: Color, rng: RandomNumberGenerator) -> void:
	# A small open square with a couple of props instead of a building.
	for i in rng.randi_range(2, 4):
		var real := AssetLibrary.instance("city_prop")
		var prop: Node3D
		if real != null:
			prop = real
		else:
			prop = MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(rng.randf_range(0.6, 1.4), rng.randf_range(0.5, 1.2), rng.randf_range(0.6, 1.4))
			(prop as MeshInstance3D).mesh = box
			(prop as MeshInstance3D).material_override = AssetLibrary.material(
				"city_prop", accent.darkened(0.5), 0.25, 0.3, 0.7)
		prop.position = center + Vector3(rng.randf_range(-6, 6), 0.5, rng.randf_range(-6, 6))
		holder.add_child(prop)

static func _sample(height_at: Callable, x: float, z: float) -> float:
	if height_at.is_valid():
		return float(height_at.call(x, z))
	return 0.0
