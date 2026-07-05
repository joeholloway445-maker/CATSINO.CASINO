class_name RealityBendOverlay
extends CanvasLayer
## The screen-space "wrongness" pass. One ColorRect running
## reality_bend.gdshader over the whole viewport, intensity tuned per
## layer and nudged live by Hope's anxiety axis — the game's own psych
## telemetry reaching out and touching the picture, not just the numbers.
##
## add_child(RealityBendOverlay.new(base_intensity)) from any layer scene.
## Layer baselines (Ready Player One clean -> Stephen King wrong):
##   hyperliminal/subliminal/supraliminal hubs -> 0.0  (stable, yours)
##   supraliminal wilds                         -> 0.05 (a held breath)
##   extraliminal                               -> 0.08 (overlay bleed)
##   liminal                                     -> 0.30 (visibly not fine)
##   periliminal                                 -> 0.55 (it has you now)

var _rect: ColorRect
var _mat: ShaderMaterial
var _base_intensity: float

func _init(base_intensity: float = 0.0) -> void:
	_base_intensity = base_intensity

func _ready() -> void:
	layer = 90 # above gameplay, below top-level menus/notifications
	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := load("res://assets/shaders/reality_bend.gdshader")
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_mat.set_shader_parameter("intensity", _base_intensity)
	_rect.material = _mat
	add_child(_rect)

func _process(delta: float) -> void:
	# Anxiety pushes the bend further than the layer baseline alone —
	# a fearful player's own screen gets less stable.
	var anxiety: float = float(Hope.profile.get("anxiety", 0.0)) if Hope else 0.0
	var target := clampf(_base_intensity + anxiety * 0.25, 0.0, 1.0)
	var current: float = _mat.get_shader_parameter("intensity")
	_mat.set_shader_parameter("intensity", move_toward(current, target, delta * 0.15))

func set_intensity(v: float) -> void:
	_base_intensity = v
