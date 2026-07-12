class_name TouchControls
extends CanvasLayer
## Mobile controls. Testing target #1 — this game ships to phones first.
## Left thumb owns MOVE (virtual joystick), right thumb owns LOOK (drag on
## the right half of the screen rotates the camera), plus a column of
## action buttons: JUMP / E interact / cast slot 1 / SPRINT (hold).
##
## Only appears on touch devices — desktop never sees it. Everything the
## rest of the code reads is a STATIC field, so no one needs a reference
## to this node:
##   TouchControls.move_vector      Vector2 in [-1, 1]
##   TouchControls.look_delta       Vector2 pixels since last frame; consume
##   TouchControls.sprint_held      bool while the sprint button is pressed
##   TouchControls.consume_jump()   true once, resets
##   TouchControls.consume_interact() true once, resets
##
## Sizes are generous (96px buttons, 80px joystick radius) and every UI
## element respects safe-area insets so it stays clear of notches, home
## indicators, and the joystick's own footprint.

static var move_vector := Vector2.ZERO
static var look_delta := Vector2.ZERO
static var sprint_held := false
static var _jump_queued := false
static var _interact_queued := false

var _stick_base: Control
var _stick_knob: Control
var _stick_center := Vector2.ZERO
var _stick_touch_id := -1
var _look_touch_id := -1
var _look_last_pos := Vector2.ZERO

const STICK_RADIUS := 80.0
const BUTTON_SIZE := 96.0

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

## Read once per frame from the controller. Returns the accumulated drag
## since the last read; the internal delta is cleared.
static func consume_look_delta() -> Vector2:
	var d := look_delta
	look_delta = Vector2.ZERO
	return d

func _ready() -> void:
	if not TouchControls.active():
		queue_free()
		return
	layer = 60
	var safe := _safe_area()

	# ---- left: virtual joystick ----
	_stick_base = Control.new()
	_stick_base.custom_minimum_size = Vector2(STICK_RADIUS * 2, STICK_RADIUS * 2)
	_stick_base.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_stick_base.position += Vector2(safe.position.x + 32, -(safe.size.y + STICK_RADIUS * 2 + 60))
	add_child(_stick_base)
	var base_ring := ColorRect.new()
	base_ring.color = Color(1, 1, 1, 0.10)
	base_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_base.add_child(base_ring)
	_stick_knob = ColorRect.new()
	(_stick_knob as ColorRect).color = Color(1, 1, 1, 0.30)
	_stick_knob.custom_minimum_size = Vector2(64, 64)
	_stick_knob.size = Vector2(64, 64)
	_stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_base.add_child(_stick_knob)
	_center_knob()

	# ---- right: action buttons ----
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	col.position += Vector2(-(safe.position.y + BUTTON_SIZE + 32), -(safe.size.y + BUTTON_SIZE * 4 + 80))
	col.add_theme_constant_override("separation", 18)
	add_child(col)
	col.add_child(_action_button("⤴", func(): TouchControls._jump_queued = true))
	col.add_child(_action_button("E", func(): TouchControls._interact_queued = true))
	col.add_child(_action_button("⚔", func():
		var ev := InputEventKey.new()
		ev.keycode = KEY_1
		ev.pressed = true
		Input.parse_input_event(ev)))
	col.add_child(_hold_button("»»", func(held: bool): TouchControls.sprint_held = held))

func _action_button(label: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	b.add_theme_font_size_override("font_size", 38)
	b.pressed.connect(on_press)
	return b

## Hold-to-fire button (sprint). Callable receives true on press, false on
## release, so the state is authoritative even if a touch ends off-button.
func _hold_button(label: String, on_state: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	b.add_theme_font_size_override("font_size", 34)
	b.button_down.connect(func(): on_state.call(true))
	b.button_up.connect(func(): on_state.call(false))
	return b

func _center_knob() -> void:
	_stick_knob.position = Vector2(STICK_RADIUS, STICK_RADIUS) - _stick_knob.size / 2.0
	_stick_center = _stick_base.global_position + Vector2(STICK_RADIUS, STICK_RADIUS)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var inside_stick: bool = event.position.distance_to(_stick_center) <= STICK_RADIUS * 1.6
		# Left thumb → joystick; anything on the RIGHT half that isn't a
		# button click becomes a camera-look drag.
		if event.pressed:
			if _stick_touch_id == -1 and inside_stick:
				_stick_touch_id = event.index
				_update_stick(event.position)
			elif _look_touch_id == -1 and event.position.x > _viewport_width() * 0.5:
				_look_touch_id = event.index
				_look_last_pos = event.position
		else:
			if event.index == _stick_touch_id:
				_stick_touch_id = -1
				TouchControls.move_vector = Vector2.ZERO
				_center_knob()
			elif event.index == _look_touch_id:
				_look_touch_id = -1
	elif event is InputEventScreenDrag:
		if event.index == _stick_touch_id:
			_update_stick(event.position)
		elif event.index == _look_touch_id:
			TouchControls.look_delta += event.position - _look_last_pos
			_look_last_pos = event.position

func _update_stick(touch_pos: Vector2) -> void:
	var offset := (touch_pos - _stick_center).limit_length(STICK_RADIUS)
	TouchControls.move_vector = offset / STICK_RADIUS
	_stick_knob.position = Vector2(STICK_RADIUS, STICK_RADIUS) + offset - _stick_knob.size / 2.0

func _viewport_width() -> float:
	return float(get_viewport().get_visible_rect().size.x)

## Safe-area insets in pixels: (left, right, top, bottom). Falls back to
## a sensible default when the OS doesn't report any (desktop, most
## browsers) — never zero, so buttons never kiss the screen edge.
func _safe_area() -> Rect2:
	var r := DisplayServer.get_display_safe_area() if DisplayServer.has_method("get_display_safe_area") else Rect2i()
	var screen := DisplayServer.screen_get_size()
	if r.size.x <= 0 or r.size.y <= 0:
		return Rect2(24, 24, 24, 24)
	var left := float(r.position.x)
	var top := float(r.position.y)
	var right := float(screen.x - (r.position.x + r.size.x))
	var bottom := float(screen.y - (r.position.y + r.size.y))
	return Rect2(maxf(left, 16), maxf(right, 16), maxf(top, 16), maxf(bottom, 16))
