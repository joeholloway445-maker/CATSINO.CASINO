class_name DayNightSky
extends Node3D
## Procedural sky + sun with a full day/night cycle — built on Godot's
## ProceduralSkyMaterial (no HDRI assets). The palette is catsino-flavored:
## warm neon-violet dusks over Paw Vegas rather than a realistic horizon.

@export var day_length_seconds := 300.0
@export var start_hour := 10.0 # 0-24
## Set by IdentityLens: the player's frame(s) tint every light this sky casts.
var frame_tint := Color(1, 1, 1)
var frame_energy_mult := 1.0

var _sun: DirectionalLight3D
var _env: WorldEnvironment
var _sky_mat: ProceduralSkyMaterial
var _time := 0.0

## Matches ProceduralTerrain.DEFAULT_VIEW_RADIUS(2) * HubRegionData.
## CHUNK_SIZE(64), minus margin so fog fully obscures the edge before
## chunks visibly pop, not exactly at it.
const DEFAULT_FOG_DISTANCE := 100.0

const DAY_TOP := Color(0.30, 0.45, 0.80)
const DAY_HORIZON := Color(0.70, 0.75, 0.85)
const DUSK_TOP := Color(0.25, 0.12, 0.40)
const DUSK_HORIZON := Color(0.95, 0.45, 0.35)
const NIGHT_TOP := Color(0.02, 0.02, 0.08)
const NIGHT_HORIZON := Color(0.10, 0.08, 0.22)

func _ready() -> void:
	_time = start_hour / 24.0 * day_length_seconds

	_sun = DirectionalLight3D.new()
	_sun.shadow_enabled = true
	add_child(_sun)

	_sky_mat = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = _sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	# SSAO/SSIL/SSR/volumetric fog are Forward+ features — the mobile-
	# friendly Compatibility renderer silently ignores or rejects them, so
	# only ask for them where they exist. Glow/tonemap/adjustments work
	# everywhere.
	if not RenderCaps.is_compatibility():
		env.ssao_enabled = true
		env.ssao_intensity = 1.5
		env.ssil_enabled = true
		env.ssr_enabled = true
		env.ssr_max_steps = 32
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.01
		env.volumetric_fog_albedo = Color(0.85, 0.85, 0.95)
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.05
	env.adjustment_saturation = 1.1

	# Simple exponential depth fog — unlike volumetric_fog_enabled above
	# (Forward+-only atmospheric scattering), this works on every renderer
	# including gl_compatibility, and its whole job is masking the terrain
	# streaming edge: chunks pop in/out at ProceduralTerrain's view radius,
	## and fog hides that boundary instead of showing a visible "wall" of
	# terrain appearing/disappearing at a hard distance.
	env.fog_enabled = true
	env.fog_light_energy = 1.0
	_set_fog_density_for_distance(env, DEFAULT_FOG_DISTANCE)

	_env = WorldEnvironment.new()
	_env.environment = env
	add_child(_env)

	_apply(_day_fraction())

func _process(delta: float) -> void:
	_time = fmod(_time + delta, day_length_seconds)
	_apply(_day_fraction())

func _day_fraction() -> float:
	return _time / day_length_seconds

## 0.0 = midnight, 0.5 = noon.
func _apply(t: float) -> void:
	var sun_angle := (t - 0.25) * TAU # sunrise at t=0.25
	_sun.rotation = Vector3(-sun_angle, deg_to_rad(30.0), 0.0)

	# Daylight factor: 1 at noon, 0 at night, smooth through dusk/dawn.
	var elevation := sin(sun_angle)
	var daylight := clampf(elevation * 2.0 + 0.5, 0.0, 1.0)
	var duskness := clampf(1.0 - absf(elevation) * 4.0, 0.0, 1.0)

	_sun.light_energy = maxf(daylight * 1.3, 0.05) * frame_energy_mult
	_sun.light_color = (Color(1.0, 0.95, 0.85).lerp(Color(1.0, 0.55, 0.35), duskness)) * frame_tint

	var top := NIGHT_TOP.lerp(DAY_TOP, daylight).lerp(DUSK_TOP, duskness * 0.7)
	var horizon := NIGHT_HORIZON.lerp(DAY_HORIZON, daylight).lerp(DUSK_HORIZON, duskness * 0.8)
	_sky_mat.sky_top_color = top * frame_tint
	_sky_mat.sky_horizon_color = horizon.lerp(horizon * frame_tint, 0.5)
	_sky_mat.ground_bottom_color = horizon.darkened(0.6)
	_sky_mat.ground_horizon_color = horizon
	if _env != null:
		_env.environment.fog_light_color = horizon

func current_hour() -> float:
	return _day_fraction() * 24.0

## Called by layer_world.gd/overworld.gd whenever ProceduralTerrain's view
## radius changes (vehicle enter/exit), so fog and the streaming edge stay
## visually in sync — a bigger loaded radius needs fog pushed back to
## match, or the "wall" the fog was hiding just moves further out but
## stays just as visible.
func set_fog_distance(world_units: float) -> void:
	if _env == null:
		return
	_set_fog_density_for_distance(_env.environment, world_units)

## Exponential fog has no hard cutoff distance to set directly — density
## is tuned so the fog reaches ~98% opacity by the given distance, which
## reads as "fully obscured" without being a physically exact formula.
func _set_fog_density_for_distance(env: Environment, world_units: float) -> void:
	env.fog_density = clampf(4.0 / maxf(world_units, 10.0), 0.001, 0.05)
