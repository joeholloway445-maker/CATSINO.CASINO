class_name SkillVFX
## One-shot skill visuals, colored by the caster's frame sensorium — your
## Bolt strike flashes white-hot, a Blight cast hazes green. All GPU
## particles + emissive meshes, auto-freed. Host scenes call these from
## their cast resolvers.

static func _tint() -> Color:
	var lens := AutoloadGate.get_node("IdentityLens")
	if lens == null or not lens.has_method("sensorium"):
		return Color.WHITE
	var senso: Variant = lens.call("sensorium")
	if senso is Dictionary:
		return senso.get("light", Color.WHITE)
	return Color.WHITE

## Quick burst at the caster on any cast.
static func cast_flash(parent: Node3D, at: Vector3) -> void:
	var p := _particles(parent, at + Vector3(0, 1.2, 0), 24, 0.5, _tint(), 2.0)
	p.one_shot = true

## Expanding ground ring for AoE skills.
static func aoe_ring(parent: Node3D, at: Vector3, radius: float, color: Color = Color.TRANSPARENT) -> void:
	var c := color if color.a > 0.0 else _tint()
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.1
	torus.outer_radius = 0.3
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 2.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat
	ring.position = at + Vector3(0, 0.15, 0)
	parent.add_child(ring)
	var tw := parent.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(radius * 3.3, 1.0, radius * 3.3), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.45)
	tw.chain().tween_callback(ring.queue_free)

## Beam for line skills.
static func line_beam(parent: Node3D, from: Vector3, dir: Vector3, length: float) -> void:
	var c := _tint()
	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.12
	cyl.height = length
	beam.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = mat
	beam.position = from + Vector3(0, 1.2, 0) + dir * (length / 2.0)
	beam.rotation = Vector3(PI / 2.0, atan2(dir.x, dir.z), 0)
	parent.add_child(beam)
	var tw := parent.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tw.tween_callback(beam.queue_free)

## Bubble for shields; lingers while the shield holds (caller frees early
## if broken — it self-frees after `duration`).
static func shield_bubble(parent: Node3D, follow: Node3D, duration: float = 6.0) -> void:
	var c := _tint()
	var bub := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 1.4
	sph.height = 2.8
	bub.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(c.r, c.g, c.b, 0.18)
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 0.6
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	bub.material_override = mat
	bub.position.y = 1.1
	follow.add_child(bub)
	follow.get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(bub): bub.queue_free())

## Big vertical column + shockwave for ultimates.
## A reality-tear pillar, not a particle puff — the holographic shader
## gives it scanlines + rim + flicker instead of a flat emissive cylinder.
static func ultimate_burst(parent: Node3D, at: Vector3, radius: float) -> void:
	var c := _tint()
	aoe_ring(parent, at, radius, c)
	var p := _particles(parent, at, 160, 1.2, c, 6.0)
	p.one_shot = true
	var col := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.8
	cyl.bottom_radius = 1.6
	cyl.height = 14.0
	cyl.radial_segments = 24
	col.mesh = cyl
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/holographic.gdshader")
	mat.set_shader_parameter("base_color", Color(c.r, c.g, c.b, 0.65))
	mat.set_shader_parameter("scan_speed", 3.0)
	mat.set_shader_parameter("rim_power", 2.0)
	col.material_override = mat
	col.position = at + Vector3(0, 7, 0)
	parent.add_child(col)
	var tw := parent.create_tween()
	tw.tween_method(func(a: float): mat.set_shader_parameter("base_color", Color(c.r, c.g, c.b, a)),
		0.65, 0.0, 0.8)
	tw.tween_callback(col.queue_free)

