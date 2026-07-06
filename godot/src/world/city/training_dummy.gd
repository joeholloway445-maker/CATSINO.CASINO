class_name TrainingDummy
extends Node3D
## A Stockyards training dummy. Click it (or hit it with a cast — the host
## scene forwards those) to practice a combat discipline: UNARMED and GUNS
## dummies feed XP into the new discipline lines; MELEE and RANGED feed
## whatever skill sits in your hotbar's first slot. Infinite HP — it's a
## dummy — but it staggers, sparks, and counts your hits out loud.

var discipline_tag := "MELEE"
var trains_skill := "" # skill id to XP; empty = hotbar slot 0's skill
var accent := Color(0.8, 0.7, 0.4)
var _hits := 0
var _label: Label3D
var _body: MeshInstance3D

func _ready() -> void:
	var real := AssetLibrary.instance("training_dummy")
	if real != null:
		add_child(real)
	else:
		_body = MeshInstance3D.new()
		var caps := CapsuleMesh.new()
		caps.radius = 0.45
		caps.height = 1.9
		_body.mesh = caps
		_body.position.y = 1.2
		_body.material_override = AssetLibrary.material("facade_brick", Color(0.6, 0.45, 0.3), 0.2, 0.0, 0.9)
		add_child(_body)
		var post := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.12
		cyl.height = 1.2
		post.mesh = cyl
		post.position.y = 0.4
		post.material_override = AssetLibrary.material("facade_metal", Color(0.35, 0.3, 0.25), 0.3, 0.4, 0.7)
		add_child(post)

	_label = Label3D.new()
	_label.text = discipline_tag
	_label.font_size = 64
	_label.outline_size = 10
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 2.8
	_label.modulate = accent
	add_child(_label)

	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 2.4, 1.4)
	cs.shape = box
	cs.position.y = 1.2
	area.add_child(cs)
	area.input_ray_pickable = true
	area.input_event.connect(func(_c, ev, _p, _n, _i):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			take_hit())
	add_child(area)

## One practice hit: stagger, spark, XP into the right discipline.
func take_hit() -> void:
	_hits += 1
	_label.text = "%s  ×%d" % [discipline_tag, _hits]
	SkillVFX.hit_spark(self, global_position)
	if _body:
		var tw := create_tween()
		tw.tween_property(_body, "rotation:x", 0.35, 0.08)
		tw.tween_property(_body, "rotation:x", 0.0, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var skill_id := trains_skill
	if skill_id == "":
		# MELEE/RANGED dummies train whatever's slotted first on your bar.
		var bar: Dictionary = SkillManager.current_bar()
		var actives: Array = bar.get("actives", [])
		if not actives.is_empty():
			skill_id = str(actives[0])
	if skill_id != "":
		# Discipline skills can be LEARNED here — the Stockyards is the
		# teacher (spends a skill point via the normal unlock path).
		if not SkillManager.is_unlocked(skill_id):
			if not SkillManager.unlock(skill_id):
				return
		SkillManager.add_skill_xp(skill_id, 4)
	if _hits % 25 == 0:
		EconomyManager.earn_prestige(2, "stockyards_training")
		NotificationUI.notify_info("🐎 %d hits on the %s dummy. The Stockyards respects repetition." % [_hits, discipline_tag])
