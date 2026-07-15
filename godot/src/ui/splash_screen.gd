extends Control
class_name SplashScreen
# Initial loading screen shown before the login scene

signal loading_complete()

var _progress_bar: ProgressBar
var _status_label: Label
var _progress: float = 0.0
var _done: bool = false

const LOGO_PATH := "res://assets/ui/logo.png"

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
	vbox.custom_minimum_size = Vector2(520, 420)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	if ResourceLoader.exists(LOGO_PATH):
		var logo := TextureRect.new()
		logo.texture = load(LOGO_PATH)
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.custom_minimum_size = Vector2(320, 320)
		logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(logo)
	else:
		var logo_label := Label.new()
		logo_label.text = "PERILIMINAL.SPACE"
		logo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		logo_label.add_theme_font_size_override("font_size", 48)
		vbox.add_child(logo_label)

	var tagline = Label.new()
	tagline.text = "Six realities. One of you."
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
	# Kick core systems while the cosmetic bar advances so login lands in
	# GameState.LOGIN and restored sessions can skip straight to title.
	if GameManager and GameManager.game_state == GameManager.GameState.LOADING:
		GameManager.initialize()
	for i in range(LOADING_STEPS.size()):
		_status_label.text = LOADING_STEPS[i]
		var target = float(i + 1) / LOADING_STEPS.size() * 100.0
		while _progress < target:
			_progress = minf(_progress + 4.0, target)
			_progress_bar.value = _progress
			await get_tree().create_timer(0.04).timeout

	# Wait for init if it is still finishing (restored auth may have already
	# swapped us to the title screen).
	var waited := 0.0
	while GameManager and GameManager.game_state == GameManager.GameState.LOADING and waited < 8.0:
		await get_tree().process_frame
		waited += get_process_delta_time()

	if not is_inside_tree():
		return
	await get_tree().create_timer(0.3).timeout
	_done = true
	loading_complete.emit()
	# If auth already moved us to title during init, do not clobber it.
	if GameManager and GameManager.game_state == GameManager.GameState.WORLD:
		return
	get_tree().change_scene_to_file("res://scenes/ui/login.tscn")