## Renders a cast styled by a player skill-blueprint from the Forge —
## shape_style, colors, density and scale all come from the blueprint, and
## its synthesized sound signature plays alongside. Falls back to nothing
## exotic if params are missing (clamp_params guarantees defaults anyway).
static func blueprint_cast(parent: Node3D, at: Vector3, bp: Dictionary) -> void:
	var p: Dictionary = bp.get("params", {})
	var c1: Color = p.get("primary_color", _tint())
	var c2: Color = p.get("secondary_color", Color.WHITE)
	var scale: float = float(p.get("scale", 1.0))
	var density: float = float(p.get("particle_density", 1.0))
	var turb: float = float(p.get("turbulence", 0.3))
	var afterglow: float = float(p.get("afterglow", 0.6))
	match str(p.get("shape_style", "ring")):
		"ring":
			aoe_ring(parent, at, 2.0 * scale, c1)
		"burst":
			var b := _particles(parent, at + Vector3(0, 1.0, 0), int(40 * density), 0.5 + afterglow * 0.4, c1, 4.0 * scale)
			b.one_shot = true
		"spiral":
			for i in 3:
				var s := _particles(parent, at + Vector3(0, 0.4 + i * 0.5, 0), int(18 * density), 0.7, c1.lerp(c2, i / 3.0), 2.0 * scale)
				s.one_shot = true
				(s.process_material as ParticleProcessMaterial).orbit_velocity_min = 0.6 + turb
				(s.process_material as ParticleProcessMaterial).orbit_velocity_max = 1.2 + turb
		"shards":
			for i in int(5 * density):
				var ang := TAU * i / maxf(5 * density, 1.0)
				line_beam(parent, at + Vector3(cos(ang), 0, sin(ang)) * 0.3, Vector3(cos(ang), 0.1, sin(ang)), 2.5 * scale)
		"wave":
			aoe_ring(parent, at, 1.2 * scale, c1)
			aoe_ring(parent, at, 2.4 * scale, c2)
		"sigil":
			aoe_ring(parent, at, 1.0 * scale, c1)
			var g := _particles(parent, at + Vector3(0, 0.2, 0), int(30 * density), 0.9 + afterglow, c2, 0.8)
			g.one_shot = true
			(g.process_material as ParticleProcessMaterial).gravity = Vector3(0, 1.5, 0)
	BlueprintAudio.play(parent, bp)

## Wraps a shimmering aura shell around a Node3D's visible mesh — the
## cat_aura shader inflates a duplicate of every MeshInstance3D found
## under `root` outward along its own normals and pulses it additively.
## Used for Hope's manifestations and apex-stage (Stage 3) world entities
## — a genuine visual "this one is different," not just a bigger number.
static func add_aura_shell(root: Node3D, color: Color, size: float = 0.06) -> void:
	var shader := load("res://assets/shaders/cat_aura.gdshader")
	for child in root.get_children():
		if child is MeshInstance3D and child.mesh != null:
			var shell := MeshInstance3D.new()
			shell.mesh = child.mesh
			shell.transform = child.transform
			var mat := ShaderMaterial.new()
			mat.shader = shader
			mat.set_shader_parameter("aura_color", Color(color.r, color.g, color.b, 1.0))
			mat.set_shader_parameter("aura_size", size)
			shell.material_override = mat
			child.add_child(shell)

## Impact puff on a target.
static func hit_spark(parent: Node3D, at: Vector3) -> void:
	var p := _particles(parent, at + Vector3(0, 1.0, 0), 16, 0.35, Color(1.0, 0.8, 0.4), 3.0)
	p.one_shot = true

static func _particles(parent: Node3D, at: Vector3, amount: int, life: float, color: Color, speed: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 1.0
	p.position = at
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 70.0
	pm.initial_velocity_min = speed * 0.5
	pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, -3, 0)
	pm.scale_min = 0.04
	pm.scale_max = 0.12
	pm.color = color
	p.process_material = pm
	var mesh := SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.5
	mesh.material = mat
	p.draw_pass_1 = mesh
	parent.add_child(p)
	p.emitting = true
	parent.get_tree().create_timer(life + 0.5).timeout.connect(func():
		if is_instance_valid(p): p.queue_free())
	return p
