extends Node3D

class_name PawsVegasScene

# ─── Configuration ────────────────────────────────────────────────────────────
@export var npc_count: int = 20
@export var npc_wander_radius: float = 20.0
@export var npc_spawn_center: Vector3 = Vector3.ZERO

# ─── Child node references ────────────────────────────────────────────────────
@onready var ambient_light: OmniLight3D = $AmbientNeon/NeonLight
@onready var npc_container: Node3D = $NPCContainer
@onready var game_lobby_ui: GameLobbyUI = $UILayer/GameLobbyUI
@onready var crowd_density_label: Label3D = $CrowdDensityMarker/DensityLabel
@onready var particle_fx: GPUParticles3D = $AmbientNeon/NeonParticles

# ─── NPC templates ────────────────────────────────────────────────────────────
const NPC_RACES: Array[CharacterData.Race] = [
	CharacterData.Race.KETH, CharacterData.Race.LUMARI, CharacterData.Race.VEX,
	CharacterData.Race.FEROX, CharacterData.Race.AZHUL, CharacterData.Race.SYLVA,
	CharacterData.Race.GEARA, CharacterData.Race.NYX, CharacterData.Race.AQUIS,
	CharacterData.Race.IGNI, CharacterData.Race.KRYOS, CharacterData.Race.MYCO,
	CharacterData.Race.VOLT, CharacterData.Race.PETRA, CharacterData.Race.SANGUIS,
	CharacterData.Race.CHIMERA, CharacterData.Race.ASTRA, CharacterData.Race.FERROS,
	CharacterData.Race.ETHEREA, CharacterData.Race.GLYPHE,
]
const NPC_FRAMES: Array[CharacterData.Frame] = [
	CharacterData.Frame.VEIL, CharacterData.Frame.ZEPHYR, CharacterData.Frame.BASTION,
	CharacterData.Frame.BEHEMOTH, CharacterData.Frame.PHANTOM, CharacterData.Frame.BOLT,
	CharacterData.Frame.FLUX,
]

# ─── Runtime state ────────────────────────────────────────────────────────────
var _npcs: Array[Node3D] = []
var _npc_data: Array[CharacterData] = []
var _current_player_count: int = 0

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	_setup_ambient()
	_spawn_npcs(npc_count)
	_open_game_lobby()
	_connect_signals()

func _process(_delta: float) -> void:
	_update_npc_wander()

# ─── Ambient setup ────────────────────────────────────────────────────────────
func _setup_ambient() -> void:
	if is_instance_valid(ambient_light):
		ambient_light.light_color = Color(0.9, 0.3, 1.0)   # Purple neon
		ambient_light.light_energy = 2.5
		ambient_light.omni_range = 40.0

	if is_instance_valid(particle_fx):
		particle_fx.emitting = true

	# Pulsing neon effect via Tween
	var pulse_tween := create_tween().set_loops()
	pulse_tween.tween_property(ambient_light, "light_energy", 1.8, 1.2)\
		.set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(ambient_light, "light_energy", 2.5, 1.2)\
		.set_ease(Tween.EASE_IN_OUT)

# ─── NPC spawning ─────────────────────────────────────────────────────────────
func _spawn_npcs(count: int) -> void:
	# Clear existing
	for npc in _npcs:
		if is_instance_valid(npc):
			npc.queue_free()
	_npcs.clear()
	_npc_data.clear()

	for i in range(count):
		var data := _make_random_character_data(i)
		_npc_data.append(data)

		var npc_node := _create_npc_node(data, i)
		npc_container.add_child(npc_node)
		_npcs.append(npc_node)

func _make_random_character_data(seed_offset: int) -> CharacterData:
	var data := CharacterData.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec() + seed_offset * 1337

	data.character_name = "NPC_%d" % seed_offset
	data.race = NPC_RACES[rng.randi() % NPC_RACES.size()]
	data.frame = NPC_FRAMES[rng.randi() % NPC_FRAMES.size()]
	data.mod = CharacterData.Mod.NULL
	return data

