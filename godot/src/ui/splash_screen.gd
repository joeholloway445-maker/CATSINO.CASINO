extends Control
class_name SplashScreen
# Initial loading screen shown before the login scene

signal loading_complete()

var _progress_bar: ProgressBar
var _status_label: Label
var _logo_label: Label
var _progress: float = 0.0
var _done: bool = false

const LOADING_STEPS = [
	"Initializing game world...",
	"Loading faction data...",
	"Connecting to Paw Vegas...",
	"Waking up companions...",
	"Shuffling the deck...",
	"Spinning up the reels...",
	"Almost ready...",
]

func _ready() -> void:
	_build_ui()
	_start_loading()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.0, 0.05)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(500, 300)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	_logo_label = Label.new()
	_logo_label.text = "CATSINO.CASINO"
	_logo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_logo_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(_logo_label)

	var tagline = Label.new()
	tagline.text = "The world's most stylish cat casino MMO"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.modulate = Color(0.6, 0.4, 0.9)
	vbox.add_child(tagline)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(400, 12)
	_progress_bar.value = 0
	_progress_bar.max_value = 100
	_progress_bar.show_percentage = false
	vbox.add_child(_progress_bar)

	_status_label = Label.new()
	_status_label.text = "Loading..."
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.modulate = Color(0.6, 0.6, 0.6)
	vbox.add_child(_status_label)

func _start_loading() -> void:
	for i in range(LOADING_STEPS.size()):
		_status_label.text = LOADING_STEPS[i]
		var target = float(i + 1) / LOADING_STEPS.size() * 100.0
		while _progress < target:
			_progress = minf(_progress + 4.0, target)
			_progress_bar.value = _progress
			await get_tree().create_timer(0.04).timeout

	await get_tree().create_timer(0.3).timeout
	_done = true
	loading_complete.emit()
	get_tree().change_scene_to_file("res://scenes/ui/login.tscn")
