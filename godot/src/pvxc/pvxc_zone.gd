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

const PLAYER_MAX_HP := 100
const ATTACK_RANGE := 3.0
const ATTACK_COOLDOWN := 0.6

var _player: ThirdPersonController
var _hud_mult: Label
var _hud_loot: Label
var _hud_hp: Label
var _hud_phase: Label
var _core_light: OmniLight3D
var _creatures: Array[PvxcCreature] = []
var _player_hp := PLAYER_MAX_HP
var _shield := 0
var _attack_cd := 0.0
var _attack_damage := 20
var _attack_damage_base := 20
var _peers: Dictionary = {} # peer_id -> RemotePlayer
var _peer_hp: Dictionary = {}
var _presence_wired := false

func _ready() -> void:
	if not PvxcManager.in_run:
		# No stake, no entry — bounce to the gate UI.
		get_tree().change_scene_to_file.call_deferred("res://scenes/pvxc/pvxc_gate.tscn")
		return
	_build_arena()
	_player = ThirdPersonController.new()
	add_child(_player)
	_player.global_position = Vector3(RIM - 10.0, 3.0, 0)
	# Match the live global phase on entry (cats in PvE, identity in PvP).
	_apply_phase(PvxcManager.combat_phase, false)
	PvxcManager.phase_changed.connect(_on_phase_changed)
	# Player attack power scales with build + entities.
	var stats := CharacterCreatorLogic.build_starting_stats(
		PlayerProfile.selected_race_id, PlayerProfile.faction,
		PlayerProfile.selected_frame, PlayerProfile.selected_mod)
	_attack_damage = 14 + int(stats.pow) / 2 + PlayerProfile.level
	_attack_damage_base = _attack_damage
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 0x50565844
	for i in range(CREATURES):
		var a := rng2.randf() * TAU
		var r := rng2.randf_range(CORE, RIM * 0.9)
		_spawn_creature(Vector3(cos(a) * r, 0, sin(a) * r), rng2)
	add_child(SensoriumAmbience.new())
	# No track here on purpose: the PVXC gets your build's hum and a pulse,
	# nothing comforting. (MusicManager fades out via the empty context.)
	MusicManager.play_context("pvxc")
	var hotbar := HotbarUI.new()
	hotbar.cast_requested.connect(_on_cast)
	add_child(hotbar)
	_build_hud()
	_set_creatures_active(not PvxcManager.is_pvp_phase())
	if PvxcManager.is_pvp_phase():
		_ensure_presence()

func _on_phase_changed(phase: String) -> void:
	_apply_phase(phase, true)

func _apply_phase(phase: String, announce_fx: bool) -> void:
	var pvp := phase == "pvp"
	if is_instance_valid(_player):
		_player.set_visual_mode("identity" if pvp else "cat")
	_set_creatures_active(not pvp)
	for pid in _peers.keys():
		var rp: RemotePlayer = _peers[pid]
		if is_instance_valid(rp):
			rp.set_visual_mode("identity" if pvp else "cat")
	if pvp:
		_ensure_presence()
	if announce_fx and is_instance_valid(_player):
		SkillVFX.aoe_ring(self, _player.global_position, 3.5,
			Color(1.0, 0.2, 0.25) if pvp else Color(1.0, 0.7, 0.3))

func _set_creatures_active(active: bool) -> void:
	for c in _creatures:
		if not is_instance_valid(c):
			continue
		c.visible = active
		c.set_process(active)
		c.set_physics_process(active)
		# Park wildlife during PvP so the floor is for fighters.
		if not active:
			c.global_position.y = -20.0
		elif c.global_position.y < -5.0:
			c.global_position.y = 0.0

func _ensure_presence() -> void:
	if _presence_wired:
		return
	_presence_wired = true
	PresenceManager.peer_joined.connect(_on_peer_joined)
	PresenceManager.peer_updated.connect(_on_peer_updated)
	PresenceManager.peer_left.connect(_on_peer_left)
	PresenceManager.bot_wants_cast.connect(_on_bot_cast)
	PresenceManager.join_layer("pvxc")

func _on_peer_joined(pid: String, prof: Dictionary) -> void:
	if _peers.has(pid):
		return
	var rp := RemotePlayer.new()
	rp.setup(pid, prof, "identity" if PvxcManager.is_pvp_phase() else "cat")
	# Scatter peers inside the rim, away from the extraction lip.
	var a := hash(pid) % 360 * TAU / 360.0
	var r := 40.0 + (hash(pid + "r") % 50)
	rp.global_position = Vector3(cos(a) * r, 0.1, sin(a) * r)
	add_child(rp)
	_peers[pid] = rp
	_peer_hp[pid] = 80 + randi() % 60

