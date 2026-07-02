extends Node3D
## The PVXC floor — a survival crater sunk into the casino. Ark-styled:
## harvestable resource nodes, roaming hostile creatures (rolled from the
## entity roster), extraction gates on the rim, and the permanently RED
## CORE at dead center where everything pays 12x and the light never stops
## being wrong. Reuses the overworld kit; the sky here ignores day/night —
## the casino has no sun, the PVXC has no mercy.

const RIM := PvxcManager.ZONE_RADIUS
const CORE := PvxcManager.RED_CORE_RADIUS
const HARVEST_NODES := 40
const CREATURES := 12
const GATES := 4

var _player: ThirdPersonController
var _hud_mult: Label
var _hud_loot: Label
var _core_light: OmniLight3D

func _ready() -> void:
	if not PvxcManager.in_run:
		# No stake, no entry — bounce to the gate UI.
		get_tree().change_scene_to_file.call_deferred("res://scenes/pvxc/pvxc_gate.tscn")
		return
	_build_arena()
	_player = ThirdPersonController.new()
	add_child(_player)
	_player.global_position = Vector3(RIM - 10.0, 3.0, 0)
	add_child(SensoriumAmbience.new())
	# No track here on purpose: the PVXC gets your build's hum and a pulse,
	# nothing comforting. (MusicManager fades out via the empty context.)
	MusicManager.play_context("pvxc")
	_build_hud()

func _build_arena() -> void:
	# Environment: windowless casino-basement dark, red bleed from the core.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.01, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.1, 0.12)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.2, 0.04, 0.06)
	env.fog_density = 0.015
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# Crater floor (hard mesh — renders through the race lens like all of it).
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = RIM
	floor_mesh.bottom_radius = RIM
	floor_mesh.height = 1.0
	var floor_mi := MeshInstance3D.new()
	floor_mi.mesh = floor_mesh
	floor_mi.position.y = -0.5
	floor_mi.material_override = IdentityLens.world_material(Color(0.2, 0.12, 0.1))
	add_child(floor_mi)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = RIM
	cyl.height = 1.0
	shape.shape = cyl
	shape.position.y = -0.5
	body.add_child(shape)
	add_child(body)

	# The RED CORE — a permanent warning you can see from anywhere.
	var core_ring := TorusMesh.new()
	core_ring.inner_radius = CORE - 1.0
	core_ring.outer_radius = CORE
	var ring_mi := MeshInstance3D.new()
	ring_mi.mesh = core_ring
	ring_mi.position.y = 0.1
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1, 0, 0.05)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1, 0, 0.05)
	ring_mat.emission_energy_multiplier = 2.0
	ring_mi.material_override = ring_mat
	add_child(ring_mi)

	_core_light = OmniLight3D.new()
	_core_light.light_color = Color(1, 0.05, 0.1)
	_core_light.omni_range = CORE * 3.0
	_core_light.light_energy = 3.0
	_core_light.position.y = 8.0
	add_child(_core_light)

	# Harvest nodes — denser toward the core (risk gradient IS the loot map).
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x50565843 # "PVXC"
	for i in range(HARVEST_NODES):
		var pull := rng.randf() # bias toward center
		var r := lerpf(CORE * 0.3, RIM * 0.95, pull * pull)
		var a := rng.randf() * TAU
		_spawn_harvest_node(Vector3(cos(a) * r, 0, sin(a) * r), rng)

	# Hostile creatures from the FULL roster — the PVXC doesn't respect
	# faction access; everything in here wants your loot.
	for i in range(CREATURES):
		var a := rng.randf() * TAU
		var r := rng.randf_range(CORE, RIM * 0.9)
		_spawn_creature(Vector3(cos(a) * r, 0, sin(a) * r), rng)

	# Extraction gates on the rim — green, obvious, far from the good loot.
	for i in range(GATES):
		var a := TAU * i / GATES
		_spawn_gate(Vector3(cos(a) * (RIM - 3.0), 0, sin(a) * (RIM - 3.0)))

