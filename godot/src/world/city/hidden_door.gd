class_name HiddenDoor
extends Node3D
## A liminal breach wearing a normal door's face. Seeded randomly through
## every Supraliminal city, it is VISUALLY IDENTICAL to any other CityDoor —
## no glow, no label, no aura, no sound cue. The only way to know is to
## walk through it: the doorway keeps going, and you are in the Liminal.
##
## Finding one is meant to feel like finding a real secret. What a player
## does with it — keeps it, tells their guild, sells the location — is
## entirely up to them. The game never marks it on any map.

var door_id := ""
var accent := Color(0.6, 0.6, 0.65)

var _fired := false

func _ready() -> void:
	# The disguise IS a CityDoor — same mesh, same slide, same frame posts.
	# Any tell here would defeat the entire point.
	var face := CityDoor.new()
	face.accent = accent
	add_child(face)

	# The breach: a thin trigger just past the panel. You only cross it by
	# actually stepping THROUGH the open door, not by brushing past it.
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 3.0, 0.5)
	cs.shape = box
	area.add_child(cs)
	area.position = Vector3(0, 1.6, -0.7)
	add_child(area)
	area.body_entered.connect(func(b: Node3D):
		if b is ThirdPersonController:
			_fall_through())

func _fall_through() -> void:
	if _fired:
		return
	_fired = true
	# Hope saw you find it. Knoll now knows you're a threshold-finder.
	Hope.record("hidden_door_found", {"door": door_id})
	Hope.observe_door("hidden_" + door_id, "rushed", 0.0)
	NotificationUI.notify_win("The doorway keeps going. The city sounds are gone. You found one. 🚪")
	LayerManager.transition_to("liminal", true)
