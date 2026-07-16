class_name ProceduralTerrain
extends Node3D
## Streams heightmap terrain chunks around the player, one mesh per
## DiscoveryManager grid cell (HubRegionData.CHUNK_SIZE world units).
## Heights come from a deterministic FastNoiseLite field offset by each
## chunk's ProceduralRegionGenerator elevation, so terrain is stable across
## sessions and clients. Biomes tint the ground; when the discover mechanic
## repaints a chunk's dominant_pack, the tint blends toward that player's
## influence color — the overworld literally shows who explored it.

const HubRegionData = preload("res://src/data/hub_region_data.gd")

const DEFAULT_VIEW_RADIUS := 2 # chunks in every direction, on foot
## Vehicles cover ground much faster than walking; a bigger radius means
## fewer, larger streaming loads instead of constant small ones at the
## same on-foot cadence — see set_view_radius(), called from
## layer_world.gd/overworld.gd on vehicle enter/exit.
var _view_radius := DEFAULT_VIEW_RADIUS
const QUADS_PER_CHUNK := 16
const HEIGHT_SCALE := 8.0

const BIOME_COLORS := {
	"plains":        Color(0.35, 0.55, 0.28),
	"ruins":         Color(0.45, 0.42, 0.38),
	"crystal_field": Color(0.45, 0.55, 0.75),
	"overgrowth":    Color(0.20, 0.45, 0.25),
	"ashland":       Color(0.35, 0.28, 0.30),
	"coastal":       Color(0.28, 0.22, 0.18), # seabed under the water plane
}
const HUB_COLOR := Color(0.55, 0.52, 0.45)
const WATER_SURFACE_COLOR := Color(0.15, 0.35, 0.55, 0.75)
## Must match WaterVehicle.WATER_LEVEL_Y — the seabed is generated well
## below this (see height_at's coastal branch) so the surface plane always
## reads as a real body of water, not a flooded field.
const WATER_LEVEL_Y := 0.0

var _noise := FastNoiseLite.new()
var _loaded: Dictionary = {} # Vector2i -> Node3D (chunk root)

func _ready() -> void:
	_noise.seed = 0x43415453 # "CATS"
	_noise.frequency = 0.012
	_noise.fractal_octaves = 4
	DiscoveryManager.chunk_repainted.connect(_on_chunk_repainted)

## Deterministic terrain height at any world position — used by both mesh
## generation and spawn placement so nothing ever spawns underground.
func height_at(world_x: float, world_z: float) -> float:
	var coord := DiscoveryManager.world_pos_to_chunk(Vector3(world_x, 0, world_z))
	var chunk := DiscoveryManager.get_or_generate_chunk(coord)
	# Hub chunks are flat: the mega-city sits on a graded plaza foundation,
	# not rolling noise. Everywhere else keeps its biome elevation + noise.
	if chunk.is_hub:
		return 0.0
	var elevation := float(chunk.biome.get("elevation", 0.0))
	var noise_scale := HEIGHT_SCALE
	if str(chunk.biome.get("biome", "")) == "coastal":
		# Keep the seabed mostly submerged (WaterVehicle's WATER_LEVEL_Y is a
		# flat 0.0) — full HEIGHT_SCALE noise would poke rock through the
		# surface often enough that "coastal" wouldn't read as water.
		noise_scale = HEIGHT_SCALE * 0.15
	return elevation + _noise.get_noise_2d(world_x, world_z) * noise_scale

## Bigger radius = fewer, larger streaming loads — used while piloting a
## vehicle so terrain doesn't have to keep pace with small on-foot-sized
## loads at car/boat/plane speed. Restore DEFAULT_VIEW_RADIUS on exit.
func set_view_radius(r: int) -> void:
	_view_radius = maxi(r, 1)

func get_view_radius() -> int:
	return _view_radius

## Ensure all chunks within _view_radius of coord exist; drop the rest.
func stream_around(coord: Vector2i) -> void:
	var wanted: Dictionary = {}
	for dx in range(-_view_radius, _view_radius + 1):
		for dz in range(-_view_radius, _view_radius + 1):
			var c := coord + Vector2i(dx, dz)
			wanted[c] = true
			if not _loaded.has(c):
				_loaded[c] = _build_chunk(c)
	for c in _loaded.keys():
		if not wanted.has(c):
			_loaded[c].queue_free()
			_loaded.erase(c)