func _spawn_harvest_node(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var node := Area3D.new()
	var mi := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(1.0, rng.randf_range(1.2, 2.4), 1.0)
	mi.mesh = prism
	var in_core := Vector2(pos.x, pos.z).length() <= CORE
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.15, 0.2) if in_core else Color(0.9, 0.75, 0.3)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.8
	mi.material_override = mat
	node.add_child(mi)
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 2.0
	cs.shape = sph
	node.add_child(cs)
	node.position = pos
	var base_value := rng.randi_range(20, 60)
	node.body_entered.connect(func(b):
		if b is ThirdPersonController and PvxcManager.in_run:
			PvxcManager.collect(base_value, node.global_position)
			NotificationUI.notify_info("⛏️ +%d loot (x%d zone)" % [
				int(base_value * PvxcManager.mult_at(node.global_position)),
				int(PvxcManager.mult_at(node.global_position))])
			node.queue_free())
	add_child(node)

func _spawn_creature(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var roster := CompanionRegistry.get_all()
	if roster.is_empty():
		return
	var entity: Dictionary = roster[rng.randi() % roster.size()]
	var mi := MeshInstance3D.new()
	var caps := CapsuleMesh.new()
	caps.radius = 0.5
	caps.height = 1.6
	mi.mesh = caps
	# Wild PVXC creatures render through your lens WITH perception — strong
	# ones loom at you before you ever read their stats.
	var profile := {"level": int(entity.get("rarity", 1)) * 15, "faction": entity.get("faction", ""),
		"alignment": "feral", "stats": {"pow": entity.get("pow", 50)}}
	var seen: Dictionary = IdentityLens.perceive_being(profile, Color(0.6, 0.3, 0.3))
	mi.material_override = seen.material
	mi.scale = Vector3.ONE * seen.scale
	mi.position = pos + Vector3(0, 1.0, 0)
	mi.set_meta("entity_id", entity.get("id", ""))
	add_child(mi)

func _spawn_gate(pos: Vector3) -> void:
	var gate := Area3D.new()
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3, 5, 0.5)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 1.0, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 1.0, 0.4)
	mat.emission_energy_multiplier = 1.5
	mi.material_override = mat
	mi.position.y = 2.5
	gate.add_child(mi)
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(4, 6, 2)
	cs.shape = bx
	cs.position.y = 2.5
	gate.add_child(cs)
	gate.position = pos
	gate.body_entered.connect(func(b):
		if b is ThirdPersonController and PvxcManager.in_run:
			PvxcManager.extract()
			MusicManager.exit_racing() # restore layer music
			get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	add_child(gate)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud_mult = Label.new()
	_hud_mult.position = Vector2(10, 10)
	_hud_mult.add_theme_font_size_override("font_size", 20)
	layer.add_child(_hud_mult)
	_hud_loot = Label.new()
	_hud_loot.position = Vector2(10, 40)
	layer.add_child(_hud_loot)
	var target := Label.new()
	target.position = Vector2(10, 64)
	target.modulate = Color(1, 0.4, 0.4)
	var t := PvxcManager.my_target()
	target.text = "⚔️ Revenge target inside: %s" % t if t != "" else ""
	layer.add_child(target)

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var m := PvxcManager.mult_at(_player.global_position)
	var red := PvxcManager.in_red_core(_player.global_position)
	_hud_mult.text = "🔴 RED CORE — x12" if red else "PVXC — x%d" % int(m)
	_hud_mult.modulate = Color(1, 0.15, 0.2) if red else Color(1, 0.8, 0.3)
	_hud_loot.text = "Carried loot: %d  (die and it's the house's)" % PvxcManager.carried_loot
	if is_instance_valid(_core_light):
		_core_light.light_energy = 3.0 + sin(Time.get_ticks_msec() / 300.0) * 1.2
