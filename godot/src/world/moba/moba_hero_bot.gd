class_name MobaHeroBot
extends Node3D
## Lightweight AI hero for offline 5v5 feel. Pushes an assigned lane, last-hits
## when safe, retreats under half HP, and can be summoned as a companion.

signal died(bot: MobaHeroBot)
signal damaged(bot: MobaHeroBot, amount: int)

const ATTACK_RANGE := 3.4
const ATTACK_CD := 0.9
const AGGRO := 11.0
const RETREAT_HP_FRAC := 0.35

var team: String = "ally"
var lane_id: int = 1
var display_name: String = "Bot"
var is_companion := false
var max_hp := 180
var hp := 180
var damage := 16
var armor := 3
var speed := 4.2
var gold_bounty := 140
var xp_bounty := 90
var waypoints: Array[Vector3] = []
var _wp_index := 0
var _attack_cd := 0.0
var _alive := true
var _visual: MeshInstance3D
var _label: Label3D
var _match: Node
var _home: Vector3 = Vector3.ZERO

func configure(p_team: String, p_lane: int, path: Array[Vector3], p_name: String, p_match: Node, p_companion: bool = false) -> void:
	team = p_team
	lane_id = p_lane
	display_name = p_name
	_match = p_match
	is_companion = p_companion
	waypoints = path.duplicate()
	if team == "enemy":
		waypoints.reverse()
	if is_companion:
		max_hp = 200
		damage = 18
		armor = 4
		speed = 4.6
		gold_bounty = 0
	elif team == "enemy":
		max_hp = 170
		damage = 15
		gold_bounty = 150
	hp = max_hp
	_home = waypoints[0] if not waypoints.is_empty() else global_position
	add_to_group("moba_hero")
	add_to_group("moba_unit")
	add_to_group("moba_%s" % team)
	_build_visual()

func _build_visual() -> void:
	_visual = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.45
	cap.height = 1.5
	_visual.mesh = cap
	var mat := StandardMaterial3D.new()
	if is_companion:
		mat.albedo_color = Color(0.55, 0.95, 0.7)
	elif team == "ally":
		mat.albedo_color = Color(0.35, 0.7, 1.0)
	else:
		mat.albedo_color = Color(0.95, 0.4, 0.55)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.8
	_visual.material_override = mat
	_visual.position.y = 0.9
	add_child(_visual)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 2.1
	_label.font_size = 30
	_label.outline_size = 5
	_refresh_label()
	add_child(_label)

func _refresh_label() -> void:
	if _label:
		_label.text = "%s\n%d/%d" % [display_name, maxi(hp, 0), max_hp]

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	# Companion sticks near player when present.
	if is_companion and team == "ally" and _match and _match.get("player"):
		var p: Node3D = _match.player
		if p and is_instance_valid(p) and _match.hero_is_alive():
			var to_p: Vector3 = p.global_position - global_position
			to_p.y = 0.0
			if to_p.length() > 4.5:
				global_position += to_p.normalized() * speed * delta
	var target := _acquire()
	if float(hp) / float(max_hp) < RETREAT_HP_FRAC and not is_companion:
		_retreat(delta)
		return
	if target != null:
		var to: Vector3 = target.global_position - global_position
		to.y = 0.0
		var d: float = to.length()
		if d <= ATTACK_RANGE:
			if _attack_cd <= 0.0:
				_attack_cd = ATTACK_CD
				_strike(target)
		else:
			global_position += to.normalized() * speed * delta
			if _visual:
				_visual.rotation.y = atan2(to.x, to.z)
		return
	_push_lane(delta)

func _retreat(delta: float) -> void:
	var to: Vector3 = _home - global_position
	to.y = 0.0
	if to.length() > 1.0:
		global_position += to.normalized() * speed * 1.15 * delta
	# Slow regen while retreating.
	hp = mini(max_hp, hp + int(ceil(8.0 * delta)))
	_refresh_label()

func _push_lane(delta: float) -> void:
	if _wp_index >= waypoints.size():
		return
	var goal: Vector3 = waypoints[_wp_index]
	var to: Vector3 = goal - global_position
	to.y = 0.0
	if to.length() < 1.5:
		_wp_index = mini(_wp_index + 1, waypoints.size() - 1)
		return
	global_position += to.normalized() * speed * delta
	if _visual:
		_visual.rotation.y = atan2(to.x, to.z)

func _acquire() -> Node3D:
	var best: Node3D = null
	var best_d: float = AGGRO
	for n in get_tree().get_nodes_in_group("moba_unit"):
		if not is_instance_valid(n) or n == self:
			continue
		if str(n.get("team")) == team:
			continue
		if n.has_method("is_alive") and not n.is_alive():
			continue
		var d: float = global_position.distance_to((n as Node3D).global_position)
		# Prefer low-HP minions (last-hit instinct) slightly.
		var score: float = d
		if n.is_in_group("moba_minion") and n.get("hp") != null:
			var mhp: int = int(n.get("hp"))
			if mhp <= damage + 4:
				score -= 3.0
		if score < best_d:
			best_d = score
			best = n as Node3D
	if team == "enemy":
		for p in get_tree().get_nodes_in_group("player"):
			if not is_instance_valid(p):
				continue
			if _match and not _match.hero_is_alive():
				continue
			var d: float = global_position.distance_to((p as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = p as Node3D
	return best

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
	damaged.emit(self, mitigated)
	_refresh_label()
	MobaFx.damage_float(get_parent(), global_position, mitigated, mitigated >= 30)
	if hp <= 0:
		_alive = false
		if _match and _match.has_method("on_hero_bot_killed"):
			_match.on_hero_bot_killed(self, attacker)
		died.emit(self)
		queue_free()

func is_alive() -> bool:
	return _alive and hp > 0
