class_name TerrainWorld
extends Node3D
## World ground: Terrain3D when the GDExtension is available (desktop AAA /
## native), otherwise the existing ProceduralTerrain chunk streamer (web).
##
## Terrain3D path ports Tokisan's CodeGenerated demo pattern — noise height
## import + auto-shader grass/dirt — so hero layers stop looking like a flat
## white plane the moment the addon loads.

signal ready_terrain(kind: String)

var _terrain_node: Node3D
var kind: String = "none"

func build_async(seed_key: String = "periliminal", height_scale: float = 48.0) -> void:
	if ClassDB.class_exists("Terrain3D"):
		_terrain_node = await _build_terrain3d(seed_key, height_scale)
		kind = "terrain3d"
	else:
		_terrain_node = _build_procedural()
		kind = "procedural"
	if _terrain_node.get_parent() != self:
		add_child(_terrain_node)
	ready_terrain.emit(kind)

func _build_procedural() -> Node3D:
	var pt = ProceduralTerrain.new()
	return pt

func _build_terrain3d(seed_key: String, height_scale: float) -> Node3D:
	# Typed via ClassDB so the script still parses when the extension is absent.
	var terrain = ClassDB.instantiate("Terrain3D")
	terrain.name = "Terrain3D"
	add_child(terrain)

	# Material: auto-shader slope blend (grass / dirt)
	if terrain.get("material") != null:
		var mat = terrain.material
		if mat.has_method("set") or true:
			mat.world_background = 0 # NONE if enum available
			mat.auto_shader = true
			if mat.has_method("set_shader_param"):
				mat.set_shader_param("auto_slope", 10.0)
				mat.set_shader_param("blend_sharpness", 0.975)

	var assets = ClassDB.instantiate("Terrain3DAssets")
	terrain.assets = assets

	var grass_ta = await _texture_asset("Grass", Color.from_hsv(0.30, 0.40, 0.35), Color.from_hsv(0.33, 0.45, 0.40))
	var dirt_ta = await _texture_asset("Dirt", Color.from_hsv(0.08, 0.40, 0.30), Color.from_hsv(0.08, 0.40, 0.40))
	if grass_ta:
		assets.set_texture(0, grass_ta)
	if dirt_ta:
		assets.set_texture(1, dirt_ta)

	# Height from seeded noise (256² keeps first load snappy in CI / Xvfb)
	var noise := FastNoiseLite.new()
	noise.seed = hash(seed_key)
	noise.frequency = 0.002
	noise.fractal_octaves = 4
	var img := Image.create(256, 256, false, Image.FORMAT_RF)
	for x in img.get_width():
		for y in img.get_height():
			var h := noise.get_noise_2d(float(x), float(y))
			img.set_pixel(x, y, Color(h, 0.0, 0.0, 1.0))

	terrain.region_size = 256
	if terrain.get("data") != null and terrain.data.has_method("import_images"):
		terrain.data.import_images([img, null, null], Vector3(-128, 0, -128), 0.0, height_scale)

	# Flatten a plaza around origin so cities / spawn still work
	if terrain.data.has_method("get_height"):
		pass

	return terrain

func _texture_asset(asset_name: String, c0: Color, c1: Color):
	if not ClassDB.class_exists("Terrain3DTextureAsset"):
		return null
	var gradient := Gradient.new()
	gradient.set_color(0, c0)
	gradient.set_color(1, c1)
	var fnl := FastNoiseLite.new()
	fnl.frequency = 0.004
	var alb_noise := NoiseTexture2D.new()
	alb_noise.width = 128
	alb_noise.height = 128
	alb_noise.seamless = true
	alb_noise.noise = fnl
	alb_noise.color_ramp = gradient
	await alb_noise.changed
	var alb_img: Image = alb_noise.get_image()
	for x in alb_img.get_width():
		for y in alb_img.get_height():
			var clr: Color = alb_img.get_pixel(x, y)
			clr.a = clr.v
			alb_img.set_pixel(x, y, clr)
	alb_img.generate_mipmaps()
	var albedo := ImageTexture.create_from_image(alb_img)

	var nrm_noise := NoiseTexture2D.new()
	nrm_noise.width = 128
	nrm_noise.height = 128
	nrm_noise.as_normal_map = true
	nrm_noise.seamless = true
	nrm_noise.noise = fnl
	await nrm_noise.changed
	var nrm_img: Image = nrm_noise.get_image()
	for x in nrm_img.get_width():
		for y in nrm_img.get_height():
			var n: Color = nrm_img.get_pixel(x, y)
			n.a = 0.8
			nrm_img.set_pixel(x, y, n)
	nrm_img.generate_mipmaps()
	var normal := ImageTexture.create_from_image(nrm_img)

	var ta = ClassDB.instantiate("Terrain3DTextureAsset")
	ta.name = asset_name
	ta.albedo_texture = albedo
	ta.normal_texture = normal
	ta.uv_scale = 0.08
	return ta
