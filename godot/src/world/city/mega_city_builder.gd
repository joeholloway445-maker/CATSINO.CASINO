class_name MegaCityBuilder
## Builds a full, functional mega-city for a DFW hub. Prefers the
## OpenStreetMap downtown clone in `world_data/osm/<hub>.json` (real street
## polylines + building footprints, via OsmCityLayout) when present; falls
## back to the CityData district grid otherwise. Streetlights, neon, civic
## venues, landmarks, hideouts, and hidden doors are layered on top either way.
##
## Every hard-mesh surface routes through AssetLibrary.material() (so the
## race lens + any installed texture pack apply) or AssetLibrary.instance()
## (so any installed model pack applies). Deterministic per hub — the same
## city rebuilds identically every visit.
##
##   var city := MegaCityBuilder.build("dallas", origin, sky, height_at)
##   add_child(city)

static func build(hub_id: String, origin: Vector3, sky: DayNightSky,
		height_at: Callable, player: Node3D = null) -> Node3D:
	var layout: Dictionary = CityData.HUB_LAYOUT.get(hub_id, CityData.HUB_LAYOUT["arlington"])
	var faction := str(layout.faction)
	var accent := CityData.accent_for(faction)

	var root := Node3D.new()
	root.name = "MegaCity_%s" % hub_id
	root.position = origin
	root.set_meta("sky", sky) # districts' traffic ribbons read this

	# One light-rig driver + one ambience node for the whole city.
	var lighting := CityLighting.begin(sky)
	root.add_child(lighting)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("city_" + hub_id)

	var city_base_y := _sample(height_at, origin.x, origin.z)
	var used_osm := false
	# Prefer the OpenStreetMap downtown clone when world_data/osm/<hub>.json
	# exists — real street polylines + building footprints, scaled to the
	# hub footprint (see docs/DFW_METROPLEX_MAP.md).
	if OsmCityLayout.has_layout(hub_id):
		_build_osm_city(root, hub_id, accent, rng, city_base_y)
		used_osm = true
	else:
		for entry in layout.districts:
			var dcell: Vector2i = entry.cell
			# Local offset under `root` (which is already at world `origin`); the
			# world position is only needed for terrain-height sampling.
			var local := Vector3(dcell.x * CityData.CELL, 0, dcell.y * CityData.CELL)
			var world := origin + local
			_build_district(root, str(entry.type), local, world, accent, rng, height_at)

	# The skyline anchors — each real city's recognizable silhouettes —
	# and the civic set (market/bank/armorer/blacksmith/stockyards/wager
	# hall). Soulless Sanctuary's landmark list alone carries the Arena,
	# College, and Space Station.
	LandmarkBuilder.place_all(root, hub_id, accent, city_base_y)
	if player != null:
		CityVenues.place_all(root, accent, city_base_y, player, hub_id)
		# SEVERAL claimable hideout sites per city (HideoutRegistry owns the
		# guild-exclusion radii, banners, and defender garrisons). Seeded, so
		# the same sites stand in the same places every visit.
		var site_rng := RandomNumberGenerator.new()
		site_rng.seed = hash("hideout_" + hub_id)
		var site_count := 2 + site_rng.randi() % 2 # 2-3 sites per city
		var osm_size := OsmCityLayout.size_of(hub_id) if used_osm else Vector2.ZERO
		for s in site_count:
			var local_pos: Vector3
			if used_osm and osm_size.x > 0.0:
				local_pos = Vector3(
					site_rng.randf_range(osm_size.x * 0.15, osm_size.x * 0.85),
					city_base_y,
					site_rng.randf_range(osm_size.y * 0.15, osm_size.y * 0.85))
			else:
				local_pos = Vector3(
					site_rng.randf_range(1.5, 6.5) * CityData.CELL, city_base_y,
					(0.5 + s * 3.0) * CityData.CELL)
			var hideout := GuildHideout.new()
			hideout.setup("%s_s%d" % [hub_id, s], "supraliminal", hub_id,
				accent, player, origin + local_pos)
			hideout.position = local_pos
			root.add_child(hideout)
		# HIDDEN DOORS: 1-3 per city, seeded, visually identical to every
		# other street door — walking through one drops you into the Liminal.
		# No tells, no map marker: finding one is the whole reward.
		var hd_rng := RandomNumberGenerator.new()
		hd_rng.seed = hash("hidden_" + hub_id)
		for i in 1 + hd_rng.randi() % 3:
			var hd := HiddenDoor.new()
			hd.door_id = "%s_h%d" % [hub_id, i]
			hd.accent = accent
			if used_osm and osm_size.x > 0.0:
				hd.position = Vector3(
					hd_rng.randf_range(osm_size.x * 0.1, osm_size.x * 0.9),
					city_base_y,
					hd_rng.randf_range(osm_size.y * 0.1, osm_size.y * 0.9))
			else:
				hd.position = Vector3(
					hd_rng.randf_range(0.5, 7.0) * CityData.CELL, city_base_y,
					hd_rng.randf_range(0.5, 7.0) * CityData.CELL)
			hd.rotation.y = hd_rng.randf_range(0.0, TAU)
			root.add_child(hd)

	# Ambience follows the FIRST/most-prominent district's bed (the hub's
	# dominant character); each district also has its own local sound.
	var amb := CityAmbience.new()
	root.add_child(amb)
	amb.setup(str(layout.districts[0].type))
	return root

