class_name HumanMaterials
## PBR materials for PeriHumans — skin with subsurface scattering on a
## melanin ramp, procedurally painted irises, and hair. All generated at
## runtime; no texture files.

# Melanin ramp: pale -> deep, sampled by the skin_melanin gene.
const _MELANIN_STOPS := [
	[0.00, Color(0.96, 0.84, 0.76)],
	[0.30, Color(0.91, 0.71, 0.56)],
	[0.55, Color(0.73, 0.49, 0.33)],
	[0.78, Color(0.49, 0.29, 0.17)],
	[1.00, Color(0.24, 0.14, 0.09)],
]

static func skin_tone(dna: HumanDNA) -> Color:
	var t := dna.get_gene("skin_melanin")
	var tone: Color = _MELANIN_STOPS[0][1]
	for i in range(1, _MELANIN_STOPS.size()):
		var a: float = _MELANIN_STOPS[i - 1][0]
		var b: float = _MELANIN_STOPS[i][0]
		if t <= b:
			tone = (_MELANIN_STOPS[i - 1][1] as Color).lerp(_MELANIN_STOPS[i][1], (t - a) / (b - a))
			break
		tone = _MELANIN_STOPS[i][1]
	# Redness warms the tone; age desaturates it slightly.
	tone = tone.lerp(Color(tone.r, tone.g * 0.82, tone.b * 0.80), dna.get_gene("skin_redness") * 0.35)
	var grey := (tone.r + tone.g + tone.b) / 3.0
	return tone.lerp(Color(grey, grey, grey), dna.get_gene("age") * 0.18)

static func skin(dna: HumanDNA) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = skin_tone(dna)
	mat.vertex_color_use_as_albedo = true  # face paint / base layer live in vertex color
	mat.roughness = lerpf(0.55, 0.78, dna.get_gene("age"))
	mat.metallic = 0.0
	mat.subsurf_scatter_enabled = true
	mat.subsurf_scatter_strength = lerpf(0.10, 0.04, dna.get_gene("skin_melanin"))
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

static func hair(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.42
	mat.metallic = 0.05
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

static func eyeball() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.93, 0.92, 0.91)
	mat.roughness = 0.12
	mat.metallic = 0.0
	return mat

static var _iris_cache: Dictionary = {}

## Radial iris painting: pupil, fibrous iris streaks, limbal ring, alpha
## falloff to transparent so it composites onto the eyeball as a quad.
static func iris_texture(color: Color) -> ImageTexture:
	var key := color.to_html(false)
	if _iris_cache.has(key):
		return _iris_cache[key]
	var size := 96
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half := size / 2.0
	for y in size:
		for x in size:
			var dx := (x - half) / half
			var dy := (y - half) / half
			var r := sqrt(dx * dx + dy * dy)
			if r > 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var ang := atan2(dy, dx)
			var streak := 0.5 + 0.5 * sin(ang * 19.0 + sin(ang * 7.0) * 2.0)
			var c: Color
			if r < 0.34:
				c = Color(0.02, 0.02, 0.03, 1.0)  # pupil
			else:
				var t := (r - 0.34) / 0.66
				c = color.darkened(0.25 * streak).lightened(0.18 * (1.0 - t))
				c = c.lerp(Color(0.05, 0.04, 0.04), smoothstep(0.72, 1.0, r))  # limbal ring
				c.a = clampf((1.0 - r) * 14.0, 0.0, 1.0)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_iris_cache[key] = tex
	return tex

static func iris(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = iris_texture(color)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.08
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return mat
