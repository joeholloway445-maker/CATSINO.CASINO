class_name BlueprintMesh
## Turns a blueprint's params into an actual Node3D. Weapons and armor are
## built from primitive meshes composed procedurally (SurfaceTool-free —
## primitives + transforms keep it cheap and let every param map 1:1 to a
## visible change). Entities get articulated bodies from the body-plan.
## Everything is seeded by BlueprintData.seed_of so per-blueprint detail
## (spike placement, marking pattern) is stable.

static func build(bp: Dictionary) -> Node3D:
	match bp.get("kind", ""):
		"weapon": return _weapon(bp)
		"armor": return _armor(bp)
		"entity": return _entity(bp)
		_: return Node3D.new()

## Route every blueprint surface through the viewer's race lens — the same
## "hard mesh" contract as terrain/props (AssetLibrary.material()): the
## authored base_color and intentional emission survive, but roughness/
## metalness and hue pull toward the local race's texture_type/primary_color,
## so the SAME sword/creature is a different material on every client.
static func _mat(base: Color, metallic: float, roughness: float,
		emission: float, emit_color: Color = Color.WHITE) -> StandardMaterial3D:
	var m := IdentityLens.world_material(base, 0.3) if IdentityLens else StandardMaterial3D.new()
	if not IdentityLens:
		m.albedo_color = base
	# Blend the item's own authored physicality with the lens' — a "0.9
	# metallic" sword should still read metallic even under a rough lens.
	m.metallic = clampf(lerpf(m.metallic, metallic, 0.6), 0.0, 1.0)
	m.roughness = clampf(lerpf(m.roughness, roughness, 0.6), 0.0, 1.0)
	# A thin rim light on every blueprint surface — the difference between
	## "flat Godot primitive" and "this was lit for a screenshot."
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.5
	if metallic > 0.5:
		m.clearcoat_enabled = true
		m.clearcoat = 0.5
	# Authored emission (glow edges, danger tells) always wins over the
	# lens' own texture_type emissive — gameplay legibility beats flavor.
	# Absent that, a naturally-emissive race (radiant, digital, ...) still
	# shows through, same as it would on any other piece of hard mesh.
	if emission > 0.01:
		m.emission_enabled = true
		m.emission = emit_color
		m.emission_energy_multiplier = emission
	return m

# ------------------------------------------------------------------ weapon

static func _weapon(bp: Dictionary) -> Node3D:
	var p: Dictionary = bp.params
	var root := Node3D.new()
	root.name = "WeaponBP"
	var rng := RandomNumberGenerator.new()
	rng.seed = BlueprintData.seed_of(bp)
	var body_mat := _mat(p.base_color, p.metallic, p.roughness, p.emission, p.edge_color)

	# Grip — every silhouette shares one.
	var grip := MeshInstance3D.new()
	var grip_mesh := CylinderMesh.new()
	grip_mesh.top_radius = 0.03
	grip_mesh.bottom_radius = 0.035
	grip_mesh.height = 0.3
	grip.mesh = grip_mesh
	grip.material_override = _mat(p.base_color.darkened(0.5), 0.2, 0.8, 0.0)
	root.add_child(grip)

	var segs := int(p.segments)
	match str(p.silhouette):
		"blade":
			for i in segs:
				var seg := MeshInstance3D.new()
				var box := BoxMesh.new()
				var t := float(i) / maxf(segs, 1.0)
				var w: float = p.width * lerpf(1.0, 1.0 - p.taper, t)
				box.size = Vector3(w, p.length / segs, w * 0.25)
				seg.mesh = box
				seg.material_override = body_mat
				seg.position = Vector3(p.curve * t * p.length * 0.5,
					0.2 + (t + 0.5 / segs) * p.length, 0)
				seg.rotation.z = p.curve * t * 0.8
				root.add_child(seg)
		"hammer":
			var haft := MeshInstance3D.new()
			var hm := CylinderMesh.new()
			hm.top_radius = 0.04; hm.bottom_radius = 0.04; hm.height = p.length
			haft.mesh = hm
			haft.position.y = 0.2 + p.length / 2.0
			haft.material_override = _mat(p.base_color.darkened(0.3), 0.3, 0.7, 0.0)
			root.add_child(haft)
			var head := MeshInstance3D.new()
			var hb := BoxMesh.new()
			hb.size = Vector3(p.width * 3.0, p.width * 2.0, p.width * 2.0)
			head.mesh = hb
			head.position.y = 0.2 + p.length
			head.material_override = body_mat
			root.add_child(head)
		"staff":
			var shaft := MeshInstance3D.new()
			var sm := CylinderMesh.new()
			sm.top_radius = p.width * 0.3; sm.bottom_radius = p.width * 0.4
			sm.height = p.length * 1.4
			shaft.mesh = sm
			shaft.position.y = 0.2 + p.length * 0.7
			shaft.material_override = body_mat
			root.add_child(shaft)
			var orb := MeshInstance3D.new()
			var om := SphereMesh.new()
			om.radius = p.width * 1.2; om.height = p.width * 2.4
			orb.mesh = om
			orb.position.y = 0.2 + p.length * 1.4 + p.width
			orb.material_override = _mat(p.edge_color, 0.1, 0.1, maxf(p.emission, 1.0), p.edge_color)
			root.add_child(orb)
		"claw":
			for i in maxi(segs, 3):
				var talon := MeshInstance3D.new()
				var tm := CylinderMesh.new()
				tm.top_radius = 0.0; tm.bottom_radius = p.width * 0.4
				tm.height = p.length * 0.6
				talon.mesh = tm
				talon.material_override = body_mat
				var spread: float = (float(i) - (maxi(segs, 3) - 1) / 2.0) * 0.08
				talon.position = Vector3(spread, 0.35 + p.length * 0.3, 0)
				talon.rotation.z = -spread * 2.0 + p.curve
				root.add_child(talon)
		"lash":
			for i in 8:
				var link := MeshInstance3D.new()
				var lm := SphereMesh.new()
				var t := float(i) / 8.0
				lm.radius = p.width * lerpf(0.5, 0.5 * (1.0 - p.taper), t)
				lm.height = lm.radius * 2.0
				link.mesh = lm
				link.material_override = body_mat
				link.position = Vector3(sin(t * TAU * p.curve * 2.0) * 0.2,
					0.25 + t * p.length, 0)
				root.add_child(link)
		"orbitals":
			for i in maxi(segs, 3):
				var shard := MeshInstance3D.new()
				var pm := PrismMesh.new()
				pm.size = Vector3(p.width, p.length * 0.35, p.width * 0.4)
				shard.mesh = pm
				shard.material_override = _mat(p.edge_color, p.metallic, p.roughness,
					maxf(p.emission, 1.5), p.edge_color)
				var ang := TAU * float(i) / maxi(segs, 3)
				shard.position = Vector3(cos(ang) * 0.35, 0.5, sin(ang) * 0.35)
				shard.rotation.y = -ang
				root.add_child(shard)
	return root

