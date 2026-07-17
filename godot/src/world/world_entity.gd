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
## Fired when a boss advances enrage phase (2 at 66% HP, 3 at 33%).
signal phase_changed(entity: WorldEntity, phase: int)

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
## Category -> PerceptionSystem alignment, so the RPS aura system reads
## entities the same way it reads players (ALIGNMENT_AURAS tint + menace).
const CATEGORY_ALIGNMENT := {
	"Energy": "radiant", "Entropy": "umbral", "Gravity": "neutral",
	"Matter": "neutral", "Psyche": "umbral", "Quantum": "radiant",
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
var _loadout_visible := true

var _boss_phases := 0
var _boss_phase := 0
var _boss_title := ""

func setup(dex_line: Dictionary, stage: int, target: Node3D) -> void:
	line = dex_line
	stage_num = stage
	stage_info = EntityDexData.stage_for(dex_line, stage)
	_target = target
	max_hp = 50 + stage * 60
	hp = max_hp
	damage = 5 + stage * 6
	speed = 2.8 + stage * 0.6
	_boss_phases = 0
	_boss_phase = 0
	_boss_title = ""
	_rebuild_visual(stage)

## Gate 6 world/zone boss: bigger pool, multi-phase enrage at 66%/33%.
## `title` stamps the floating label ("WORLD BOSS" / "ZONE WARDEN").
func setup_boss(dex_line: Dictionary, stage: int, target: Node3D,
		title: String = "WORLD BOSS") -> void:
	setup(dex_line, maxi(stage, 3), target)
	_boss_phases = 3
	_boss_phase = 1
	_boss_title = title
	max_hp = 400 + stage * 180
	hp = max_hp
	damage = 12 + stage * 8
	speed = 3.2 + stage * 0.35
	if _visual:
		_visual.scale *= 1.55
	if _label:
		_label.text = "%s · %s" % [_boss_title, str(stage_info.get("name", "?"))]
		_label.font_size = 52
	SkillVFX.add_aura_shell(self, Color(1.0, 0.35, 0.15), 0.12)
	CombatSfx.play(self, "boss_spawn", global_position, -3.0)
	_refresh_boss_label()

func is_boss() -> bool:
	return _boss_phases > 0

func boss_phase() -> int:
	return _boss_phase

func _rebuild_visual(stage: int) -> void:
	if _visual and is_instance_valid(_visual):
		_visual.queue_free()
		_visual = null
	if _label and is_instance_valid(_label):
		_label.queue_free()
		_label = null

	var category := str(line.get("category", "Matter"))
	var bp := BlueprintData.fresh("entity", "world_%s" % line.get("id", "?"), str(stage_info.get("name", "?")))
	bp.params["body"] = CATEGORY_BODY.get(category, "quadruped")
	bp.params["glow_color"] = CATEGORY_GLOW.get(category, Color.WHITE)
	bp.params["size"] = 0.8 + stage * 0.35
	bp.params["ethereal"] = 0.15 * stage if category == "Energy" else 0.0
	_visual = BlueprintMesh.build(bp)
	add_child(_visual)

	# Same asymmetric RPS the game reads players through (SovereignCrown >
	# WildlandsAscendant > VeiledCurrent > SovereignCrown; Factionless
	# beats nothing): a rival-faction entity looms bigger and auras harder
	# on YOUR client than the same entity does for its own faction.
	var entity_profile := {
		"level": stage * 20, "faction": str(line.get("faction", "Factionless")),
		"alignment": CATEGORY_ALIGNMENT.get(category, "neutral"),
		"stats": {"pow": damage * 4},
	}
	var view: Dictionary = PerceptionSystem.perceive(PerceptionSystem.local_profile(), entity_profile)
	_visual.scale *= view.apparent_scale
	if view.aura_intensity > 0.3 or stage >= 3:
		# Apex form always gets a real visual tell; a rival-faction line
		# gets one too, scaled by how outmatched the RPS says you are.
		SkillVFX.add_aura_shell(_visual, view.aura_color, 0.06 + view.aura_intensity * 0.08)

	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 1.8 + stage * 0.4
	_label.font_size = 38
	_label.outline_size = 6
	_loadout_visible = view.loadout_visible
	_label.text = "%s  (Stage %d)" % [str(stage_info.get("name", "?")), stage] if _loadout_visible else "???"
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
	_hit_juice(amount)
	if _boss_phases > 0:
		var ratio := float(hp) / float(maxi(max_hp, 1))
		var want_phase := 1
		if ratio <= 0.33:
			want_phase = 3
		elif ratio <= 0.66:
			want_phase = 2
		if want_phase > _boss_phase:
			_enter_boss_phase(want_phase)
	_refresh_boss_label()
	if _target and is_instance_valid(_target):
		var away := (global_position - _target.global_position).normalized()
		global_position += away * 1.0
	if hp <= 0:
		if _boss_phases > 0:
			# Prefer world parent; CombatSfx also anchors to SceneTree.root.
			var host: Node = get_parent() if get_parent() != null else self
			var death_at := global_position
			CombatSfx.play(host, "boss_death", death_at, -1.0)
		died.emit(self)
		queue_free()

## Enrage step — aura, ground telegraph, toast, signal. Label keeps PHASE
## in the HP line (older code overwrote the announce on the next line).
func _enter_boss_phase(phase: int) -> void:
	_boss_phase = phase
	damage += 4
	speed += 0.35
	SkillVFX.add_aura_shell(self, Color(1.0, 0.2, 0.05), 0.04 * _boss_phase)
	CombatSfx.play(self, "boss_phase", global_position, -2.0)
	SkillVFX.boss_phase_telegraph(self, Vector3.ZERO, _boss_phase)
	phase_changed.emit(self, _boss_phase)
	# Toast via AutoloadGate — bare NotificationUI races class_name compile.
	var toast := AutoloadGate.get_node("NotificationUI")
	if toast != null and toast.has_method("notify_info"):
		var who := str(stage_info.get("name", "Boss"))
		toast.call("notify_info", "⚠ %s · %s — PHASE %d" % [_boss_title, who, _boss_phase])

func _refresh_boss_label() -> void:
	if _label == null or not is_instance_valid(_label):
		return
	var shown := str(stage_info.get("name", "?")) if _loadout_visible else "???"
	if _boss_phases > 0:
		shown = "%s · %s · PHASE %d" % [_boss_title, shown, maxi(_boss_phase, 1)]
		_label.text = "%s  %d/%d" % [shown, maxi(hp, 0), max_hp]
	else:
		_label.text = "%s  %d/%d" % [shown, maxi(hp, 0), max_hp]

## Brief albedo flash + floating damage number for combat readability.
func _hit_juice(amount: int) -> void:
	if _visual:
		for child in _visual.get_children():
			if child is MeshInstance3D and child.material_override is StandardMaterial3D:
				var mat: StandardMaterial3D = (child.material_override as StandardMaterial3D).duplicate()
				child.material_override = mat
				var base := mat.albedo_color
				mat.albedo_color = Color(1.0, 0.35, 0.25)
				var tw := create_tween()
				tw.tween_property(mat, "albedo_color", base, 0.18)
				break
	var floater := Label3D.new()
	floater.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	floater.text = "-%d" % amount
	floater.font_size = 48
	floater.outline_size = 8
	floater.modulate = Color(1.0, 0.45, 0.3)
	floater.position = Vector3(randf_range(-0.3, 0.3), 2.2, 0.0)
	add_child(floater)
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(floater, "position:y", floater.position.y + 1.2, 0.55)
	tw2.tween_property(floater, "modulate:a", 0.0, 0.55)
	tw2.chain().tween_callback(floater.queue_free)

## Bounty scales with stage — apex-stage kills matter more.
func bounty() -> int:
	return 20 + stage_num * 35