func _build_chunk(coord: Vector2i) -> Node3D:
	var size := float(HubRegionData.CHUNK_SIZE)
	var origin := Vector3(coord.x * size, 0.0, coord.y * size)
	var chunk := DiscoveryManager.get_or_generate_chunk(coord)

	var root := Node3D.new()
	root.name = "Chunk_%d_%d" % [coord.x, coord.y]
	root.position = origin
	add_child(root)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := size / QUADS_PER_CHUNK
	for z in range(QUADS_PER_CHUNK):
		for x in range(QUADS_PER_CHUNK):
			var x0 := x * step
			var z0 := z * step
			var corners := [
				Vector3(x0, 0, z0), Vector3(x0 + step, 0, z0),
				Vector3(x0 + step, 0, z0 + step), Vector3(x0, 0, z0 + step),
			]
			var uvs := [
				Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
			]
			for i in range(corners.size()):
				var w: Vector3 = corners[i]
				corners[i].y = height_at(origin.x + w.x, origin.z + w.z)
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_uv(uvs[idx] * (size / 8.0)) # tile PBR maps ~8m
				st.add_vertex(corners[idx])
	st.generate_normals()
	st.generate_tangents()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	mi.mesh = mesh
	mi.material_override = _chunk_material(chunk)
	root.add_child(mi)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	body.add_child(shape)
	root.add_child(body)

	if str(chunk.biome.get("biome", "")) == "coastal":
		root.add_child(_build_water_surface(size))

	_scatter_props(root, chunk, size)
	ChunkContentSpawner.spawn(root, chunk, coord, size, _terrain_bridge())
	EntityCombatSpawner.spawn(root, chunk, coord, size, _terrain_bridge())
	return root

## ChunkContentSpawner needs TerrainBridge's public height_at() for
## non-water spawn placement; ProceduralTerrain is always a direct child
## of exactly one TerrainBridge in every scene that builds it.
func _terrain_bridge() -> TerrainBridge:
	var p := get_parent()
	return p if p is TerrainBridge else null

