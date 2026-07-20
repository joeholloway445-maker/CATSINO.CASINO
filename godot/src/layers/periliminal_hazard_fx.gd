class_name PeriliminalHazardFX
## Gate 6 juice for Hope-driven Periliminal floors: readable ground ambience
## per hazard type + tick pulses when damage lands. LayerWorld owns lifetime;
## this class only builds / frees visual nodes (SkillVFX pattern).

const ROOT_NAME := "PeriliminalHazardFX"
const HUD_NAME := "PeriliminalFloorHud"

## Palette + short player-facing label per generator hazard type.
static func profile(kind: String) -> Dictionary:
	match kind:
		"damage_floor":
			return {
				"label": "Scorching Floor",
				"color": Color(1.0, 0.32, 0.12),
				"pulse": "hot",
			}
		"unstable_floor":
			return {
				"label": "Unstable Ground",
				"color": Color(1.0, 0.78, 0.22),
				"pulse": "slip",
			}
		"knowledge_cost":
			return {
				"label": "Forbidden Knowledge",
				"color": Color(0.62, 0.35, 1.0),
				"pulse": "mind",
			}
		"environmental_danger":
			return {
				"label": "Toxic Pressure",
				"color": Color(0.28, 0.95, 0.42),
				"pulse": "gas",
			}
		"psychological_pressure":
			return {
				"label": "Personified Terror",
				"color": Color(0.55, 0.12, 0.72),
				"pulse": "fear",
			}
		"hollow_satisfaction":
			return {
				"label": "Hollow Desire",
				"color": Color(1.0, 0.45, 0.72),
				"pulse": "lure",
			}
		"temporal_stasis":
			return {
				"label": "Temporal Stasis",
				"color": Color(0.55, 0.72, 0.85),
				"pulse": "stasis",
			}
		"moral_dilemma":
			return {
				"label": "Moral Weight",
				"color": Color(0.95, 0.88, 0.55),
				"pulse": "guilt",
			}
		_:
			return {
				"label": kind.replace("_", " ").capitalize(),
				"color": Color(0.85, 0.55, 0.95),
				"pulse": "generic",
			}

static func summarize_hazards(hazards: Array) -> String:
	if hazards.is_empty():
		return "No active hazards"
	var parts: PackedStringArray = []
	for hz in hazards:
		if not hz is Dictionary:
			continue
		var kind := str(hz.get("type", ""))
		if kind.is_empty():
			continue
		parts.append(str(profile(kind).get("label", kind)))
	if parts.is_empty():
		return "No active hazards"
	return ", ".join(parts)

## Rebuild persistent floor ambience. Prefer parenting under `follow` so the
## trap stays underfoot; fall back to `host` when the player isn't ready yet.
static func apply_floor(host: Node3D, follow: Node3D, hazards: Array) -> void:
	clear(host)
	clear(follow)
	if host == null or not is_instance_valid(host) or hazards.is_empty():
		return
	var anchor: Node3D = follow if follow != null and is_instance_valid(follow) else host
	var root := Node3D.new()
	root.name = ROOT_NAME
	anchor.add_child(root)
	var i := 0
	for hz in hazards:
		if not hz is Dictionary:
			continue
		var kind := str(hz.get("type", ""))
		if kind.is_empty():
			continue
		var info: Dictionary = profile(kind)
		var tint: Color = info.get("color", Color.WHITE)
		_spawn_disk(root, tint, 3.2 + float(i) * 0.55, 0.08 + float(i) * 0.02)
		_spawn_haze(root, tint, kind)
		i += 1
	# Entry telegraph — one expanding ring so the floor change is felt.
	var lead: Dictionary = hazards[0] if hazards[0] is Dictionary else {}
	var lead_kind := str(lead.get("type", "damage_floor"))
	var lead_c: Color = profile(lead_kind).get("color", Color.WHITE)
	var at := Vector3.ZERO
	if follow != null and is_instance_valid(follow):
		at = follow.global_position
	elif host != null:
		at = host.global_position
	SkillVFX.aoe_ring(host, at, 4.5, lead_c)

## One-shot juice when a hazard deals damage this second.
static func pulse_tick(host: Node3D, follow: Node3D, hazard: Dictionary, damage: int) -> void:
	if host == null or not is_instance_valid(host) or damage <= 0:
		return
	var kind := str(hazard.get("type", ""))
	var info: Dictionary = profile(kind)
	var tint: Color = info.get("color", Color.WHITE)
	var at := Vector3.ZERO
	if follow != null and is_instance_valid(follow):
		at = follow.global_position
	match str(info.get("pulse", "generic")):
		"hot":
			SkillVFX.aoe_ring(host, at, 2.2, tint)
			SkillVFX.hit_spark(host, at)
		"slip":
			SkillVFX.aoe_ring(host, at, 1.6, tint)
		"gas", "fear", "lure", "guilt", "mind":
			SkillVFX.aoe_ring(host, at, 2.0, tint)
			_brief_particles(host, at + Vector3(0, 1.1, 0), tint, 18)
		"stasis":
			SkillVFX.aoe_ring(host, at, 1.4, tint)
			_brief_particles(host, at + Vector3(0, 0.6, 0), tint, 10)
		_:
			SkillVFX.aoe_ring(host, at, 1.8, tint)

