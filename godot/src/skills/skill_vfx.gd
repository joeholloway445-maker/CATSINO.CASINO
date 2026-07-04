class_name SkillVFX
## One-shot skill visuals, colored by the caster's frame sensorium — your
## Bolt strike flashes white-hot, a Blight cast hazes green. All GPU
## particles + emissive meshes, auto-freed. Host scenes call these from
## their cast resolvers.

static func _tint() -> Color:
	return IdentityLens.sensorium().light

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
	col.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(c.r, c.g, c.b, 0.5)
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	col.material_override = mat
	col.position = at + Vector3(0, 7, 0)
	parent.add_child(col)
	var tw := parent.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.8)
	tw.tween_callback(col.queue_free)

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
