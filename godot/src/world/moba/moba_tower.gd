class_name MobaTower
extends Node3D
## Lane tower / inhibitor / nexus. Classic aggro: minions first; heroes only
## if they recently damaged the structure or no minions remain in range.
## Nexus stays invulnerable until every outer tower is down.

signal destroyed(tower: MobaTower)
signal damaged(tower: MobaTower, amount: int, hp: int)

enum Kind { TOWER, INHIBITOR, NEXUS }

const ATTACK_RANGE := 10.0
const ATTACK_COOLDOWN := 1.05
const HERO_AGGRO_MEMORY := 4.0

var team: String = "enemy"
var kind: Kind = Kind.TOWER
var lane_id: int = -1
var max_hp := 220
var hp := 220
var attack_damage := 18
var armor := 4
var invulnerable := false
var _attack_cd := 0.0
var _hero_aggro_timer := 0.0
var _label: Label3D
var _mesh: MeshInstance3D
var _bar: Label3D
var _alive := true
var _match: Node # MobaMatch

func configure(p_team: String, p_kind: Kind, p_lane: int = -1, p_match: Node = null) -> void:
	team = p_team
	kind = p_kind
	lane_id = p_lane
	_match = p_match
	match kind:
		Kind.TOWER:
			max_hp = 240
			attack_damage = 20
			armor = 5
		Kind.INHIBITOR:
			max_hp = 320
			attack_damage = 0
			armor = 7
		Kind.NEXUS:
			max_hp = 520
			attack_damage = 30
			armor = 10
			invulnerable = true
	hp = max_hp
	add_to_group("moba_tower")
	add_to_group("moba_unit")
	add_to_group("moba_%s" % team)
	if kind == Kind.INHIBITOR:
		add_to_group("moba_inhibitor")
	if kind == Kind.NEXUS:
		add_to_group("moba_nexus")
	_build_visual()

func is_nexus() -> bool:
	return kind == Kind.NEXUS

func is_inhibitor() -> bool:
	return kind == Kind.INHIBITOR

func set_invulnerable(v: bool) -> void:
	invulnerable = v
	_refresh_label()

func _build_visual() -> void:
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	match kind:
		Kind.TOWER:
			box.size = Vector3(2.4, 4.8, 2.4)
		Kind.INHIBITOR:
			box.size = Vector3(2.8, 3.2, 2.8)
		Kind.NEXUS:
			box.size = Vector3(3.6, 7.2, 3.6)
	_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	var color := Color(0.35, 0.65, 1.0) if team == "ally" else Color(1.0, 0.35, 0.3)
	if kind == Kind.NEXUS:
		color = color.lightened(0.25)
	elif kind == Kind.INHIBITOR:
		color = color.darkened(0.15)
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5 if kind == Kind.NEXUS else 1.0
	_mesh.material_override = mat
	_mesh.position.y = box.size.y * 0.5
	add_child(_mesh)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = box.size.y + 0.7
	_label.font_size = 34
	_label.outline_size = 6
	add_child(_label)
	_refresh_label()

func _refresh_label() -> void:
	if _label == null:
		return
	var kind_name := "TOWER"
	match kind:
		Kind.INHIBITOR:
			kind_name = "INHIB"
		Kind.NEXUS:
			kind_name = "NEXUS"
	var lock := " 🔒" if invulnerable else ""
	_label.text = "%s %s%s\n%d/%d" % [team.to_upper(), kind_name, lock, maxi(hp, 0), max_hp]
	_label.modulate = Color(0.6, 0.85, 1.0) if team == "ally" else Color(1.0, 0.55, 0.5)

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_hero_aggro_timer = maxf(_hero_aggro_timer - delta, 0.0)
	if attack_damage <= 0:
		return
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	if _attack_cd > 0.0:
		return
	var target := _find_target()
	if target == null:
		return
	_attack_cd = ATTACK_COOLDOWN
	_pulse_toward(target)
	_deal_to(target, attack_damage)

func _find_target() -> Node3D:
	var best_minion: Node3D = null
	var best_hero: Node3D = null
	var d_minion: float = ATTACK_RANGE
	var d_hero: float = ATTACK_RANGE
	for n in get_tree().get_nodes_in_group("moba_unit"):
		if not is_instance_valid(n) or n == self:
			continue
		if str(n.get("team")) == team:
			continue
		if n.has_method("is_alive") and not n.is_alive():
			continue
		if n.is_in_group("moba_tower"):
			continue
		var d: float = global_position.distance_to((n as Node3D).global_position)
		if d > ATTACK_RANGE:
			continue
		if n.is_in_group("moba_minion") and d < d_minion:
			d_minion = d
			best_minion = n as Node3D
		elif n.is_in_group("moba_hero") and d < d_hero:
			d_hero = d
			best_hero = n as Node3D
	# Player counts as ally hero for enemy towers.
	if team == "enemy":
		for p in get_tree().get_nodes_in_group("player"):
			if not is_instance_valid(p):
				continue
			if _match and _match.has_method("hero_is_alive") and not _match.hero_is_alive():
				continue
			var d2: float = global_position.distance_to((p as Node3D).global_position)
			if d2 < d_hero:
				d_hero = d2
				best_hero = p as Node3D
	if best_minion != null:
		return best_minion
	# Classic: only shoot heroes if they tagged us recently, or no minions.
	if best_hero != null and (_hero_aggro_timer > 0.0 or best_minion == null):
		return best_hero
	return null

func _deal_to(target: Node3D, amount: int) -> void:
	if target.is_in_group("player"):
		if _match and _match.has_method("hero_take_hit"):
			_match.hero_take_hit(amount, self)
		return
	if target.has_method("take_hit"):
		target.take_hit(amount, self)

func _pulse_toward(target: Node3D) -> void:
	var bolt := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.18
	bolt.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.3)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 3.0
	bolt.material_override = mat
	bolt.global_position = global_position + Vector3(0, 3, 0)
	var host: Node = get_parent()
	if host:
		host.add_child(bolt)
		var tw := bolt.create_tween()
		tw.tween_property(bolt, "global_position", target.global_position + Vector3(0, 1, 0), 0.18)
		tw.tween_callback(bolt.queue_free)

func take_hit(amount: int, attacker: Node = null) -> void:
	if not _alive:
		return
	if invulnerable:
		if _match and _match.has_method("ping_feed"):
			_match.ping_feed("Nexus invulnerable — clear outer towers first")
		return
	# Inhibitors: only vulnerable after their lane tower is down.
	if kind == Kind.INHIBITOR and _match and _match.has_method("lane_tower_alive"):
		if _match.lane_tower_alive(team, lane_id):
			if _match.has_method("ping_feed"):
				_match.ping_feed("Destroy the lane tower before the inhibitor")
			return
	var mitigated: int = maxi(1, amount - armor)
	hp -= mitigated
	damaged.emit(self, mitigated, hp)
	_refresh_label()
	MobaFx.damage_float(get_parent(), global_position, mitigated, mitigated >= 40)
	# Hero aggro memory when a hero (or player) hits us.
	if attacker != null and (attacker.is_in_group("player") or attacker.is_in_group("moba_hero")):
		_hero_aggro_timer = HERO_AGGRO_MEMORY
	if hp <= 0:
		_alive = false
		destroyed.emit(self)
		queue_free()

func is_alive() -> bool:
	return _alive and hp > 0