# ------------------------------------------------------------------- armor

static func _armor(bp: Dictionary) -> Node3D:
	var p: Dictionary = bp.params
	var root := Node3D.new()
	root.name = "ArmorBP"
	var rng := RandomNumberGenerator.new()
	rng.seed = BlueprintData.seed_of(bp)
	var mat := _mat(p.base_color, p.metallic, p.roughness + p.wear * 0.3,
		p.emission, p.accent_color)

	# Torso shell — bulk widens it, coverage extends it downward.
	var torso := MeshInstance3D.new()
	var tm := CapsuleMesh.new()
	tm.radius = 0.28 + p.bulk * 0.12
	tm.height = 0.5 + p.coverage * 0.5
	torso.mesh = tm
	torso.material_override = mat
	torso.position.y = 1.2
	root.add_child(torso)

	# Pauldrons scale with bulk; style comes from silhouette.
	for side in [-1.0, 1.0]:
		var pauldron := MeshInstance3D.new()
		match str(p.silhouette):
			"plate", "shell":
				var sm := SphereMesh.new()
				sm.radius = 0.12 + p.bulk * 0.1
				sm.height = sm.radius
				pauldron.mesh = sm
			"scale", "bone":
				var pm := PrismMesh.new()
				pm.size = Vector3(0.2 + p.bulk * 0.15, 0.12, 0.2)
				pauldron.mesh = pm
			_:
				var bm := BoxMesh.new()
				bm.size = Vector3(0.18, 0.08, 0.18) * (1.0 + p.bulk)
				pauldron.mesh = bm
		pauldron.material_override = mat
		pauldron.position = Vector3(side * (0.3 + p.bulk * 0.12), 1.55, 0)
		root.add_child(pauldron)

	# Spikes: count and placement seeded per blueprint.
	var spike_count := int(p.spikes * 6.0)
	for i in spike_count:
		var spike := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.03
		cm.height = 0.1 + p.spikes * 0.15
		spike.mesh = cm
		spike.material_override = _mat(p.accent_color, p.metallic, 0.3, p.emission, p.accent_color)
		var ang := rng.randf() * TAU
		spike.position = Vector3(cos(ang) * 0.3, 1.3 + rng.randf() * 0.4, sin(ang) * 0.3)
		spike.rotation = Vector3(rng.randf() - 0.5, 0, rng.randf() - 0.5)
		root.add_child(spike)

	if str(p.silhouette) == "aura":
		# Aura armor is barely-there: ethereal shell instead of solid metal.
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.35
		mat.emission_enabled = true
		mat.emission = p.accent_color
		mat.emission_energy_multiplier = maxf(p.emission, 1.0)
	return root

# ------------------------------------------------------------------ entity

