class_name MobaMinion
extends Node3D
## Lane minion — melee / caster / siege / super. Priority: enemy minions →
## towers → heroes. Last-hitter recorded for gold; nearby heroes get XP.

signal died(minion: MobaMinion, bounty: int, last_hit_by: Node)

enum Kind { MELEE, CASTER, SIEGE, SUPER }

const AGGRO_RANGE := 8.0
const XP_RADIUS := 14.0

var team: String = "ally"
var lane_id: int = 0
var kind: Kind = Kind.MELEE
var waypoints: Array[Vector3] = []
var _wp_index := 0
var max_hp := 70
var hp := 70
var damage := 8
var armor := 1
var speed := 3.4
var gold_bounty := 18
var xp_bounty := 24
var attack_range := 2.2
var attack_cooldown := 0.95
var _attack_cd := 0.0
var _alive := true
var _visual: MeshInstance3D
var _label: Label3D
var _target: Node3D
var _last_hitter: Node = null
var _match: Node

func configure(p_team: String, p_lane: int, path: Array[Vector3], p_kind = Kind.MELEE, p_match: Node = null) -> void:
	team = p_team
	lane_id = p_lane
	kind = p_kind as Kind
	_match = p_match
	waypoints = path.duplicate()
	if team == "enemy":
		waypoints.reverse()
	match kind:
		Kind.MELEE:
			max_hp = 80
			damage = 10
			armor = 2
			speed = 3.5
			gold_bounty = 20
			xp_bounty = 26
			attack_range = 2.2
		Kind.CASTER:
			max_hp = 55
			damage = 14
			armor = 0
			speed = 3.3
			gold_bounty = 16
			xp_bounty = 22
			attack_range = 5.0
			attack_cooldown = 1.1
		Kind.SIEGE:
			max_hp = 140
			damage = 18
			armor = 4
			speed = 2.8
			gold_bounty = 40
			xp_bounty = 40
			attack_range = 4.5
			attack_cooldown = 1.3
		Kind.SUPER:
			max_hp = 260
			damage = 28
			armor = 6
			speed = 3.0
			gold_bounty = 55
			xp_bounty = 60
			attack_range = 2.6
	if team == "enemy":
		damage += 1
		gold_bounty += 2
	else:
		gold_bounty = 0 # allies don't pay the player on death
	hp = max_hp
	add_to_group("moba_minion")
	add_to_group("moba_unit")
	add_to_group("moba_%s" % team)
	_build_visual()

func _build_visual() -> void:
	_visual = MeshInstance3D.new()
	var mesh: Mesh
	match kind:
		Kind.CASTER:
			var s := SphereMesh.new()
			s.radius = 0.4
			mesh = s
		Kind.SIEGE:
			var b := BoxMesh.new()
			b.size = Vector3(0.9, 1.0, 0.9)
			mesh = b
		Kind.SUPER:
			var c := CapsuleMesh.new()
			c.radius = 0.55
			c.height = 1.6
			mesh = c
		_:
			var cap := CapsuleMesh.new()
			cap.radius = 0.35
			cap.height = 1.1
			mesh = cap
	_visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.75, 1.0) if team == "ally" else Color(1.0, 0.45, 0.35)
	if kind == Kind.SUPER:
		mat.albedo_color = mat.albedo_color.lightened(0.2)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.9 if kind == Kind.SUPER else 0.55
	_visual.material_override = mat
	_visual.position.y = 0.7
	add_child(_visual)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 1.7
	_label.font_size = 26
	_label.outline_size = 4
	_refresh_label()
	add_child(_label)

func _refresh_label() -> void:
	if _label == null:
		return
	var tag := "M"
	match kind:
		Kind.CASTER:
			tag = "C"
		Kind.SIEGE:
			tag = "S"
		Kind.SUPER:
			tag = "★"
	_label.text = "%s%s %d" % ["▲" if team == "ally" else "▼", tag, maxi(hp, 0)]

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_target = _acquire_target()
	if _target != null and is_instance_valid(_target):
		var to: Vector3 = _target.global_position - global_position
		to.y = 0.0
		var d: float = to.length()
		if d <= attack_range:
			if _attack_cd <= 0.0:
				_attack_cd = attack_cooldown
				_strike(_target)
		else:
			global_position += to.normalized() * speed * delta
			if _visual and to.length() > 0.01:
				_visual.rotation.y = atan2(to.x, to.z)
		return
	_advance_lane(delta)

func _advance_lane(delta: float) -> void:
	if _wp_index >= waypoints.size():
		return
	var goal: Vector3 = waypoints[_wp_index]
	var to: Vector3 = goal - global_position
	to.y = 0.0
	if to.length() < 1.2:
		_wp_index += 1
		return
	global_position += to.normalized() * speed * delta
	if _visual:
		_visual.rotation.y = atan2(to.x, to.z)

func _acquire_target() -> Node3D:
	var best_minion: Node3D = null
	var best_tower: Node3D = null
	var best_hero: Node3D = null
	var d_minion: float = AGGRO_RANGE
	var d_tower: float = AGGRO_RANGE
	var d_hero: float = AGGRO_RANGE
	for n in get_tree().get_nodes_in_group("moba_unit"):
		if not is_instance_valid(n) or n == self:
			continue
		if str(n.get("team")) == team:
			continue
		if n.has_method("is_alive") and not n.is_alive():
			continue
		var d: float = global_position.distance_to((n as Node3D).global_position)
		if n.is_in_group("moba_minion") and d < d_minion:
			d_minion = d
			best_minion = n as Node3D
		elif n.is_in_group("moba_tower") and d < d_tower:
			# Siege/supers prefer structures a bit more (wider effective aggro).
			var range_bonus: float = 2.0 if kind == Kind.SIEGE or kind == Kind.SUPER else 0.0
			if d < AGGRO_RANGE + range_bonus:
				d_tower = d
				best_tower = n as Node3D
		elif n.is_in_group("moba_hero") and d < d_hero:
			d_hero = d
			best_hero = n as Node3D
	if team == "enemy":
		for p in get_tree().get_nodes_in_group("player"):
			if not is_instance_valid(p):
				continue
			if _match and _match.has_method("hero_is_alive") and not _match.hero_is_alive():
				continue
			var d: float = global_position.distance_to((p as Node3D).global_position)
			if d < d_hero:
				d_hero = d
				best_hero = p as Node3D
	if best_minion != null:
		return best_minion
	if best_tower != null:
		return best_tower
	return best_hero

func _strike(target: Node3D) -> void:
	if target.is_in_group("player"):
		if _match and _match.has_method("hero_take_hit"):
			_match.hero_take_hit(damage, self)
		return
	if target.has_method("take_hit"):
		target.take_hit(damage, self)

func take_hit(amount: int, attacker: Node = null) -> void:
	if not _alive:
		return
	var mitigated: int = maxi(1, amount - armor)
	hp -= mitigated
	if attacker != null:
		_last_hitter = attacker
	_refresh_label()
	MobaFx.damage_float(get_parent(), global_position, mitigated, false)
	if hp <= 0:
		_alive = false
		died.emit(self, gold_bounty, _last_hitter)
		# XP to nearby ally heroes / player
		if _match and _match.has_method("grant_xp_near"):
			_match.grant_xp_near(global_position, xp_bounty, team)
		queue_free()

func is_alive() -> bool:
	return _alive and hp > 0
