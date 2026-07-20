class_name TouchControls
extends CanvasLayer
## Mobile controls. Testing target #1 — this game ships to phones first.
## Left thumb owns MOVE (floating virtual joystick — touch anywhere on the
## left half and the stick appears under your finger), right thumb owns LOOK
## (drag on the right half rotates the camera), plus a column of action
## buttons: JUMP / E interact / cast slot 1 / SPRINT (hold).
##
## Only appears on touch devices — desktop never sees it. Everything the
## rest of the code reads is a STATIC field, so no one needs a reference
## to this node:
##   TouchControls.move_vector      Vector2 in [-1, 1]
##   TouchControls.look_delta       Vector2 pixels since last frame; consume
##   TouchControls.sprint_held      bool while the sprint button is pressed
##   TouchControls.crouch_held      bool while the posture button is held
##   TouchControls.consume_jump()   true once, resets
##   TouchControls.consume_interact() true once, resets
##
## Sizes are phone-thumb friendly (132px buttons, 96px joystick radius) and
## every UI element respects safe-area insets so it stays clear of notches,
## home indicators, and the joystick's own footprint.

static var move_vector := Vector2.ZERO
static var crouch_held := false # hold-to-crouch posture button
static var look_delta := Vector2.ZERO
static var sprint_held := false
static var _jump_queued := false
static var _interact_queued := false

## Held states for vehicle piloting (land/water/air/space) — distinct from
## the one-shot jump queue above, since vertical thrust needs continuous
## "held" semantics, not a single tap. Reuses the same physical buttons as
## on-foot jump/sprint (dual-wired: press still queues the one-shot jump
## for on-foot use, AND tracks held state for when a vehicle is piloted).
static var jump_held := false
## Roll is vehicle-only (space craft; no on-foot equivalent), so it gets
## its own small button pair rather than overloading an existing one.
static var roll_left_held := false
static var roll_right_held := false

var _stick_base: Control
var _stick_knob: Control
var _stick_center := Vector2.ZERO
var _stick_home_position := Vector2.ZERO
var _stick_touch_id := -1
var _look_touch_id := -1
var _look_last_pos := Vector2.ZERO

const STICK_RADIUS_BASE := 96.0
const BUTTON_SIZE_BASE := 132.0

var _stick_radius := STICK_RADIUS_BASE
var _button_size := BUTTON_SIZE_BASE
var _boost := 1.0

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
	_boost = PhoneUI.boost()
	var scale_mul := maxf(_boost * 0.55, 1.0)
	_stick_radius = STICK_RADIUS_BASE * scale_mul
	_button_size = BUTTON_SIZE_BASE * scale_mul
	var safe := _safe_area()

	# ---- left: floating virtual joystick (home rest pose) ----
	_stick_base = Control.new()
	_stick_base.custom_minimum_size = Vector2(_stick_radius * 2, _stick_radius * 2)
	_stick_base.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_stick_base.position += Vector2(safe.position.x + 32, -(safe.size.y + _stick_radius * 2 + 60))
	_stick_home_position = _stick_base.position
	_stick_base.modulate = Color(1, 1, 1, 0.75)
	add_child(_stick_base)
	var base_ring := ColorRect.new()
	base_ring.color = Color(1, 1, 1, 0.28)
	base_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_base.add_child(base_ring)
	_stick_knob = ColorRect.new()
	(_stick_knob as ColorRect).color = Color(1, 1, 1, 0.62)
	var knob := 76.0 * scale_mul
	_stick_knob.custom_minimum_size = Vector2(knob, knob)
	_stick_knob.size = Vector2(knob, knob)
	_stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_base.add_child(_stick_knob)
	_center_knob()

	# ---- right: action buttons ----
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	col.position += Vector2(-(safe.position.y + _button_size + 28), -(safe.size.y + _button_size * 6 + 72))
	col.add_theme_constant_override("separation", int(16.0 * maxf(_boost * 0.4, 1.0)))
	add_child(col)
	col.add_child(_dual_button("JUMP", func(): TouchControls._jump_queued = true,
		func(held: bool): TouchControls.jump_held = held))
	# Posture: hold to crouch, release to stand.
	var crouch_btn := _action_button("CROUCH", func(): pass)
	crouch_btn.button_down.connect(func(): TouchControls.crouch_held = true)
	crouch_btn.button_up.connect(func(): TouchControls.crouch_held = false)
	col.add_child(crouch_btn)
	col.add_child(_action_button("TALK", func(): TouchControls._interact_queued = true))
	col.add_child(_action_button("ATK", func():
		var ev := InputEventKey.new()
		ev.keycode = KEY_1
		ev.pressed = true
		Input.parse_input_event(ev)))
	col.add_child(_hold_button("SPRINT", func(held: bool): TouchControls.sprint_held = held))

	# Compact roll pair — space/air bank only.
	var roll_row := HBoxContainer.new()
	roll_row.add_theme_constant_override("separation", 10)
	col.add_child(roll_row)
	roll_row.add_child(_small_hold_button("◀ROLL", func(held: bool): TouchControls.roll_left_held = held))
	roll_row.add_child(_small_hold_button("ROLL▶", func(held: bool): TouchControls.roll_right_held = held))