static func clear(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var existing := node.get_node_or_null(ROOT_NAME)
	if existing != null:
		existing.queue_free()

## Build / refresh the floor HUD panel under a CanvasLayer.
static func ensure_hud(layer: CanvasLayer) -> PanelContainer:
	if layer == null or not is_instance_valid(layer):
		return null
	var existing := layer.get_node_or_null(HUD_NAME)
	if existing is PanelContainer:
		return existing as PanelContainer
	var panel := PanelContainer.new()
	panel.name = HUD_NAME
	panel.visible = false
	panel.position = Vector2(10, 140)
	panel.custom_minimum_size = Vector2(280, 0)
	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "Body"
	margin.add_child(vbox)
	var title := Label.new()
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title)
	var traps := Label.new()
	traps.name = "Hazards"
	traps.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	traps.modulate = Color(0.85, 0.82, 0.95)
	vbox.add_child(traps)
	var exit_lbl := Label.new()
	exit_lbl.name = "Exit"
	exit_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exit_lbl.modulate = Color(0.7, 0.9, 0.75)
	vbox.add_child(exit_lbl)
	var tick := Label.new()
	tick.name = "Tick"
	tick.modulate = Color(1.0, 0.55, 0.45)
	vbox.add_child(tick)
	layer.add_child(panel)
	return panel

static func refresh_hud(panel: PanelContainer, floor_data: Dictionary, depth: int, last_tick_dmg: int = 0) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	if floor_data.is_empty():
		panel.visible = false
		return
	panel.visible = true
	var trap := str(floor_data.get("trap_type", "unknown")).replace("_", " ")
	var body := _hud_body(panel)
	if body == null:
		return
	var title := body.get_node_or_null("Title") as Label
	var hazards_lbl := body.get_node_or_null("Hazards") as Label
	var exit_lbl := body.get_node_or_null("Exit") as Label
	var tick_lbl := body.get_node_or_null("Tick") as Label
	var hazards: Array = floor_data.get("hazards", [])
	var lead_kind := ""
	if not hazards.is_empty() and hazards[0] is Dictionary:
		lead_kind = str(hazards[0].get("type", ""))
	var tint: Color = Color(0.85, 0.55, 0.95)
	if not lead_kind.is_empty():
		tint = profile(lead_kind).get("color", tint)
	if title:
		title.text = "Floor %d — %s" % [depth, trap.capitalize()]
		title.modulate = tint
	if hazards_lbl:
		hazards_lbl.text = "Hazards: %s" % summarize_hazards(hazards)
	if exit_lbl:
		var exits: Array = floor_data.get("exits", [])
		if exits.is_empty():
			exit_lbl.text = "Exit: unknown"
		else:
			exit_lbl.text = "Exit: %s" % str(exits[0]).replace("_", " ")
	if tick_lbl:
		if last_tick_dmg > 0:
			tick_lbl.text = "Pressure −%d this second" % last_tick_dmg
			tick_lbl.visible = true
		else:
			tick_lbl.text = ""
			tick_lbl.visible = false

static func _hud_body(panel: PanelContainer) -> VBoxContainer:
	for child in panel.get_children():
		if child is MarginContainer:
			return child.get_node_or_null("Body") as VBoxContainer
	return null

static func _spawn_disk(root: Node3D, tint: Color, radius: float, y_off: float) -> void:
	var disk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.06
	cyl.radial_segments = 28
	disk.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.22)
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 1.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	disk.material_override = mat
	disk.position = Vector3(0, y_off, 0)
	root.add_child(disk)

static func _spawn_haze(root: Node3D, tint: Color, kind: String) -> void:
	var p := GPUParticles3D.new()
	p.amount = 28 if kind != "temporal_stasis" else 12
	p.lifetime = 2.2
	p.position = Vector3(0, 0.4, 0)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 80.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.55
	pm.gravity = Vector3(0, 0.4 if kind != "temporal_stasis" else -0.1, 0)
	pm.scale_min = 0.04
	pm.scale_max = 0.11
	pm.color = Color(tint.r, tint.g, tint.b, 0.75)
	p.process_material = pm
	var mesh := SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 1.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.55)
	mesh.material = mat
	p.draw_pass_1 = mesh
	p.emitting = true
	root.add_child(p)

static func _brief_particles(host: Node3D, at: Vector3, tint: Color, amount: int) -> void:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 1.0
	p.position = at
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 70.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 2.4
	pm.gravity = Vector3(0, -2.0, 0)
	pm.scale_min = 0.04
	pm.scale_max = 0.1
	pm.color = tint
	p.process_material = pm
	var mesh := SphereMesh.new()
	mesh.radius = 0.045
	mesh.height = 0.09
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 2.2
	mesh.material = mat
	p.draw_pass_1 = mesh
	host.add_child(p)
	p.emitting = true
	var pid := p.get_instance_id()
	var tree := host.get_tree()
	if tree != null:
		tree.create_timer(0.9).timeout.connect(func():
			var n := instance_from_id(pid)
			if n != null:
				n.queue_free())