func _on_peer_updated(pid: String, pos: Vector3) -> void:
	if not _peers.has(pid):
		_on_peer_joined(pid, PresenceManager.peer_profile(pid))
	if _peers.has(pid) and is_instance_valid(_peers[pid]):
		# Flat crater — no terrain heightmap.
		var flat := pos
		flat.y = 0.1
		_peers[pid].move_to(flat, null)

func _on_peer_left(pid: String) -> void:
	if _peers.has(pid):
		_peers[pid].queue_free()
		_peers.erase(pid)
	_peer_hp.erase(pid)

func _on_bot_cast(pid: String, skill: Dictionary) -> void:
	if not PvxcManager.is_pvp_phase():
		return
	if not _peers.has(pid) or not is_instance_valid(_peers[pid]):
		return
	var rp: RemotePlayer = _peers[pid]
	SkillVFX.cast_flash(self, rp.global_position)
	if rp.global_position.distance_to(_player.global_position) > 5.0:
		return
	var hit := 4 + randi() % 8
	if _shield > 0:
		var ab := mini(_shield, hit)
		_shield -= ab
		hit -= ab
	_player_hp -= hit
	SkillVFX.hit_spark(self, _player.global_position)
	PresenceManager.report_bot_hit_landed(pid)
	if _player_hp <= 0:
		_on_player_bitten_fatal(pid.trim_prefix("ghost_").replace("_", " "))


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
	env.ssao_enabled = true
	env.ssao_intensity = 2.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.03
	env.volumetric_fog_albedo = Color(0.4, 0.05, 0.08)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# Embers rising out of the red core — the pit breathes.
	var embers := GPUParticles3D.new()
	embers.amount = 200
	embers.lifetime = 6.0
	embers.position.y = 0.5
	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pmat.emission_ring_radius = CORE
	pmat.emission_ring_inner_radius = 0.0
	pmat.emission_ring_height = 0.5
	pmat.emission_ring_axis = Vector3.UP
	pmat.direction = Vector3.UP
	pmat.initial_velocity_min = 1.0
	pmat.initial_velocity_max = 3.0
	pmat.gravity = Vector3(0, 0.5, 0)
	pmat.scale_min = 0.05
	pmat.scale_max = 0.15
	pmat.color = Color(1.0, 0.25, 0.1)
	embers.process_material = pmat
	var ember_mesh := SphereMesh.new()
	ember_mesh.radius = 0.06
	ember_mesh.height = 0.12
	var ember_mat := StandardMaterial3D.new()
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(1.0, 0.3, 0.1)
	ember_mat.emission_energy_multiplier = 3.0
	ember_mesh.material = ember_mat
	embers.draw_pass_1 = ember_mesh
	add_child(embers)

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
	var c := PvxcCreature.new()
	c.position = pos
	add_child(c)
	c.setup(entity, _player)
	_creatures.append(c)
	c.bit_player.connect(_on_player_bitten)
	c.died.connect(func(creature: PvxcCreature):
		_creatures.erase(creature)
		PvxcManager.record_kill(str(creature.entity.get("name", "?")), creature.bounty, creature.global_position)
		NotificationUI.notify_win("🗡️ %s down (+%d bounty)" % [creature.entity.get("name", "?"), creature.bounty]))

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