static func _entity(bp: Dictionary) -> Node3D:
	var p: Dictionary = bp.params
	var root := Node3D.new()
	root.name = "EntityBP"
	var rng := RandomNumberGenerator.new()
	rng.seed = BlueprintData.seed_of(bp)
	var hide := _mat(p.base_color, 0.0, 0.8 - p.fur * 0.3, p.ethereal * 1.5, p.glow_color)
	if p.ethereal > 0.4:
		hide.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		hide.albedo_color.a = 1.0 - p.ethereal * 0.6

	var s: float = p.size
	match str(p.body):
		"quadruped", "biped":
			var body := MeshInstance3D.new()
			var bm := CapsuleMesh.new()
			bm.radius = 0.25 * s
			bm.height = 0.9 * s
			body.mesh = bm
			body.material_override = hide
			var upright := str(p.body) == "biped"
			body.rotation.x = 0.0 if upright else PI / 2.0
			body.position.y = (0.8 if upright else 0.5) * s
			root.add_child(body)
			var legs := 2 if upright else 4
			for i in legs:
				var leg := MeshInstance3D.new()
				var lm := CylinderMesh.new()
				lm.top_radius = 0.06 * s
				lm.bottom_radius = 0.05 * s
				lm.height = 0.5 * s * p.limb_length
				leg.mesh = lm
				leg.material_override = hide
				var lx := (0.12 if upright else 0.15) * s * (1 if i % 2 == 0 else -1)
				var lz := 0.0 if upright else 0.3 * s * (1 if i < 2 else -1)
				leg.position = Vector3(lx, 0.25 * s * p.limb_length, lz)
				root.add_child(leg)
		"serpent":
			for i in 9:
				var seg := MeshInstance3D.new()
				var sm := SphereMesh.new()
				var t := float(i) / 9.0
				sm.radius = 0.2 * s * (1.0 - t * 0.6)
				sm.height = sm.radius * 2.0
				seg.mesh = sm
				seg.material_override = hide
				seg.position = Vector3(sin(t * TAU) * 0.3 * s, 0.2 * s, -t * 1.2 * s)
				root.add_child(seg)
		"avian":
			var body := MeshInstance3D.new()
			var am := SphereMesh.new()
			am.radius = 0.25 * s
			am.height = 0.6 * s
			body.mesh = am
			body.material_override = hide
			body.position.y = 0.8 * s
			root.add_child(body)
			for side in [-1.0, 1.0]:
				var wing := MeshInstance3D.new()
				var wm := PrismMesh.new()
				wm.size = Vector3(0.7 * s * p.limb_length, 0.05 * s, 0.35 * s)
				wing.mesh = wm
				wing.material_override = hide
				wing.position = Vector3(side * 0.45 * s * p.limb_length, 0.85 * s, 0)
				wing.rotation.z = side * 0.3
				root.add_child(wing)
		"floating":
			var core := MeshInstance3D.new()
			var cm := SphereMesh.new()
			cm.radius = 0.3 * s
			cm.height = 0.6 * s
			core.mesh = cm
			core.material_override = _mat(p.glow_color, 0.0, 0.1, 2.0, p.glow_color)
			core.position.y = 1.0 * s
			root.add_child(core)
			for i in 3 + int(p.fur * 4.0):
				var mote := MeshInstance3D.new()
				var mm := SphereMesh.new()
				mm.radius = 0.05 * s
				mm.height = 0.1 * s
				mote.mesh = mm
				mote.material_override = hide
				var ang := rng.randf() * TAU
				mote.position = Vector3(cos(ang) * 0.5 * s, 1.0 * s + rng.randf_range(-0.2, 0.3) * s, sin(ang) * 0.5 * s)
				root.add_child(mote)
		"swarm":
			for i in 12:
				var unit := MeshInstance3D.new()
				var um := BoxMesh.new()
				um.size = Vector3.ONE * 0.08 * s
				unit.mesh = um
				unit.material_override = hide
				unit.position = Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(0.2, 1.0), rng.randf_range(-0.4, 0.4)) * s
				root.add_child(unit)

	# Head + glow eyes for anything with a front.
	if str(p.body) in ["quadruped", "biped", "serpent", "avian"]:
		var head := MeshInstance3D.new()
		var hm := SphereMesh.new()
		hm.radius = 0.15 * s * p.head_scale
		hm.height = hm.radius * 2.0
		head.mesh = hm
		head.material_override = hide
		head.position = Vector3(0, (1.1 if str(p.body) == "biped" else 0.6) * s, 0.45 * s)
		root.add_child(head)
		for side in [-1.0, 1.0]:
			var eye := MeshInstance3D.new()
			var em := SphereMesh.new()
			em.radius = 0.03 * s * p.head_scale
			em.height = em.radius * 2.0
			eye.mesh = em
			eye.material_override = _mat(p.glow_color, 0.0, 0.0, 3.0, p.glow_color)
			eye.position = head.position + Vector3(side * 0.06 * s, 0.03 * s, 0.12 * s * p.head_scale)
			root.add_child(eye)

	# Markings: seeded patches of the marking color.
	for i in int(p.fur * 5.0):
		var patch := MeshInstance3D.new()
		var pm := SphereMesh.new()
		pm.radius = 0.08 * s
		pm.height = 0.05 * s
		patch.mesh = pm
		patch.material_override = _mat(p.marking_color, 0.0, 0.9, 0.0)
		patch.position = Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0.3, 0.8), rng.randf_range(-0.4, 0.4)) * s
		root.add_child(patch)
	return root
