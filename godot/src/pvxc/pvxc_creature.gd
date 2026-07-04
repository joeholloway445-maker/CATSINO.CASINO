class_name PvxcCreature
extends Node3D
## A hostile PVXC creature with real behavior: idles until you're inside
## its aggro ring, then hunts. Has HP scaled by rarity; hit it with attacks
## (pvxc_zone forwards the player's swings), it staggers; kill it for a
## bounty through PvxcManager. If it reaches you it bites on a cooldown —
## the zone owns your HP bar.

signal died(creature: PvxcCreature)
signal bit_player(damage: int)

const AGGRO_RANGE := 18.0
const ATTACK_RANGE := 2.2
const BITE_COOLDOWN := 1.2

var entity: Dictionary = {}
var hp := 100
var max_hp := 100
var speed := 4.0
var damage := 8
var bounty := 20
var _bite_cd := 0.0
var _target: Node3D
var _visual: Node3D
var _hp_bar: Label3D

func setup(e: Dictionary, target: Node3D) -> void:
	entity = e
	_target = target
	var rarity := int(e.get("rarity", 1))
	max_hp = 40 + rarity * 30 + int(e.get("res", 40))
	hp = max_hp
	damage = 5 + rarity * 3 + int(e.get("pow", 40)) / 10
	speed = 3.0 + float(e.get("spd", 40)) / 25.0
	bounty = 15 + rarity * 20

	var profile := {"level": rarity * 15, "faction": e.get("faction", ""),
		"alignment": "feral", "stats": {"pow": e.get("pow", 50)}}
	var seen: Dictionary = IdentityLens.perceive_being(profile, Color(0.6, 0.3, 0.3))
	_visual = AssetLibrary.instance("creature")
	if _visual == null:
		var mi := MeshInstance3D.new()
		var caps := CapsuleMesh.new()
		caps.radius = 0.5
		caps.height = 1.6
		mi.mesh = caps
		mi.material_override = seen.material
		_visual = mi
	_visual.scale = Vector3.ONE * seen.scale
	_visual.position.y = 1.0
	add_child(_visual)

	_hp_bar = Label3D.new()
	_hp_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_bar.position.y = 2.4
	_hp_bar.font_size = 40
	_hp_bar.outline_size = 6
	if seen.view.loadout_visible:
		_hp_bar.text = str(e.get("name", "?"))
	else:
		_hp_bar.text = "???"
	add_child(_hp_bar)

func _physics_process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	var d := to_target.length()
	_bite_cd = maxf(_bite_cd - delta, 0.0)
	if d < ATTACK_RANGE:
		if _bite_cd <= 0.0:
			_bite_cd = BITE_COOLDOWN
			bit_player.emit(damage)
	elif d < AGGRO_RANGE:
		global_position += to_target.normalized() * speed * delta
		if _visual:
			_visual.rotation.y = atan2(to_target.x, to_target.z)

func take_hit(amount: int) -> void:
	hp -= amount
	_hp_bar.text = "%s  %d/%d" % [_hp_bar.text.split("  ")[0], maxi(hp, 0), max_hp]
	_hp_bar.modulate = Color(1.0, lerpf(0.2, 1.0, float(hp) / max_hp), 0.3)
	# Knockback stagger.
	if _target and is_instance_valid(_target):
		var away := (global_position - _target.global_position).normalized()
		global_position += away * 1.2
	if hp <= 0:
		died.emit(self)
		queue_free()

func dist_to(pos: Vector3) -> float:
	return global_position.distance_to(pos)