## Skill effect resolution — the hotbar emits, the zone applies.
func _on_cast(sk: Dictionary) -> void:
	if not PvxcManager.in_run:
		return
	var kind: String = sk.get("kind", "damage")
	var shape: String = sk.get("shape", "single")
	var radius: float = float(sk.get("radius", 3.0))
	var power: float = float(sk.get("power", 1.0))
	var dmg := int(_attack_damage * power)
	# VFX: every cast flashes in your sensorium's light — unless the player
	# forged a blueprint for this skill, in which case THEIR design plays.
	var cast_bp := BlueprintManager.equipped_for("skill", str(sk.get("id", "")))
	if not cast_bp.is_empty():
		SkillVFX.blueprint_cast(self, _player.global_position, cast_bp)
	else:
		SkillVFX.cast_flash(self, _player.global_position)
	if sk.get("ult_cost", 0) > 0:
		SkillVFX.ultimate_burst(self, _player.global_position, maxf(radius, 6.0))
	elif shape == "aoe":
		SkillVFX.aoe_ring(self, _player.global_position, radius)
	elif shape == "line":
		SkillVFX.line_beam(self, _player.global_position, -_player.global_transform.basis.z, radius)
	match kind:
		"damage", "chance":
			if kind == "chance":
				dmg = int(dmg * (2.0 if randf() < 0.35 else 0.6)) # gambler's spread
			var hit := 0
			if PvxcManager.is_pvp_phase():
				hit = _hit_peers(shape, radius, dmg)
			else:
				for c in _targets_for(shape, radius):
					c.take_hit(dmg)
					SkillVFX.hit_spark(self, c.global_position)
					hit += 1
			if hit > 0:
				SkillManager.gain_ultimate(6.0 * hit)
			else:
				NotificationUI.notify_info("%s — nothing in reach." % sk.get("name", "?"))
		"shield":
			_shield = maxi(_shield, int(30 * power))
			SkillVFX.shield_bubble(self, _player, 6.0)
			SkillManager.gain_ultimate(4.0)
		"mobility":
			var fwd := -_player.global_transform.basis.z
			_player.global_position += fwd * (6.0 + 6.0 * power)
			SkillManager.gain_ultimate(3.0)
		"control":
			for c in _targets_for("aoe", maxf(radius, 6.0)):
				c.speed *= 0.5
				get_tree().create_timer(4.0).timeout.connect(func():
					if is_instance_valid(c): c.speed *= 2.0)
			SkillManager.gain_ultimate(5.0)
		"buff":
			_attack_damage = int(_attack_damage * (1.0 + 0.25 * power))
			get_tree().create_timer(8.0).timeout.connect(func():
				_attack_damage = _attack_damage_base) # settles back
			SkillManager.gain_ultimate(4.0)
		"build": # Sovereign Crown / Wildlands creations — walls and thickets
			_spawn_wall(_player.global_position - _player.global_transform.basis.z * 3.0, power)
			SkillManager.gain_ultimate(4.0)
		"sentry": # Crown Sentry — autonomous turret
			_spawn_sentry(_player.global_position - _player.global_transform.basis.z * 2.0, power)
			SkillManager.gain_ultimate(4.0)
		"summon": # Wildlands Packmate — a made creature that fights for you
			_spawn_summon(_player.global_position + Vector3(1.5, 0, 1.5), power)
			SkillManager.gain_ultimate(4.0)
		"transform": # Feral Shift / Apex Bloom — become the bigger thing
			_apply_transform(power, sk.get("ult_cost", 0) > 0)
			SkillManager.gain_ultimate(3.0)
		"bastion": # Coronation Bastion — walls + sentries in a ring
			for i in range(4):
				var a := TAU * i / 4.0
				_spawn_wall(_player.global_position + Vector3(cos(a), 0, sin(a)) * 6.0, power)
				_spawn_sentry(_player.global_position + Vector3(cos(a + 0.4), 0, sin(a + 0.4)) * 5.0, power)

func _targets_for(shape: String, radius: float) -> Array[PvxcCreature]:
	var out: Array[PvxcCreature] = []
	var origin := _player.global_position
	var fwd := -_player.global_transform.basis.z
	for c in _creatures:
		if not is_instance_valid(c) or not c.visible:
			continue
		var d := c.dist_to(origin)
		match shape:
			"single":
				if d < radius:
					out.append(c)
					return out # nearest-ish single target
			"aoe", "self":
				if d < radius:
					out.append(c)
			"line":
				var rel := c.global_position - origin
				if d < radius and rel.normalized().dot(fwd) > 0.6:
					out.append(c)
	return out

func _hit_peers(shape: String, radius: float, dmg: int) -> int:
	var hit := 0
	var origin := _player.global_position
	var fwd := -_player.global_transform.basis.z
	for pid in _peers.keys():
		var rp: RemotePlayer = _peers[pid]
		if not is_instance_valid(rp):
			continue
		var d: float = rp.global_position.distance_to(origin)
		var lands := false
		match shape:
			"single":
				lands = d < radius
			"aoe", "self":
				lands = d < radius
			"line":
				var rel := rp.global_position - origin
				lands = d < radius and rel.normalized().dot(fwd) > 0.6
			_:
				lands = d < radius
		if not lands:
			continue
		_peer_hp[pid] = int(_peer_hp.get(pid, 100)) - dmg
		SkillVFX.hit_spark(self, rp.global_position)
		hit += 1
		if int(_peer_hp[pid]) <= 0:
			PvxcManager.record_kill(pid, 40 + randi() % 80, rp.global_position)
			rp.queue_free()
			_peers.erase(pid)
			_peer_hp.erase(pid)
	return hit

