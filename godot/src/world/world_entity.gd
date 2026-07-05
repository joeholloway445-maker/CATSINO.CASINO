class_name WorldEntity
extends Node3D
## An open-world threat pulled from EntityDexData — distinct from PvP
## "peers" (real players / bots): this is wildlife, not a person. Chases
## on aggro, bites on cooldown, scales with its evolution stage (1 weak,
## 2 mid, 3 apex). Faction-exclusive same as companions — a Sovereign
## Crown player only ever encounters Sovereign Crown (or Factionless)
## lines in open contested territory.

signal died(entity: WorldEntity)
signal bit_player(damage: int)

const AGGRO_RANGE := 20.0
const ATTACK_RANGE := 2.4
const BITE_COOLDOWN := 1.4

## Category -> BlueprintData entity body-plan mapping, so each dex
## category reads as a distinct silhouette even before bespoke art exists.
const CATEGORY_BODY := {
	"Energy": "floating", "Entropy": "serpent", "Gravity": "biped",
	"Matter": "quadruped", "Psyche": "avian", "Quantum": "swarm",
}
const CATEGORY_GLOW := {
	"Energy": Color(1.0, 0.9, 0.3), "Entropy": Color(0.5, 0.15, 0.15),
	"Gravity": Color(0.3, 0.4, 0.9), "Matter": Color(0.55, 0.45, 0.3),
	"Psyche": Color(0.8, 0.3, 0.9), "Quantum": Color(0.3, 0.9, 0.85),
}

var line: Dictionary = {}
var stage_info: Dictionary = {}
var stage_num := 1
var hp := 60
var max_hp := 60
var speed := 3.5
var damage := 6
var _bite_cd := 0.0
var _target: Node3D
var _visual: Node3D
var _label: Label3D

func setup(dex_line: Dictionary, stage: int, target: Node3D) -> void:
	line = dex_line
	stage_num = stage
	stage_info = EntityDexData.stage_for(dex_line, stage)
	_target = target
	max_hp = 50 + stage * 60
	hp = max_hp
	damage = 5 + stage * 6
	speed = 2.8 + stage * 0.6

	var category := str(line.get("category", "Matter"))
	var bp := BlueprintData.fresh("entity", "world_%s" % line.get("id", "?"), str(stage_info.get("name", "?")))
	bp.params["body"] = CATEGORY_BODY.get(category, "quadruped")
	bp.params["glow_color"] = CATEGORY_GLOW.get(category, Color.WHITE)
	bp.params["size"] = 0.8 + stage * 0.35
	bp.params["ethereal"] = 0.15 * stage if category == "Energy" else 0.0
	_visual = BlueprintMesh.build(bp)
	add_child(_visual)
	if stage >= 3:
		# Apex form gets a real visual tell, not just a bigger hp bar.
		SkillVFX.add_aura_shell(_visual, CATEGORY_GLOW.get(category, Color.WHITE), 0.1)

	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 1.8 + stage * 0.4
	_label.font_size = 38
	_label.outline_size = 6
	_label.text = "%s  (Stage %d)" % [str(stage_info.get("name", "?")), stage]
	_label.modulate = CATEGORY_GLOW.get(category, Color.WHITE)
	add_child(_label)

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
	if _label:
		_label.text = "%s  %d/%d" % [str(stage_info.get("name", "?")), maxi(hp, 0), max_hp]
	if _target and is_instance_valid(_target):
		var away := (global_position - _target.global_position).normalized()
		global_position += away * 1.0
	if hp <= 0:
		died.emit(self)
		queue_free()

## Bounty scales with stage — apex-stage kills matter more.
func bounty() -> int:
	return 20 + stage_num * 35
