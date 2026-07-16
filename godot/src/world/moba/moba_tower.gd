class_name MobaTower
extends Node3D
## Lane tower / nexus for Paws of the Ancients. Aggros nearest enemy unit
## in range, fires hitscan pulses, and dies when HP hits zero.

signal destroyed(tower: MobaTower)
signal damaged(tower: MobaTower, hp: int)

const ATTACK_RANGE := 10.0
const ATTACK_COOLDOWN := 1.1

var team: String = "enemy" # ally | enemy
var is_nexus := false
var max_hp := 220
var hp := 220
var attack_damage := 18
var armor := 4
var _attack_cd := 0.0
var _label: Label3D
var _mesh: MeshInstance3D
var _alive := true

func configure(p_team: String, p_nexus: bool = false) -> void:
	team = p_team
	is_nexus = p_nexus
	max_hp = 420 if p_nexus else 220
	hp = max_hp
	attack_damage = 28 if p_nexus else 18
	armor = 8 if p_nexus else 4
	add_to_group("moba_tower")
	add_to_group("moba_unit")
	add_to_group("moba_%s" % team)
	_build_visual()

func _build_visual() -> void:
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.4, 6.0 if is_nexus else 4.5, 2.4) if not is_nexus else Vector3(3.2, 7.0, 3.2)
	_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	var color := Color(0.35, 0.65, 1.0) if team == "ally" else Color(1.0, 0.35, 0.3)
	if is_nexus:
		color = color.lightened(0.25)
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.4 if is_nexus else 1.0
	_mesh.material_override = mat
	_mesh.position.y = box.size.y * 0.5
	add_child(_mesh)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = box.size.y + 0.6
	_label.font_size = 36
	_label.outline_size = 6
	_refresh_label()
	add_child(_label)

func _refresh_label() -> void:
	if _label == null:
		return
	var kind := "NEXUS" if is_nexus else "TOWER"
	_label.text = "%s %s\n%d/%d" % [team.to_upper(), kind, maxi(hp, 0), max_hp]
	_label.modulate = Color(0.6, 0.85, 1.0) if team == "ally" else Color(1.0, 0.55, 0.5)

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	if _attack_cd > 0.0:
		return
	var target := _find_target()
	if target == null:
		return
	_attack_cd = ATTACK_COOLDOWN
	_pulse_toward(target)
	if target.is_in_group("player"):
		var match_node := get_parent()
		while match_node and not match_node.has_method("hero_take_hit"):
			match_node = match_node.get_parent()
		if match_node:
			match_node.hero_take_hit(attack_damage, self)
	elif target.has_method("take_hit"):
		target.take_hit(attack_damage, self)

func _find_target() -> Node3D:
	var best: Node3D = null
	var best_d := ATTACK_RANGE
	for n in get_tree().get_nodes_in_group("moba_unit"):
		if not is_instance_valid(n) or n == self:
			continue
		if str(n.get("team")) == team:
			continue
		if n.has_method("is_alive") and not n.is_alive():
			continue
		var d := global_position.distance_to((n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n as Node3D
	# Player is the ally hero — towers on enemy team can shoot them.
	if team == "enemy":
		var players := get_tree().get_nodes_in_group("player")
		for p in players:
			if not is_instance_valid(p):
				continue
			var d2 := global_position.distance_to((p as Node3D).global_position)
			if d2 < best_d:
				best_d = d2
				best = p as Node3D
	return best

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
	get_parent().add_child(bolt)
	var tw := bolt.create_tween()
	tw.tween_property(bolt, "global_position", target.global_position + Vector3(0, 1, 0), 0.18)
	tw.tween_callback(bolt.queue_free)

func take_hit(amount: int, _attacker: Node = null) -> void:
	if not _alive:
		return
	var mitigated := maxi(1, amount - armor)
	hp -= mitigated
	_refresh_label()
	damaged.emit(self, hp)
	if hp <= 0:
		_alive = false
		destroyed.emit(self)
		queue_free()

func is_alive() -> bool:
	return _alive and hp > 0
