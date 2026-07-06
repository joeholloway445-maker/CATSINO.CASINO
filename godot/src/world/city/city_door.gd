class_name CityDoor
extends Node3D
## A real opening door on a city building: slides aside as the player
## approaches, closes behind them. Purely kinetic — the interaction rings
## on venues still own what's INSIDE; this makes the shell feel alive.
## Model slot "city_door" swaps in real door art.

var accent := Color(0.6, 0.6, 0.65)
var width := 2.4
var height := 3.2

var _panel: Node3D
var _open := false
var _closed_x := 0.0

func _ready() -> void:
	var real := AssetLibrary.instance("city_door")
	if real != null:
		_panel = real
	else:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(width, height, 0.18)
		mi.mesh = box
		mi.position.y = height / 2.0
		var mat := AssetLibrary.material("facade_metal", accent.darkened(0.3), 0.2, 0.6, 0.4)
		mat.emission_enabled = true
		mat.emission = accent
		mat.emission_energy_multiplier = 0.15
		mi.material_override = mat
		_panel = mi
	add_child(_panel)
	_closed_x = _panel.position.x

	# Frame posts so the doorway reads even while open.
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.25, height + 0.3, 0.3)
		post.mesh = box
		post.position = Vector3(side * (width / 2.0 + 0.15), (height + 0.3) / 2.0, 0)
		post.material_override = AssetLibrary.material("facade_concrete", Color(0.35, 0.35, 0.4), 0.2, 0.1, 0.7)
		add_child(post)

	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 4.5
	cs.shape = sph
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(func(b: Node3D):
		if b is ThirdPersonController:
			_slide(true))
	area.body_exited.connect(func(b: Node3D):
		if b is ThirdPersonController:
			_slide(false))

func _slide(open: bool) -> void:
	if open == _open:
		return
	_open = open
	var tw := create_tween()
	tw.tween_property(_panel, "position:x",
		_closed_x + (width * 0.95 if open else 0.0), 0.45)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# The door's own voice — a soft mechanical shift, synthesized.
	var player := AudioStreamPlayer3D.new()
	add_child(player)
	var stream := AssetLibrary.sound("door_slide")
	if stream != null:
		player.stream = stream
		player.play()
	player.finished.connect(player.queue_free)
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(player): player.queue_free())
