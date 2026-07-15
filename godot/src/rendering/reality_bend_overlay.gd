class_name RealityBendOverlay
extends CanvasLayer
## The screen-space "wrongness" pass. One ColorRect running
## reality_bend.gdshader over the whole viewport, intensity tuned per
## layer and nudged live by Hope's anxiety axis — the game's own psych
## telemetry reaching out and touching the picture, not just the numbers.
##
## At higher bend (Liminal / Periliminal), CRT + VHS + dither overlays
## from assets/shaders/ fade in on top (godotshaders.com–style mood,
## mobile-safe canvas_item shaders).
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
var _crt_rect: ColorRect
var _vhs_rect: ColorRect
var _dither_rect: ColorRect
var _crt_mat: ShaderMaterial
var _vhs_mat: ShaderMaterial
var _dither_mat: ShaderMaterial

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

	_crt_mat = _make_overlay_mat("res://assets/shaders/crt_overlay.gdshader")
	_vhs_mat = _make_overlay_mat("res://assets/shaders/vhs_overlay.gdshader")
	_dither_mat = _make_overlay_mat("res://assets/shaders/dither_overlay.gdshader")
	_crt_rect = _make_overlay_rect(_crt_mat)
	_vhs_rect = _make_overlay_rect(_vhs_mat)
	_dither_rect = _make_overlay_rect(_dither_mat)
	add_child(_dither_rect)
	add_child(_crt_rect)
	add_child(_vhs_rect)
	_sync_mood_overlays(_base_intensity)

func _make_overlay_mat(path: String) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	var sh: Shader = load(path)
	if sh:
		mat.shader = sh
	return mat

func _make_overlay_rect(mat: ShaderMaterial) -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.material = mat
	r.visible = false
	r.modulate = Color(1, 1, 1, 0)
	return r

func _process(delta: float) -> void:
	# Anxiety pushes the bend further than the layer baseline alone —
	# a fearful player's own screen gets less stable.
	var anxiety: float = float(Hope.profile.get("anxiety", 0.0)) if Hope else 0.0
	var target := clampf(_base_intensity + anxiety * 0.25, 0.0, 1.0)
	var current: float = _mat.get_shader_parameter("intensity")
	var next := move_toward(current, target, delta * 0.15)
	_mat.set_shader_parameter("intensity", next)
	_sync_mood_overlays(next)

func _sync_mood_overlays(intensity: float) -> void:
	# CRT starts around liminal, VHS/dither ramp harder into periliminal.
	var crt_a := clampf((intensity - 0.2) / 0.5, 0.0, 0.55)
	var vhs_a := clampf((intensity - 0.35) / 0.45, 0.0, 0.45)
	var dit_a := clampf((intensity - 0.25) / 0.5, 0.0, 0.4)
	_set_overlay(_crt_rect, crt_a)
	_set_overlay(_vhs_rect, vhs_a)
	_set_overlay(_dither_rect, dit_a)

func _set_overlay(rect: ColorRect, alpha: float) -> void:
	if rect == null:
		return
	rect.visible = alpha > 0.01
	rect.modulate = Color(1, 1, 1, alpha)

func set_intensity(v: float) -> void:
	_base_intensity = v