func _on_player_bitten(damage: int) -> void:
	if PvxcManager.is_pvp_phase():
		return # wildlife sleeps during PvP
	SkillManager.gain_ultimate(3.0) # taking hits charges the ultimate too
	if _shield > 0:
		var absorbed := mini(_shield, damage)
		_shield -= absorbed
		damage -= absorbed
	_player_hp -= damage
	if _player_hp <= 0:
		# The pit keeps you. Nearest creature gets the credit.
		var killer := "the PVXC"
		var best := 999999.0
		for c in _creatures:
			if is_instance_valid(c) and c.visible:
				var d: float = c.dist_to(_player.global_position)
				if d < best:
					best = d
					killer = str(c.entity.get("name", killer))
		_on_player_bitten_fatal(killer)

func _on_player_bitten_fatal(killer: String) -> void:
	PvxcManager.record_death(killer)
	MusicManager.exit_racing()
	get_tree().change_scene_to_file("res://scenes/pvxc/pvxc_gate.tscn")

## ── Faction skill structures ────────────────────────────────────────────────
const CROWN_BUFF := 1.5 # Mandate of Stone: Crown structures last longer, hit harder

func _faction_mult() -> float:
	return CROWN_BUFF if PlayerProfile.faction == "SovereignCrown" else 1.0

func _spawn_wall(at: Vector3, power: float) -> void:
	var wall := StaticBody3D.new()
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(5.0, 2.6, 0.7)
	mi.mesh = box
	mi.position.y = 1.3
	mi.material_override = IdentityLens.world_material(Color(0.85, 0.7, 0.3) if PlayerProfile.faction == "SovereignCrown" else Color(0.25, 0.5, 0.25), 0.5)
	wall.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = box.size
	cs.shape = bs
	cs.position.y = 1.3
	wall.add_child(cs)
	wall.position = at
	wall.rotation.y = _player.rotation.y
	add_child(wall)
	SkillVFX.aoe_ring(self, at, 2.0)
	get_tree().create_timer(10.0 * power * _faction_mult()).timeout.connect(func():
		if is_instance_valid(wall): wall.queue_free())

func _spawn_sentry(at: Vector3, power: float) -> void:
	var sentry := Node3D.new()
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.25
	cyl.bottom_radius = 0.45
	cyl.height = 2.2
	mi.mesh = cyl
	mi.position.y = 1.1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.75, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.3)
	mat.emission_energy_multiplier = 1.2
	mi.material_override = mat
	sentry.add_child(mi)
	sentry.position = at
	add_child(sentry)
	var dps := int(_attack_damage * 0.4 * power * _faction_mult())
	var tick := Timer.new()
	tick.wait_time = 1.0
	tick.autostart = true
	sentry.add_child(tick)
	tick.timeout.connect(func():
		var best: PvxcCreature = null
		var bd := 12.0
		for c in _creatures:
			if is_instance_valid(c):
				var d: float = c.dist_to(sentry.global_position)
				if d < bd:
					bd = d
					best = c
		if best:
			best.take_hit(dps)
			SkillVFX.line_beam(self, sentry.global_position, (best.global_position - sentry.global_position).normalized(), bd)
			SkillVFX.hit_spark(self, best.global_position))
	get_tree().create_timer(15.0 * _faction_mult()).timeout.connect(func():
		if is_instance_valid(sentry): sentry.queue_free())

