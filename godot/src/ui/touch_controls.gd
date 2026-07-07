class_name TouchControls
extends CanvasLayer
## Mobile controls: left-thumb virtual joystick (move), right-side buttons
## (JUMP / E interact / hotbar cast 1). Only appears on touch devices —
## desktop never sees it. ThirdPersonController and interaction code read
## the static state (TouchControls.move_vector / consume_jump / consume_interact),
## so nothing else needs a reference to this node.
##
## Sized generously (88px buttons) for thumbs; sits above the game, below
## menus.

static var move_vector := Vector2.ZERO
static var crouch_held := false # hold-to-crouch posture button
static var _jump_queued := false
static var _interact_queued := false

var _stick_base: Control
var _stick_knob: Control
var _stick_center := Vector2.ZERO
var _stick_touch_id := -1

const STICK_RADIUS := 70.0

static func active() -> bool:
	return DisplayServer.is_touchscreen_available()

static func consume_jump() -> bool:
	var j := _jump_queued
	_jump_queued = false
	return j

static func consume_interact() -> bool:
	var i := _interact_queued
	_interact_queued = false
	return i

func _ready() -> void:
	if not TouchControls.active():
		queue_free()
		return
	layer = 60

	# ---- left: virtual joystick ----
	_stick_base = Control.new()
	_stick_base.custom_minimum_size = Vector2(STICK_RADIUS * 2, STICK_RADIUS * 2)
	_stick_base.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_stick_base.position += Vector2(40, -220)
	add_child(_stick_base)
	var base_ring := ColorRect.new()
	base_ring.color = Color(1, 1, 1, 0.08)
	base_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_base.add_child(base_ring)
	_stick_knob = ColorRect.new()
	(_stick_knob as ColorRect).color = Color(1, 1, 1, 0.25)
	_stick_knob.custom_minimum_size = Vector2(56, 56)
	_stick_knob.size = Vector2(56, 56)
	_stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_base.add_child(_stick_knob)
	_center_knob()

	# ---- right: action buttons ----
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	col.position += Vector2(-140, -424)
	col.add_theme_constant_override("separation", 16)
	add_child(col)
	col.add_child(_action_button("⤴", func(): TouchControls._jump_queued = true))
	# Posture: hold to crouch, release to stand.
	var crouch_btn := _action_button("⤵", func(): pass)
	crouch_btn.button_down.connect(func(): TouchControls.crouch_held = true)
	crouch_btn.button_up.connect(func(): TouchControls.crouch_held = false)
	col.add_child(crouch_btn)
	col.add_child(_action_button("E", func(): TouchControls._interact_queued = true))
	col.add_child(_action_button("⚔", func():
		# Fire hotbar slot 1 by injecting the key event the HotbarUI reads.
		var ev := InputEventKey.new()
		ev.keycode = KEY_1
		ev.pressed = true
		Input.parse_input_event(ev)))

func _exit_tree() -> void:
	# Never let a held control outlive its scene.
	TouchControls.crouch_held = false
	TouchControls.move_vector = Vector2.ZERO

func _action_button(label: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(88, 88)
	b.add_theme_font_size_override("font_size", 34)
	b.pressed.connect(on_press)
	return b

func _center_knob() -> void:
	_stick_knob.position = Vector2(STICK_RADIUS, STICK_RADIUS) - _stick_knob.size / 2.0
	_stick_center = _stick_base.global_position + Vector2(STICK_RADIUS, STICK_RADIUS)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var inside := event.position.distance_to(_stick_center) <= STICK_RADIUS * 1.6
		if event.pressed and _stick_touch_id == -1 and inside:
			_stick_touch_id = event.index
			_update_stick(event.position)
		elif not event.pressed and event.index == _stick_touch_id:
			_stick_touch_id = -1
			TouchControls.move_vector = Vector2.ZERO
			_center_knob()
	elif event is InputEventScreenDrag and event.index == _stick_touch_id:
		_update_stick(event.position)

func _update_stick(touch_pos: Vector2) -> void:
	var offset := (touch_pos - _stick_center).limit_length(STICK_RADIUS)
	TouchControls.move_vector = offset / STICK_RADIUS
	_stick_knob.position = Vector2(STICK_RADIUS, STICK_RADIUS) + offset - _stick_knob.size / 2.0