## Build a hub from OSM street polylines + building footprints. Geometry is
## already projected/rescaled into city-local meters by the fetch script.
static func _build_osm_city(root: Node3D, hub_id: String, accent: Color,
		rng: RandomNumberGenerator, base_y: float) -> void:
	var data := OsmCityLayout.load_layout(hub_id)
	var size := OsmCityLayout.size_of(hub_id)
	var holder := Node3D.new()
	holder.name = "OsmDowntown_%s" % hub_id
	root.add_child(holder)

	# Flat plaza plate under the whole imported downtown.
	var ground := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(maxf(size.x, 40.0), 0.4, maxf(size.y, 40.0))
	ground.mesh = gm
	ground.position = Vector3(size.x / 2.0, base_y - 0.2, size.y / 2.0)
	ground.material_override = AssetLibrary.material("asphalt",
		Color(0.12, 0.12, 0.14), 0.2, 0.0, 0.9)
	holder.add_child(ground)

	var road_mat := AssetLibrary.material("asphalt", Color(0.08, 0.08, 0.09), 0.15, 0.0, 0.85)
	var lamp_mat := AssetLibrary.material("streetlight", Color(0.15, 0.15, 0.17), 0.2, 0.7, 0.4)
	var lamp_budget := 0
	const MAX_LAMPS := 90

	for street in data.get("streets", []):
		var pts: Array = street.get("points", [])
		if pts.size() < 2:
			continue
		var width := OsmCityLayout.street_width(int(street.get("width_class", 1)))
		for i in range(pts.size() - 1):
			var a: Array = pts[i]
			var b: Array = pts[i + 1]
			var ax := float(a[0])
			var az := float(a[1])
			var bx := float(b[0])
			var bz := float(b[1])
			var dx := bx - ax
			var dz := bz - az
			var length := sqrt(dx * dx + dz * dz)
			if length < 0.5:
				continue
			var mid := Vector3((ax + bx) * 0.5, base_y - 0.12, (az + bz) * 0.5)
			var strip := _road_strip(mid, Vector3(width, 0.1, length), road_mat)
			strip.rotation.y = atan2(dx, dz)
			holder.add_child(strip)
			# Streetlights along major/medium roads, budget-capped.
			if lamp_budget < MAX_LAMPS and int(street.get("width_class", 1)) >= 1 and i % 3 == 0:
				_streetlight(holder, Vector3(ax, base_y, az), lamp_mat)
				lamp_budget += 1

	for bldg in data.get("buildings", []):
		var cx := float(bldg.get("cx", 0.0))
		var cz := float(bldg.get("cz", 0.0))
		var sx := clampf(float(bldg.get("sx", 10.0)), 3.0, 48.0)
		var sz := clampf(float(bldg.get("sz", 10.0)), 3.0, 48.0)
		var pname := OsmCityLayout.profile_for(bldg)
		var floors := OsmCityLayout.floors_for(bldg, pname)
		var center := Vector3(cx, base_y, cz)
		var node := BuildingBuilder.build_osm(pname, center, base_y, accent, rng,
			sx, sz, floors)
		holder.add_child(node)
		if rng.randf() < 0.35:
			_add_neon(node, accent, rng)

	# Local downtown sound bed.
	var amb := CityAmbience.new()
	holder.add_child(amb)
	amb.setup("downtown_core")

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

	# ---- night traffic: light streaks along the street grid ----
	var traffic := TrafficRibbons.new()
	traffic.name = "Traffic_%s" % dtype
	traffic.grid = grid
	traffic.base_y = base_y
	traffic.sky = _sky_of(root)
	holder.add_child(traffic)

	# ---- district sound bed (local, position-independent stereo) ----
	var amb := CityAmbience.new()
	holder.add_child(amb)
	amb.setup(dtype)

