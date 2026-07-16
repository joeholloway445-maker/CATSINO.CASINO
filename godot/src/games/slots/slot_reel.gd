extends Control

class_name SlotReel

signal reel_stopped(symbol: String)

const SYMBOLS: Array[String] = ["🐱", "🌟", "🎭", "🐾", "💎", "🎰", "⭐", "🔔"]

@export var symbol_height: float = 80.0
@export var visible_symbols: int = 3

var strip: VBoxContainer
var _symbol_labels: Array[Label] = []
var _current_symbol: String = "🐱"
var _spinning: bool = false
var _spin_tween: Tween = null
var _display: Label

func _ready() -> void:
	_ensure_strip()
	_build_strip()

func _ensure_strip() -> void:
	var clip := get_node_or_null("ClipContainer") as Control
	if clip == null:
		clip = Control.new()
		clip.name = "ClipContainer"
		clip.clip_contents = true
		clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(clip)
	strip = clip.get_node_or_null("Strip") as VBoxContainer
	if strip == null:
		strip = VBoxContainer.new()
		strip.name = "Strip"
		clip.add_child(strip)
	_display = get_node_or_null("SymbolLabel") as Label
	if _display == null:
		_display = Label.new()
		_display.name = "SymbolLabel"
		_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_display.add_theme_font_size_override("font_size", 42)
		_display.text = _current_symbol
		add_child(_display)

func _build_strip() -> void:
	if strip == null:
		return
	for child in strip.get_children():
		child.queue_free()
	_symbol_labels.clear()
	for i in range(SYMBOLS.size() * 3):
		var lbl := Label.new()
		lbl.text = SYMBOLS[i % SYMBOLS.size()]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(0, symbol_height)
		lbl.add_theme_font_size_override("font_size", 28)
		strip.add_child(lbl)
		_symbol_labels.append(lbl)
	strip.position.y = 0.0
	_current_symbol = SYMBOLS[0]
	if _display:
		_display.text = _current_symbol

func set_symbol(symbol: String) -> void:
	_current_symbol = str(symbol)
	if _display:
		_display.text = _current_symbol
	if strip and _symbol_labels.size() > 0:
		_symbol_labels[0].text = _current_symbol

func spin(duration: float) -> void:
	if _spinning:
		return
	_spinning = true
	if _spin_tween and _spin_tween.is_valid():
		_spin_tween.kill()
	if strip == null:
		await get_tree().create_timer(duration).timeout
		_spinning = false
		return
	var cycles: int = 4 + randi() % 4
	var total_travel: float = float(cycles) * float(SYMBOLS.size()) * symbol_height
	var start_y: float = strip.position.y
	_spin_tween = create_tween()
	_spin_tween.tween_property(strip, "position:y", start_y - total_travel, duration)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

func stop_at(symbol: String) -> void:
	_spinning = false
	if _spin_tween and _spin_tween.is_valid():
		_spin_tween.kill()
	set_symbol(symbol)
	reel_stopped.emit(_current_symbol)

func get_current_symbol() -> String:
	return _current_symbol
