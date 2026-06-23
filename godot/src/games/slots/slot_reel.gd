extends Control

class_name SlotReel

# ─── Signals ─────────────────────────────────────────────────────────────────
signal reel_stopped(symbol: String)

# ─── Constants ───────────────────────────────────────────────────────────────
const SYMBOLS: Array[String] = ["CAT", "FISH", "COIN", "YARN", "BOWL", "CROWN", "STAR", "VOID"]

# ─── Configuration ────────────────────────────────────────────────────────────
@export var symbol_height: float = 80.0
@export var visible_symbols: int = 3

# ─── Child node references ────────────────────────────────────────────────────
# The reel renders a strip of Labels stacked vertically.
# A ClipContainer (or SubViewport) clips them to the visible window.
@onready var strip: VBoxContainer = $ClipContainer/Strip

# ─── Internal state ───────────────────────────────────────────────────────────
var _symbol_labels: Array[Label] = []
var _current_symbol: String = "CAT"
var _spinning: bool = false
var _spin_tween: Tween = null
var _total_strip_symbols: int = 0

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_strip()

func _build_strip() -> void:
	# Clear existing labels
	for child in strip.get_children():
		child.queue_free()
	_symbol_labels.clear()

	# Build enough symbols for seamless looping:
	# visible_symbols + padding above + padding below
	_total_strip_symbols = SYMBOLS.size() * 3  # 3 full cycles for looping
	for i in range(_total_strip_symbols):
		var lbl := Label.new()
		lbl.text = SYMBOLS[i % SYMBOLS.size()]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(0, symbol_height)
		lbl.add_theme_font_size_override("font_size", 28)
		strip.add_child(lbl)
		_symbol_labels.append(lbl)

	# Snap to first symbol initially
	strip.position.y = 0.0
	_current_symbol = _symbol_labels[0].text

# ─── Public API ───────────────────────────────────────────────────────────────
func spin(duration: float) -> void:
	if _spinning:
		return
	_spinning = true

	# Kill any previous tween
	if _spin_tween and _spin_tween.is_valid():
		_spin_tween.kill()

	# How far to travel: scroll through several full SYMBOLS cycles
	var cycles: int = 4 + randi() % 4  # 4-7 full cycles
	var total_travel: float = float(cycles) * float(SYMBOLS.size()) * symbol_height

	# Tween the strip upward (symbols scroll downward visually)
	var start_y: float = strip.position.y
	var end_y: float = start_y - total_travel

	_spin_tween = create_tween()
	_spin_tween.tween_property(strip, "position:y", end_y, duration)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_CUBIC)

func stop_at(symbol: String) -> void:
	_spinning = false
	if _spin_tween and _spin_tween.is_valid():
		_spin_tween.kill()

	var sym_upper := symbol.to_upper()
	if sym_upper not in SYMBOLS:
		sym_upper = SYMBOLS[0]

	_current_symbol = sym_upper

	# Find target symbol index in the middle row of the strip
	var target_idx: int = SYMBOLS.find(sym_upper)
	# We use the second cycle so there is padding above
	var cycle_offset: int = SYMBOLS.size()
	var final_y: float = -float(cycle_offset + target_idx) * symbol_height

	if _spin_tween and _spin_tween.is_valid():
		_spin_tween.kill()

	var snap_tween := create_tween()
	snap_tween.tween_property(strip, "position:y", final_y, 0.3)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
	snap_tween.tween_callback(func() -> void:
		reel_stopped.emit(_current_symbol)
	)

func get_current_symbol() -> String:
	return _current_symbol
