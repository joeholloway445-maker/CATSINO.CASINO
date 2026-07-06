class_name LogoEmblem
extends Control
## The Periliminal.Space emblem, drawn procedurally until final key art
## lands (drop assets/ui/logo.png in and this yields to it automatically).
## The brief: dark mystery, futuristic AND ancient — a shadowy humanoid
## figure, discreet but overwhelming, a God of gods, standing inside a
## geometrically broken/glitched 9-point star, wrapped by TWO ouroboros
## rings blended from all elements / entity categories in yin-yang
## contrast (one ring light-aspected, one dark, each carrying the other's
## seed color).
##
## Category palette follows WorldEntity.CATEGORY_GLOW so the serpents are
## literally made of the six entity types.

const CATEGORY_COLORS := [
	Color(1.0, 0.9, 0.3),   # Energy
	Color(0.5, 0.15, 0.15), # Entropy
	Color(0.3, 0.4, 0.9),   # Gravity
	Color(0.55, 0.45, 0.3), # Matter
	Color(0.8, 0.3, 0.9),   # Psyche
	Color(0.3, 0.9, 0.85),  # Quantum
]

var _t := 0.0
var _glitch_seed := 0
var _texture: Texture2D = null

func _ready() -> void:
	custom_minimum_size = Vector2(280, 280)
	# Final key art wins the moment it exists.
	if ResourceLoader.exists("res://assets/ui/logo.png"):
		_texture = load("res://assets/ui/logo.png")

func _process(delta: float) -> void:
	_t += delta
	# Re-roll the glitch displacement a few times a second, not per frame —
	# broken geometry should snap, not shimmer.
	if int(_t * 6.0) != _glitch_seed:
		_glitch_seed = int(_t * 6.0)
		queue_redraw()

func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) * 0.5
	if _texture != null:
		draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false)
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = _glitch_seed

	# ---- the two ouroboros: outer light-aspected, inner dark-aspected ----
	_draw_ouroboros(c, r * 0.97, 6.0, false, rng)  # light serpent, clockwise
	_draw_ouroboros(c, r * 0.85, 5.0, true, rng)   # dark serpent, counter

	# ---- the broken 9-point star ----
	var pts: Array[Vector2] = []
	for i in 9:
		var ang := -PI / 2.0 + TAU * float(i) / 9.0
		var p := c + Vector2(cos(ang), sin(ang)) * r * 0.72
		# geometric break: a third of the vertices are glitch-displaced
		if rng.randf() < 0.33:
			p += Vector2(rng.randf_range(-8, 8), rng.randf_range(-8, 8))
		pts.append(p)
	# 9-point star as {9/4} polygram: connect every 4th vertex.
	for i in 9:
		var a := pts[i]
		var b := pts[(i + 4) % 9]
		# occasional segment drops out entirely — the glitch eats it
		if rng.randf() < 0.12:
			continue
		draw_line(a, b, Color(0.75, 0.7, 0.95, 0.8), 2.0, true)
		# chromatic ghost of the same segment, offset — the glitch echo
		var off := Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3))
		draw_line(a + off, b + off, Color(0.4, 0.9, 0.95, 0.25), 1.0, true)

	# ---- the figure: discreet, overpowering ----
	_draw_figure(c, r, rng)

## A serpent ring built from arc segments cycling through all six entity
## categories. `dark` inverts the palette toward shadow (yin to the other's
## yang) while keeping one bright "seed" segment of the opposite aspect.
func _draw_ouroboros(c: Vector2, radius: float, width: float, dark: bool, rng: RandomNumberGenerator) -> void:
	var segs := 48
	var dir := -1.0 if dark else 1.0
	var spin := _t * 0.12 * dir
	for i in segs:
		var a0 := spin + TAU * float(i) / segs
		var a1 := spin + TAU * float(i + 1) / segs + 0.01
		var col: Color = CATEGORY_COLORS[i % CATEGORY_COLORS.size()]
		if dark:
			col = col.darkened(0.55)
		# the yin-yang seed: one segment carries the OTHER ring's aspect
		if i == 0:
			col = col.lightened(0.5) if dark else col.darkened(0.6)
		col.a = 0.9
		draw_arc(c, radius, a0, a1, 6, col, width, true)
	# the head eating the tail: a small wedge + eye at the seam
	var head_ang := spin
	var head := c + Vector2(cos(head_ang), sin(head_ang)) * radius
	draw_circle(head, width * 1.1, Color(0.1, 0.08, 0.14) if dark else Color(0.9, 0.88, 0.95))
	draw_circle(head, width * 0.35, Color(1.0, 0.3, 0.25) if dark else Color(0.2, 0.9, 0.9))

## The shadowy God-of-gods: a near-black silhouette that reads as a robed
## humanoid, one point of light where a face should be — drawn LAST so it
## quietly owns everything behind it.
func _draw_figure(c: Vector2, r: float, rng: RandomNumberGenerator) -> void:
	var h := r * 0.9
	var w := r * 0.34
	var top := c + Vector2(0, -h * 0.52)
	var shadow := Color(0.02, 0.01, 0.05, 0.96)
	# robe: a tall tapering polygon, hem slightly glitch-torn
	var hem_y := c.y + h * 0.5
	var robe := PackedVector2Array([
		top + Vector2(-w * 0.28, 0),
		top + Vector2(w * 0.28, 0),
		Vector2(c.x + w * 0.55, hem_y + rng.randf_range(-3, 3)),
		Vector2(c.x + w * 0.2, hem_y + rng.randf_range(-4, 2)),
		Vector2(c.x - w * 0.2, hem_y + rng.randf_range(-4, 2)),
		Vector2(c.x - w * 0.55, hem_y + rng.randf_range(-3, 3)),
	])
	draw_colored_polygon(robe, shadow)
	# head: hooded void
	draw_circle(top + Vector2(0, -w * 0.22), w * 0.3, shadow)
	# presence: a faint aura no wider than the figure — overwhelming
	# because of what it ISN'T showing
	for i in 3:
		var aura := Color(0.5, 0.35, 0.8, 0.05)
		draw_circle(c + Vector2(0, -h * 0.1), w * (0.9 + i * 0.35), aura)
	# the single light: not two eyes — one point, off-center, watching
	var eye := top + Vector2(w * 0.06, -w * 0.2)
	var pulse := 0.6 + 0.4 * sin(_t * 1.7)
	draw_circle(eye, 2.2, Color(0.95, 0.9, 1.0, pulse))
