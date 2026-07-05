class_name CityLighting
extends Node
## The city's light rig driver. One instance per built city; it holds every
## window band, streetlight, and neon sign and rides their emission/energy
## on the day/night curve read from the layer's DayNightSky. Windows and
## neon glow at night and fade by day; streetlights switch on at dusk.
##
## BuildingBuilder / MegaCityBuilder register their emitters statically via
## the `_current` instance set in `begin()`, so builder code stays simple.

static var _current: CityLighting = null

var _sky: DayNightSky
var _windows: Array[MeshInstance3D] = []
var _street_lights: Array[OmniLight3D] = []
var _neons: Array = [] # {mesh, base_energy}
var _accum := 0.0

## Call before building a city; routes all register_* to this instance.
static func begin(sky: DayNightSky) -> CityLighting:
	var cl := CityLighting.new()
	cl._sky = sky
	_current = cl
	return cl

static func register_window(mesh: MeshInstance3D) -> void:
	if _current:
		_current._windows.append(mesh)

static func register_streetlight(light: OmniLight3D) -> void:
	if _current:
		_current._street_lights.append(light)

static func register_neon(mesh: MeshInstance3D, base_energy: float) -> void:
	if _current:
		_current._neons.append({"mesh": mesh, "base": base_energy})

func _ready() -> void:
	_apply(_night_factor())

func _process(delta: float) -> void:
	# Light state changes slowly — update a few times a second, not per frame.
	_accum += delta
	if _accum < 0.4:
		return
	_accum = 0.0
	_apply(_night_factor())

## 0 at high noon, 1 in the dead of night, smooth through dusk/dawn.
func _night_factor() -> float:
	var hour := _sky.current_hour() if is_instance_valid(_sky) else 21.0
	# Brightest daylight ~13:00, darkest ~01:00.
	var day := clampf(sin((hour - 6.0) / 24.0 * TAU) * 0.5 + 0.5, 0.0, 1.0)
	return clampf(1.0 - day, 0.0, 1.0)

func _apply(night: float) -> void:
	for w in _windows:
		if not is_instance_valid(w):
			continue
		var mat := w.material_override
		if mat is StandardMaterial3D:
			var glow: float = float(w.get_meta("night_glow", 0.7))
			# A little window scatter so not every floor lights identically.
			mat.emission_energy_multiplier = night * glow * 2.2
	for l in _street_lights:
		if is_instance_valid(l):
			l.light_energy = night * 3.0
			l.visible = night > 0.1
	for n in _neons:
		var m: MeshInstance3D = n["mesh"]
		if not is_instance_valid(m):
			continue
		var mat := m.material_override
		if mat is StandardMaterial3D:
			# Neon stays partly lit by day (it's neon) but blooms at night.
			mat.emission_energy_multiplier = float(n["base"]) * (0.35 + night * 0.9)
