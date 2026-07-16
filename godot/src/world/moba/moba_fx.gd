class_name MobaFx
extends RefCounted
## Tiny combat VFX helpers for Paws of the Ancients (damage floats, pings).

static func damage_float(parent: Node, world_pos: Vector3, amount: int, crit: bool = false) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.text = str(amount)
	lbl.font_size = 48 if crit else 34
	lbl.outline_size = 8
	lbl.modulate = Color(1.0, 0.85, 0.2) if crit else Color(1.0, 0.45, 0.35)
	lbl.position = world_pos + Vector3(randf_range(-0.3, 0.3), 1.4, randf_range(-0.3, 0.3))
	parent.add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y + 1.2, 0.55)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.55)
	tw.tween_callback(lbl.queue_free)

static func gold_float(parent: Node, world_pos: Vector3, amount: int) -> void:
	if parent == null or amount <= 0:
		return
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.text = "+%dg" % amount
	lbl.font_size = 32
	lbl.outline_size = 6
	lbl.modulate = Color(1.0, 0.9, 0.3)
	lbl.position = world_pos + Vector3(0, 1.8, 0)
	parent.add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y + 1.0, 0.7)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.tween_callback(lbl.queue_free)
