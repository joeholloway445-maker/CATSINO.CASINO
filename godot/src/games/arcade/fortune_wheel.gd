extends Node
class_name FortuneWheel
# Spinning fortune wheel — 12 segments, server-authoritative result

signal spin_started()
signal spin_result(segment_name: String, multiplier: float, payout: int)
signal error_occurred(message: String)

const SEGMENTS = [
	{name="Void",    mult=0.0,  color=Color(0.1, 0.0, 0.1)},
	{name="Coin",    mult=1.0,  color=Color(0.8, 0.7, 0.0)},
	{name="Coin",    mult=1.0,  color=Color(0.8, 0.7, 0.0)},
	{name="Bronze",  mult=1.5,  color=Color(0.8, 0.5, 0.2)},
	{name="Void",    mult=0.0,  color=Color(0.1, 0.0, 0.1)},
	{name="Bronze",  mult=1.5,  color=Color(0.8, 0.5, 0.2)},
	{name="Silver",  mult=2.0,  color=Color(0.7, 0.7, 0.8)},
	{name="Void",    mult=0.0,  color=Color(0.1, 0.0, 0.1)},
	{name="Silver",  mult=2.0,  color=Color(0.7, 0.7, 0.8)},
	{name="Gold",    mult=3.0,  color=Color(1.0, 0.8, 0.0)},
	{name="Diamond", mult=5.0,  color=Color(0.5, 0.9, 1.0)},
	{name="Royal",   mult=10.0, color=Color(0.8, 0.2, 1.0)},
]

var _spinning: bool = false
var _visual_angle: float = 0.0
var _target_angle: float = 0.0
var _spin_speed: float = 0.0
var _pending_segment: int = -1
var _pending_payout: int = 0
var _result_label: Label
var _bet: int = 50

func _ready() -> void:
	var root := get_parent() if get_parent() else self
	var spin_btn: Button = root.get_node_or_null("SpinButton") as Button
	if spin_btn and not spin_btn.pressed.is_connected(_on_spin_pressed):
		spin_btn.pressed.connect(_on_spin_pressed)
	_result_label = root.get_node_or_null("ResultLabel") as Label
	if _result_label == null and root is Control:
		_result_label = Label.new()
		_result_label.name = "ResultLabel"
		_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_result_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_result_label.offset_top = -80
		(root as Control).add_child(_result_label)
	if not spin_result.is_connected(_on_spin_ui_result):
		spin_result.connect(_on_spin_ui_result)
	if not error_occurred.is_connected(_on_spin_ui_error):
		error_occurred.connect(_on_spin_ui_error)
	_add_back_button(root)

func _add_back_button(root: Node) -> void:
	if root.get_node_or_null("BackBtn"):
		return
	if root is Control:
		var back := Button.new()
		back.name = "BackBtn"
		back.text = "⬅ Back"
		back.position = Vector2(12, 12)
		back.pressed.connect(func() -> void:
			get_tree().change_scene_to_file("res://scenes/world/paw_vegas_hub.tscn"))
		root.add_child(back)

func _on_spin_pressed() -> void:
	spin(_bet)

func _on_spin_ui_result(segment_name: String, multiplier: float, payout: int) -> void:
	if _result_label:
		_result_label.text = "%s (x%.1f) — +%d coins" % [segment_name, multiplier, payout]
	if payout > 0 and NotificationUI:
		NotificationUI.notify_win("Fortune: +%d" % payout)

func _on_spin_ui_error(message: String) -> void:
	if _result_label:
		_result_label.text = message
	if NotificationUI:
		NotificationUI.notify_error(message)

func spin(bet: int) -> void:
	if _spinning:
		error_occurred.emit("Wheel is spinning")
		return
	_spinning = true
	spin_started.emit()
	var payload = JSON.stringify({"bet": bet, "wheel": "fortune"})
	NetworkManager.call_rpc("draw_fortune", payload, func(r): _on_result(r, bet))

func _on_result(result: Dictionary, bet: int) -> void:
	if not result.get("success", false):
		error_occurred.emit(result.get("error", "Server error"))
		_spinning = false
		return

	var seg_idx: int = int(result.get("segment_index", result.get("segment", 0))) % SEGMENTS.size()
	_pending_segment = seg_idx
	_pending_payout = int(result.get("payout", 0))

	# Animate to the result segment
	var full_spins = 5
	var seg_angle = (360.0 / SEGMENTS.size()) * seg_idx
	_target_angle = _visual_angle + 360.0 * full_spins + seg_angle
	_spin_speed = 1800.0

func _process(delta: float) -> void:
	if not _spinning or _pending_segment < 0:
		return

	if _visual_angle < _target_angle:
		_spin_speed = maxf(90.0, _spin_speed - delta * 400.0)
		_visual_angle = minf(_target_angle, _visual_angle + _spin_speed * delta)
		if _visual_angle >= _target_angle:
			_finish_spin()

func _finish_spin() -> void:
	_spinning = false
	var seg = SEGMENTS[_pending_segment]
	spin_result.emit(seg.name, seg.mult, _pending_payout)
	_pending_segment = -1

func get_visual_angle() -> float:
	return fmod(_visual_angle, 360.0)

func is_spinning() -> bool:
	return _spinning