func _spawn_summon(at: Vector3, power: float) -> void:
	# A made creature: chases the nearest hostile and bites it.
	var ally := Node3D.new()
	var mi := MeshInstance3D.new()
	var caps := CapsuleMesh.new()
	caps.radius = 0.35
	caps.height = 1.1
	mi.mesh = caps
	mi.position.y = 0.7
	mi.material_override = IdentityLens.world_material(Color(0.3, 0.7, 0.35), 0.6)
	ally.add_child(mi)
	ally.position = at
	add_child(ally)
	SkillVFX.aoe_ring(self, at, 2.5)
	var dps := int(_attack_damage * 0.5 * power * (1.2 if PlayerProfile.faction == "WildlandsAscendant" else 1.0))
	var tick := Timer.new()
	tick.wait_time = 0.8
	tick.autostart = true
	ally.add_child(tick)
	tick.timeout.connect(func():
		var best: PvxcCreature = null
		var bd := 999.0
		for c in _creatures:
			if is_instance_valid(c):
				var d: float = c.dist_to(ally.global_position)
				if d < bd:
					bd = d
					best = c
		if best == null: return
		if bd > 2.0:
			ally.global_position += (best.global_position - ally.global_position).normalized() * 4.0 * 0.8
		else:
			best.take_hit(dps)
			SkillVFX.hit_spark(self, best.global_position))
	get_tree().create_timer(15.0).timeout.connect(func():
		if is_instance_valid(ally): ally.queue_free())

func _apply_transform(power: float, is_ult: bool) -> void:
	var wa := PlayerProfile.faction == "WildlandsAscendant"
	var dur := (12.0 if is_ult else 8.0) * (1.3 if wa else 1.0) # Green Memory
	var mult := 1.0 + 0.3 * power
	_attack_damage = int(_attack_damage * mult)
	_player.scale = Vector3.ONE * (1.35 if is_ult else 1.15)
	SkillVFX.ultimate_burst(self, _player.global_position, 4.0) if is_ult else SkillVFX.aoe_ring(self, _player.global_position, 3.0)
	NotificationUI.notify_info("🐾 You are the bigger thing now (%ds)." % int(dur))
	get_tree().create_timer(dur).timeout.connect(func():
		_attack_damage = _attack_damage_base
		if is_instance_valid(_player): _player.scale = Vector3.ONE)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud_mult = Label.new()
	_hud_mult.position = Vector2(10, 10)
	_hud_mult.add_theme_font_size_override("font_size", 20)
	layer.add_child(_hud_mult)
	_hud_phase = Label.new()
	_hud_phase.position = Vector2(10, 36)
	_hud_phase.add_theme_font_size_override("font_size", 16)
	layer.add_child(_hud_phase)
	_hud_loot = Label.new()
	_hud_loot.position = Vector2(10, 60)
	layer.add_child(_hud_loot)
	_hud_hp = Label.new()
	_hud_hp.position = Vector2(10, 108)
	_hud_hp.add_theme_font_size_override("font_size", 18)
	layer.add_child(_hud_hp)
	var target := Label.new()
	target.position = Vector2(10, 84)
	target.modulate = Color(1, 0.4, 0.4)
	var t := PvxcManager.my_target()
	target.text = "⚔️ Revenge target inside: %s" % t if t != "" else ""
	layer.add_child(target)

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _presence_wired:
		PresenceManager.report_position(_player.global_position)
	var m := PvxcManager.mult_at(_player.global_position)
	var red := PvxcManager.in_red_core(_player.global_position)
	_hud_mult.text = "🔴 RED CORE — x12" if red else "PVXC — x%d" % int(m)
	_hud_mult.modulate = Color(1, 0.15, 0.2) if red else Color(1, 0.8, 0.3)
	var secs := int(PvxcManager.phase_seconds_left())
	var mm := secs / 60
	var ss := secs % 60
	if PvxcManager.is_pvp_phase():
		_hud_phase.text = "⚔️ PvP layer — fight as yourself  ·  %d:%02d until cats" % [mm, ss]
		_hud_phase.modulate = Color(1.0, 0.35, 0.4)
	else:
		_hud_phase.text = "🐱 PvE layer — house cats vs wildlife  ·  %d:%02d until PvP" % [mm, ss]
		_hud_phase.modulate = Color(1.0, 0.85, 0.45)
	_hud_loot.text = "Carried loot: %d  (die and it's the house's)" % PvxcManager.carried_loot
	if is_instance_valid(_core_light):
		_core_light.light_energy = 3.0 + sin(Time.get_ticks_msec() / 300.0) * 1.2
	_attack_cd = maxf(_attack_cd - _delta, 0.0)
	if _hud_hp:
		_hud_hp.text = "❤️ %d/%d%s   1-5 skills • R ult • Tab bar" % [
			maxi(_player_hp, 0), PLAYER_MAX_HP,
			("  🛡️ %d" % _shield) if _shield > 0 else ""]
		_hud_hp.modulate = Color(1, 0.3, 0.3) if _player_hp < 30 else Color(0.9, 0.9, 0.9)
