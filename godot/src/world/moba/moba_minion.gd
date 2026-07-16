class_name MobaMinion
extends Node3D
## Lane minion for Paws of the Ancients. Walks waypoints; when enemies are
## in aggro, prioritizes enemy minions → towers → hero.

signal died(minion: MobaMinion, bounty: int)

const AGGRO_RANGE := 8.0
const ATTACK_RANGE := 2.2
const ATTACK_COOLDOWN := 0.95

var team: String = "ally"
var lane_id: int = 0
var waypoints: Array[Vector3] = []
var _wp_index := 0
var max_hp := 70
var hp := 70
var damage := 8
var armor := 1
var speed := 3.4
var gold_bounty := 18
var _attack_cd := 0.0
var _alive := true
var _visual: MeshInstance3D
var _label: Label3D
var _target: Node3D

func configure(p_team: String, p_lane: int, path: Array[Vector3]) -> void:
	team = p_team
	lane_id = p_lane
	waypoints = path.duplicate()
	if team == "enemy":
		waypoints.reverse()
	max_hp = 70
	hp = max_hp
	damage = 9 if team == "enemy" else 8
	speed = 3.2 if team == "enemy" else 3.5
	gold_bounty = 22 if team == "enemy" else 0
	add_to_group("moba_minion")
	add_to_group("moba_unit")
	add_to_group("moba_%s" % team)
	_build_visual()

func _build_visual() -> void:
	_visual = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.1
	_visual.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.75, 1.0) if team == "ally" else Color(1.0, 0.45, 0.35)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.6
	_visual.material_override = mat
	_visual.position.y = 0.7
	add_child(_visual)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 1.6
	_label.font_size = 28
	_label.outline_size = 4
	_refresh_label()
	add_child(_label)

func _refresh_label() -> void:
	if _label:
		_label.text = "%s %d" % ["▲" if team == "ally" else "▼", maxi(hp, 0)]

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_target = _acquire_target()
	if _target != null and is_instance_valid(_target):
		var to := _target.global_position - global_position
		to.y = 0.0
		var d := to.length()
		if d <= ATTACK_RANGE:
			if _attack_cd <= 0.0:
				_attack_cd = ATTACK_COOLDOWN
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
	var to := goal - global_position
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
	var d_minion := AGGRO_RANGE
	var d_tower := AGGRO_RANGE
	var d_hero := AGGRO_RANGE
	for n in get_tree().get_nodes_in_group("moba_unit"):
		if not is_instance_valid(n) or n == self:
			continue
		if str(n.get("team")) == team:
			continue
		if n.has_method("is_alive") and not n.is_alive():
			continue
		var d := global_position.distance_to((n as Node3D).global_position)
		if n.is_in_group("moba_minion") and d < d_minion:
			d_minion = d
			best_minion = n as Node3D
		elif n.is_in_group("moba_tower") and d < d_tower:
			d_tower = d
			best_tower = n as Node3D
	if team == "enemy":
		for p in get_tree().get_nodes_in_group("player"):
			if not is_instance_valid(p):
				continue
			var d := global_position.distance_to((p as Node3D).global_position)
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
		var match_node := get_parent()
		while match_node and not match_node.has_method("hero_take_hit"):
			match_node = match_node.get_parent()
		if match_node:
			match_node.hero_take_hit(damage, self)
		return
	if target.has_method("take_hit"):
		target.take_hit(damage, self)

func take_hit(amount: int, _attacker: Node = null) -> void:
	if not _alive:
		return
	hp -= maxi(1, amount - armor)
	_refresh_label()
	if hp <= 0:
		_alive = false
		died.emit(self, gold_bounty)
		queue_free()

func is_alive() -> bool:
	return _alive and hp > 0
