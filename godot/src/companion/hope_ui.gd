class_name HopeUI
extends CanvasLayer
## Hope on YOUR screen — always. A corner presence showing stage, bond,
## and what Hope most recently understood about you. Only your client
## renders this; the world only ever sees Hope during synergy manifests.

var _face: Label
var _status: Label

func _ready() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	box.position.x -= 240
	box.position.y += 8
	box.custom_minimum_size = Vector2(230, 0)
	add_child(box)

	_face = Label.new()
	_face.add_theme_font_size_override("font_size", 18)
	box.add_child(_face)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.85, 0.8, 0.6)
	box.add_child(_status)

	Hope.bond_gained.connect(func(_t, _s): _refresh())
	Hope.observation.connect(func(_e, drive):
		_status.text = "…it noticed. (%s)" % drive
		get_tree().create_timer(4.0).timeout.connect(_refresh))
	Hope.manifested.connect(func():
		_face.modulate = Color(1.0, 0.95, 0.5)
		get_tree().create_timer(1.5).timeout.connect(func():
			_face.modulate = Color.WHITE))
	_refresh()

func _refresh() -> void:
	var s := Hope.stage()
	# Mannerisms drift with the profile: an aggressive player's Hope leans
	# forward; a cautious one's Hope sits half-hidden.
	var mood := "⟢" if Hope.profile.caution > Hope.profile.aggression else "⟣"
	_face.text = "%s Hope — %s (bond %d)" % [mood, s.name, Hope.bond]
	_status.text = s.desc