func _process(_delta: float) -> void:
	# Replay touch "E" as a real key event here, on this always-alive
	# CanvasLayer, rather than inside whatever controller happens to be
	# active — a piloted vehicle disables the on-foot controller's
	# _physics_process, which would otherwise silently swallow this.
	if TouchControls.consume_interact():
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.physical_keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)

func _exit_tree() -> void:
	# Never let a held control outlive its scene.
	TouchControls.crouch_held = false
	TouchControls.move_vector = Vector2.ZERO

func _action_button(label: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(_button_size, _button_size * 0.85)
	var fs := maxf(_boost * 0.55, 1.0)
	b.add_theme_font_size_override("font_size", int(round(26.0 * fs)))
	b.pressed.connect(on_press)
	return b

## Hold-to-fire button (sprint). Callable receives true on press, false on
## release, so the state is authoritative even if a touch ends off-button.
func _hold_button(label: String, on_state: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(_button_size, _button_size * 0.85)
	var fs := maxf(_boost * 0.55, 1.0)
	b.add_theme_font_size_override("font_size", int(round(24.0 * fs)))
	b.button_down.connect(func(): on_state.call(true))
	b.button_up.connect(func(): on_state.call(false))
	return b

## Half-size hold button, for secondary controls (space-vehicle roll)
## that shouldn't compete visually with the primary action column.
func _small_hold_button(label: String, on_state: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(_button_size * 0.55, _button_size * 0.5)
	var fs := maxf(_boost * 0.55, 1.0)
	b.add_theme_font_size_override("font_size", int(round(18.0 * fs)))
	b.button_down.connect(func(): on_state.call(true))
	b.button_up.connect(func(): on_state.call(false))
	return b

## Same button, wired for both semantics: a single press queues the
## one-shot jump (on-foot), while press/release also tracks a continuous
## held state (vehicle vertical thrust) — the two consumers read whichever
## field is relevant to their context, so nothing needs to know about the
## other's existence.
func _dual_button(label: String, on_press: Callable, on_held: Callable) -> Button:
	var b := _action_button(label, on_press)
	b.button_down.connect(func(): on_held.call(true))
	b.button_up.connect(func(): on_held.call(false))
	return b

func _center_knob() -> void:
	_stick_knob.position = Vector2(_stick_radius, _stick_radius) - _stick_knob.size / 2.0
	_stick_center = _stick_base.global_position + Vector2(_stick_radius, _stick_radius)

## Floating stick: place the base so its center sits under the finger,
## matching how look-drag works on the right half (touch anywhere left).
func _place_stick_at(screen_pos: Vector2) -> void:
	_stick_center = screen_pos
	_stick_base.global_position = screen_pos - Vector2(_stick_radius, _stick_radius)
	_stick_knob.position = Vector2(_stick_radius, _stick_radius) - _stick_knob.size / 2.0
	_stick_base.modulate = Color(1, 1, 1, 1)

func _reset_stick_home() -> void:
	_stick_base.position = _stick_home_position
	_stick_base.modulate = Color(1, 1, 1, 0.55)
	_center_knob()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		# Left half → floating joystick (anywhere, not just the rest pad).
		# Right half → camera-look drag (buttons still eat their own presses).
		if event.pressed:
			if _stick_touch_id == -1 and event.position.x < _viewport_width() * 0.5:
				_stick_touch_id = event.index
				_place_stick_at(event.position)
				_update_stick(event.position)
			elif _look_touch_id == -1 and event.position.x > _viewport_width() * 0.5:
				_look_touch_id = event.index
				_look_last_pos = event.position
		else:
			if event.index == _stick_touch_id:
				_stick_touch_id = -1
				TouchControls.move_vector = Vector2.ZERO
				_reset_stick_home()
			elif event.index == _look_touch_id:
				_look_touch_id = -1
	elif event is InputEventScreenDrag:
		if event.index == _stick_touch_id:
			_update_stick(event.position)
		elif event.index == _look_touch_id:
			TouchControls.look_delta += event.position - _look_last_pos
			_look_last_pos = event.position

func _update_stick(touch_pos: Vector2) -> void:
	var offset := (touch_pos - _stick_center).limit_length(_stick_radius)
	TouchControls.move_vector = offset / _stick_radius
	_stick_knob.position = Vector2(_stick_radius, _stick_radius) + offset - _stick_knob.size / 2.0

func _viewport_width() -> float:
	return float(get_viewport().get_visible_rect().size.x)

## Safe-area insets in pixels: (left, right, top, bottom). Falls back to
## a sensible default when the OS doesn't report any (desktop, most
## browsers) — never zero, so buttons never kiss the screen edge.
func _safe_area() -> Rect2:
	var r := DisplayServer.get_display_safe_area() if DisplayServer.has_method("get_display_safe_area") else Rect2i()
	var screen := DisplayServer.screen_get_size()
	if r.size.x <= 0 or r.size.y <= 0:
		return Rect2(24.0 * _boost, 24.0 * _boost, 24.0 * _boost, 24.0 * _boost)
	var left := float(r.position.x)
	var top := float(r.position.y)
	var right := float(screen.x - (r.position.x + r.size.x))
	var bottom := float(screen.y - (r.position.y + r.size.y))
	var pad := 16.0 * _boost
	return Rect2(maxf(left, pad), maxf(right, pad), maxf(top, pad), maxf(bottom, pad))
