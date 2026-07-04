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

	var seg_idx: int = result.get("segment", 0) % SEGMENTS.size()
	_pending_segment = seg_idx
	_pending_payout = result.get("payout", 0)

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