func _create_npc_node(data: CharacterData, index: int) -> Node3D:
	var npc := Node3D.new()
	npc.name = "NPC_%d" % index

	# Random starting position around spawn center
	var angle: float = randf() * TAU
	var dist: float = randf_range(2.0, npc_wander_radius)
	npc.position = npc_spawn_center + Vector3(
		cos(angle) * dist,
		0.0,
		sin(angle) * dist
	)

	# Visual placeholder — a simple MeshInstance3D capsule
	var mesh_instance := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.6
	mesh_instance.mesh = capsule
	mesh_instance.position.y = 0.8

	# Colour by race for variety
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _race_color(data.race)
	mesh_instance.material_override = mat
	npc.add_child(mesh_instance)

	# NavigationAgent3D for wandering
	var nav_agent := NavigationAgent3D.new()
	nav_agent.name = "NavAgent"
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.8
	npc.add_child(nav_agent)

	# Store wander timer as metadata
	npc.set_meta("wander_timer", randf_range(2.0, 8.0))
	npc.set_meta("wander_elapsed", 0.0)
	npc.set_meta("nav_agent_path", nav_agent.get_path())

	return npc

func _race_color(race: CharacterData.Race) -> Color:
	# Deterministic color per race enum value
	var h: float = float(int(race) * 37 % 360) / 360.0
	return Color.from_hsv(h, 0.6, 0.85)

# ─── NPC wandering (called from _process) ────────────────────────────────────
func _update_npc_wander() -> void:
	var dt: float = get_process_delta_time()
	for npc in _npcs:
		if not is_instance_valid(npc):
			continue

		var elapsed: float = npc.get_meta("wander_elapsed", 0.0) + dt
		var timer: float = npc.get_meta("wander_timer", 5.0)
		npc.set_meta("wander_elapsed", elapsed)

		var nav: NavigationAgent3D = npc.get_node_or_null("NavAgent")
		if nav == null:
			continue

		if elapsed >= timer or nav.is_navigation_finished():
			# Pick new random target
			var angle: float = randf() * TAU
			var dist: float = randf_range(1.0, npc_wander_radius)
			var target: Vector3 = npc_spawn_center + Vector3(
				cos(angle) * dist, 0.0, sin(angle) * dist
			)
			nav.target_position = target
			npc.set_meta("wander_elapsed", 0.0)
			npc.set_meta("wander_timer", randf_range(3.0, 9.0))
		else:
			# Move toward next path position
			if not nav.is_navigation_finished():
				var next_pos: Vector3 = nav.get_next_path_position()
				var direction: Vector3 = (next_pos - npc.global_position).normalized()
				npc.global_position += direction * 1.8 * dt  # Walk speed 1.8 m/s
				if direction.length_squared() > 0.001:
					npc.look_at(npc.global_position + direction, Vector3.UP)

# ─── Game lobby ───────────────────────────────────────────────────────────────
func _open_game_lobby() -> void:
	if is_instance_valid(game_lobby_ui):
		game_lobby_ui.visible = true
		game_lobby_ui.refresh()

# ─── Signals ─────────────────────────────────────────────────────────────────
func _connect_signals() -> void:
	if DistrictManager.has_signal("player_count_updated"):
		DistrictManager.player_count_updated.connect(_on_player_count_updated)

func _on_player_count_updated(district_name: String, count: int) -> void:
	if district_name != "paw_vegas":
		return
	_current_player_count = count
	_update_crowd_density()

func _update_crowd_density() -> void:
	if not is_instance_valid(crowd_density_label):
		return

	var density_str: String
	if _current_player_count < 10:
		density_str = "Quiet"
	elif _current_player_count < 50:
		density_str = "Lively"
	elif _current_player_count < 150:
		density_str = "Bustling"
	else:
		density_str = "PACKED"

	crowd_density_label.text = "Paws Vegas — %s (%d cats)" % [density_str, _current_player_count]

	# Adjust NPC count to reflect density (clamp for performance)
	var target_npc_count: int = clamp(_current_player_count / 10, 5, 40)
	if abs(target_npc_count - _npcs.size()) > 3:
		_spawn_npcs(target_npc_count)
