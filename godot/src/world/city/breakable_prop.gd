class_name BreakableProp
extends Node3D
## A demolishable/rebuildable piece of city furniture. Casts and clicks
## damage it; at zero it bursts into debris and pays a little fragment
## salvage. Walk up to the wreck and press E to REBUILD it (costs
## fragments) — the city is something players break and repair, not a
## painted backdrop. In group "breakable" so every cast resolver finds it.

signal demolished(prop: BreakableProp)
signal rebuilt(prop: BreakableProp)

const REBUILD_COST := 5   # fragments
const SALVAGE := 2        # fragments paid on demolition

var hp := 30
var max_hp := 30
var broken := false
var accent := Color(0.6, 0.6, 0.65)

var _visual: Node3D
var _rubble: Node3D
var _prompt: Label3D

func _ready() -> void:
	add_to_group("breakable")
	var real := AssetLibrary.instance("city_prop")
	if real != null:
		_visual = real
	else:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.2, 1.0, 1.2)
		mi.mesh = box
		mi.position.y = 0.5
		mi.material_override = AssetLibrary.material("city_prop", accent.darkened(0.4), 0.25, 0.3, 0.7)
		_visual = mi
	add_child(_visual)

	# Rubble pile, hidden until demolished.
	_rubble = Node3D.new()
	for i in 4:
		var chunk := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * randf_range(0.2, 0.45)
		chunk.mesh = box
		chunk.position = Vector3(randf_range(-0.5, 0.5), 0.15, randf_range(-0.5, 0.5))
		chunk.rotation = Vector3(randf(), randf(), randf())
		chunk.material_override = AssetLibrary.material("facade_concrete", accent.darkened(0.6), 0.2, 0.1, 0.9)
		_rubble.add_child(chunk)
	_rubble.visible = false
	add_child(_rubble)

	_prompt = Label3D.new()
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.font_size = 40
	_prompt.outline_size = 6
	_prompt.position.y = 1.6
	_prompt.visible = false
	add_child(_prompt)

	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 2.5
	cs.shape = sph
	area.add_child(cs)
	area.input_ray_pickable = true
	area.input_event.connect(func(_c, ev, _p, _n, _i):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			if broken:
				try_rebuild()
			else:
				take_hit(10))
	add_child(area)

func take_hit(amount: int) -> void:
	if broken:
		return
	hp -= amount
	SkillVFX.hit_spark(self, global_position)
	if hp <= 0:
		_demolish()

func _demolish() -> void:
	broken = true
	_visual.visible = false
	_rubble.visible = true
	_prompt.text = "🔨 E to rebuild (%d 🧩)" % REBUILD_COST
	_prompt.visible = true
	EconomyManager.earn_currency("fragments", SALVAGE, "demolition_salvage")
	Hope.record("demolish", {"at": str(global_position)})
	demolished.emit(self)

func try_rebuild() -> void:
	if not broken:
		return
	if not await EconomyManager.spend_currency("fragments", REBUILD_COST, "rebuild_prop"):
		NotificationUI.notify_error("Rebuilding takes %d 🧩 fragments." % REBUILD_COST)
		return
	broken = false
	hp = max_hp
	_visual.visible = true
	_rubble.visible = false
	_prompt.visible = false
	SkillVFX.aoe_ring(self, global_position, 1.5, Color(0.5, 0.9, 0.6))
	rebuilt.emit(self)
