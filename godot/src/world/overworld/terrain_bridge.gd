class_name TerrainBridge
extends Node3D
## Drop-in replacement for ProceduralTerrain at call sites.
## Prefers Terrain3D (native AAA) when the GDExtension class exists;
## otherwise keeps the web-safe ProceduralTerrain chunk streamer.
## Same public surface: height_at(), stream_around().

var _proc: ProceduralTerrain
var _t3d: Node = null # Terrain3D when available
var backend: String = "procedural"
var _built := false

func _ready() -> void:
	if not _built:
		await ensure_built()

func ensure_built(seed_key: String = "periliminal") -> void:
	if _built:
		return
	_built = true
	# Terrain3D's clipmap shaders need Forward+/Vulkan (uses fma etc.).
	# Never force it on gl_compatibility (web / GLES3 / many CI Xvfb setups).
	var want_t3d := ClassDB.class_exists("Terrain3D") and not RenderCaps.is_compatibility()
	if want_t3d:
		backend = "terrain3d"
		var tw := TerrainWorld.new()
		add_child(tw)
		await tw.build_async(seed_key, 56.0)
		_t3d = tw.get_node_or_null("Terrain3D")
		_proc = ProceduralTerrain.new()
		_proc.visible = false
		add_child(_proc)
	else:
		backend = "procedural"
		_proc = ProceduralTerrain.new()
		add_child(_proc)
	print("[TerrainBridge] backend=", backend)

func height_at(x: float, z: float) -> float:
	if _t3d != null and _t3d.get("data") != null and _t3d.data.has_method("get_height"):
		var h: float = float(_t3d.data.get_height(Vector3(x, 0.0, z)))
		if is_finite(h) and absf(h) < 100000.0:
			return h
	if _proc != null:
		return _proc.height_at(x, z)
	return 0.0

func stream_around(coord: Vector2i) -> void:
	if _proc != null:
		_proc.stream_around(coord)
	# Terrain3D clipmaps stream themselves — no chunk fan-out needed.