## The sky reference travels via metadata on the city root (set in build()).
static func _sky_of(root: Node3D) -> DayNightSky:
	return root.get_meta("sky") if root.has_meta("sky") else null

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
	_build_lane_markings(holder, grid, base_y)
	_build_sidewalks(holder, grid, base_y)

## Lane dashes down every street center — one MultiMesh per district keeps
## hundreds of dashes at a single draw call.
static func _build_lane_markings(holder: Node3D, grid: Vector2i, base_y: float) -> void:
	var dash_mesh := BoxMesh.new()
	dash_mesh.size = Vector3(0.35, 0.05, 2.2)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.8, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(0.85, 0.8, 0.35)
	mat.emission_energy_multiplier = 0.25
	dash_mesh.material = mat
	var transforms: Array[Transform3D] = []
	var dash_step := 6.0
	# dashes along Z-running streets
	for gx in range(grid.x + 1):
		var x := gx * CityData.CELL - CityData.STREET_WIDTH / 2.0
		var z := 0.0
		while z < grid.y * CityData.CELL:
			transforms.append(Transform3D(Basis.IDENTITY, Vector3(x, base_y - 0.07, z)))
			z += dash_step
	# dashes along X-running streets (rotated 90°)
	var rot := Basis(Vector3.UP, PI / 2.0)
	for gy in range(grid.y + 1):
		var z := gy * CityData.CELL - CityData.STREET_WIDTH / 2.0
		var x := 0.0
		while x < grid.x * CityData.CELL:
			transforms.append(Transform3D(rot, Vector3(x, base_y - 0.07, z)))
			x += dash_step
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = dash_mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	holder.add_child(mmi)

## A raised curb plate under every block lot — the sidewalk ring that
## separates street asphalt from building ground.
static func _build_sidewalks(holder: Node3D, grid: Vector2i, base_y: float) -> void:
	var walk_mat := AssetLibrary.material("sidewalk", Color(0.32, 0.32, 0.35), 0.15, 0.0, 0.8)
	for gx in grid.x:
		for gy in grid.y:
			var pad := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(CityData.BLOCK_SIZE + 3.0, 0.18, CityData.BLOCK_SIZE + 3.0)
			pad.mesh = box
			pad.position = Vector3(
				gx * CityData.CELL + CityData.CELL / 2.0, base_y - 0.05,
				gy * CityData.CELL + CityData.CELL / 2.0)
			pad.material_override = walk_mat
			holder.add_child(pad)

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
	var sign_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(rng.randf_range(3.0, 6.0), rng.randf_range(1.2, 2.4), 0.3)
	sign_mesh.mesh = box
	var mat := AssetLibrary.material("neon", hue, 0.0, 0.0, 0.3)
	mat.emission_enabled = true
	mat.emission = hue
	mat.emission_energy_multiplier = 2.0
	sign_mesh.material_override = mat
	sign_mesh.position = pos
	building.add_child(sign_mesh)
	CityLighting.register_neon(sign_mesh, 2.0)

static func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _first_mesh(child)
		if found != null:
			return found
	return null

static func _build_plaza(holder: Node3D, center: Vector3, accent: Color, rng: RandomNumberGenerator) -> void:
	# A small open square of DEMOLISHABLE props instead of a building —
	# break them for salvage, rebuild them with fragments (BreakableProp).
	for i in rng.randi_range(2, 4):
		var prop := BreakableProp.new()
		prop.accent = accent
		prop.position = center + Vector3(rng.randf_range(-6, 6), 0.0, rng.randf_range(-6, 6))
		holder.add_child(prop)

static func _sample(height_at: Callable, x: float, z: float) -> float:
	if height_at.is_valid():
		return float(height_at.call(x, z))
	return 0.0