## Flat translucent plane at WATER_LEVEL_Y so "coastal" chunks read as an
## actual body of water rather than just low, dark dirt — the seabed mesh
## underneath is real geometry (WaterVehicle floats and collides against
## it via buoyancy + the StaticBody3D above), this plane is visual only.
func _build_water_surface(size: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "WaterSurface"
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	mi.mesh = plane
	mi.position = Vector3(size * 0.5, WATER_LEVEL_Y, size * 0.5)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WATER_SURFACE_COLOR
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.04
	mat.metallic = 0.45
	mat.specular = 0.7
	if not RenderCaps.is_compatibility() and "refraction_enabled" in mat:
		mat.refraction_enabled = true
		mat.refraction_scale = 0.02
	mi.material_override = mat
	return mi

func _chunk_material(chunk: WorldChunk) -> StandardMaterial3D:
	var biome := str(chunk.biome.get("biome", "plains"))
	var color: Color = HUB_COLOR if chunk.is_hub else BIOME_COLORS.get(
		biome, BIOME_COLORS["plains"])
	if chunk.dominant_pack != null:
		color = color.lerp(chunk.dominant_pack.texture_tint, 0.35)
	# PBR ground maps when installed (Poly Haven grass/dirt/sand/asphalt).
	# Hub plazas stay asphalt; coastal → sand; ashland/ruins → dirt; else grass.
	var slot := "asphalt" if chunk.is_hub else _biome_ground_slot(biome)
	var mat: StandardMaterial3D
	if AssetLibrary.has_texture(slot):
		mat = AssetLibrary.material(slot, color, 0.2, 0.0, 0.85)
	else:
		# All hard mesh renders through the player's race lens — the same chunk
		# is made of different stuff on different players' clients.
		mat = IdentityLens.world_material(color)
		mat.roughness = maxf(mat.roughness, 0.7) # ground stays walkable-matte
	mat.roughness = maxf(mat.roughness, 0.72)
	return mat

func _biome_ground_slot(biome: String) -> String:
	match biome:
		"coastal":
			return "sand" if AssetLibrary.has_texture("sand") else "dirt"
		"ashland", "ruins":
			return "dirt" if AssetLibrary.has_texture("dirt") else "asphalt"
		"crystal_field":
			return "dirt" if AssetLibrary.has_texture("dirt") else "grass"
		_:
			return "grass" if AssetLibrary.has_texture("grass") else "dirt"

## Low-poly biome props (crystals, ruins pillars, trees) from the chunk's
## deterministic prop_seed — no imported assets.
func _scatter_props(root: Node3D, chunk: WorldChunk, size: float) -> void:
	if chunk.is_hub:
		return
	if str(chunk.biome.get("biome", "")) == "coastal":
		return # no land props underwater; the seabed stays clear
	var rng := RandomNumberGenerator.new()
	rng.seed = int(chunk.biome.get("prop_seed", 0))
	var density: float = float(chunk.biome.get("prop_density", 0.3))
	var count := int(density * 12.0)
	var biome: String = str(chunk.biome.get("biome", "plains"))
	var slot := {"crystal_field": "crystal", "ruins": "ruin_pillar", "ashland": "rock"}.get(biome, "tree")
	for i in range(count):
		var px := rng.randf() * size
		var pz := rng.randf() * size
		# Real asset if installed (docs/SHIPPING.md), procedural otherwise.
		# Prefer variant pools so forests/ruins don't clone one mesh.
		var prop: Node3D = AssetLibrary.instance_variant_or(slot, rng,
			func(): return _make_prop(biome, rng),
			BIOME_COLORS.get(biome, Color.WHITE), 0.15)
		prop.position = Vector3(px, height_at(root.position.x + px, root.position.z + pz), pz)
		prop.rotation.y = rng.randf() * TAU
		var sc := rng.randf_range(0.85, 1.25)
		prop.scale = Vector3(sc, sc, sc)
		root.add_child(prop)

func _make_prop(biome: String, rng: RandomNumberGenerator) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	match biome:
		"crystal_field":
			var prism := PrismMesh.new()
			prism.size = Vector3(0.8, rng.randf_range(1.5, 3.5), 0.8)
			mi.mesh = prism
			mat.albedo_color = Color(0.6, 0.75, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.3, 0.5, 1.0)
			mat.emission_energy_multiplier = 0.6
		"ruins":
			var box := BoxMesh.new()
			box.size = Vector3(rng.randf_range(0.8, 1.4), rng.randf_range(1.0, 3.0), rng.randf_range(0.8, 1.4))
			mi.mesh = box
			mat.albedo_color = Color(0.5, 0.48, 0.44)
		"ashland":
			var rock := SphereMesh.new()
			rock.radius = rng.randf_range(0.4, 1.1)
			rock.height = rock.radius * 1.4
			mi.mesh = rock
			mat.albedo_color = Color(0.25, 0.2, 0.22)
		_: # plains / overgrowth — stylized cone tree
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = rng.randf_range(0.8, 1.6)
			cone.height = rng.randf_range(2.5, 5.0)
			mi.mesh = cone
			mi.position.y += cone.height * 0.5
			mat.albedo_color = Color(0.15, 0.4, 0.2) if biome == "overgrowth" else Color(0.25, 0.5, 0.25)
	mat.roughness = 0.9
	# Props are hard mesh too — same race lens, lighter pull.
	var lensed := IdentityLens.world_material(mat.albedo_color, 0.25)
	if mat.emission_enabled:
		lensed.emission_enabled = true
		lensed.emission = mat.emission
		lensed.emission_energy_multiplier = mat.emission_energy_multiplier
	mi.material_override = lensed
	return mi

func _on_chunk_repainted(coord: Vector2i, chunk: WorldChunk) -> void:
	if _loaded.has(coord):
		var ground: MeshInstance3D = _loaded[coord].get_node_or_null("Ground")
		if ground:
			ground.material_override = _chunk_material(chunk)
