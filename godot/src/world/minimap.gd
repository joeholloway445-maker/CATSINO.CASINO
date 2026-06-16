extends Control
class_name Minimap
# Minimap showing current district and player position

var _current_district: String = "paw_vegas"
var _player_dot: Control

const DISTRICT_COLORS = {
	"paw_vegas":      Color(0.8, 0.2, 1.0),
	"cat_coliseum":   Color(1.0, 0.3, 0.1),
	"neon_alley":     Color(0.0, 0.9, 1.0),
	"cat_forest":     Color(0.2, 0.9, 0.2),
	"arcade_galaxy":  Color(0.9, 0.8, 0.0),
}

const DISTRICT_POSITIONS = {
	"paw_vegas":     Vector2(0.5, 0.5),
	"cat_coliseum":  Vector2(0.2, 0.3),
	"neon_alley":    Vector2(0.8, 0.4),
	"cat_forest":    Vector2(0.3, 0.7),
	"arcade_galaxy": Vector2(0.7, 0.7),
}

func _ready() -> void:
	custom_minimum_size = Vector2(160, 120)
	_player_dot = ColorRect.new()
	_player_dot.color = Color.WHITE
	_player_dot.size = Vector2(8, 8)
	add_child(_player_dot)

func _draw() -> void:
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.4, 0.0, 0.6, 0.5), false, 1.0)

	# Draw district nodes
	for district in DISTRICT_POSITIONS:
		var pos = DISTRICT_POSITIONS[district] * size
		var color = DISTRICT_COLORS.get(district, Color.GRAY)
		var is_current = district == _current_district
		draw_circle(pos, 6.0 if is_current else 4.0, color)
		if is_current:
			draw_circle(pos, 8.0, color * Color(1, 1, 1, 0.3), false)

	# Draw connections between districts
	var districts = DISTRICT_POSITIONS.keys()
	for i in range(districts.size()):
		for j in range(i + 1, districts.size()):
			var p1 = DISTRICT_POSITIONS[districts[i]] * size
			var p2 = DISTRICT_POSITIONS[districts[j]] * size
			draw_line(p1, p2, Color(0.3, 0.3, 0.3, 0.5), 1.0)

func set_district(district: String) -> void:
	_current_district = district
	var pos = DISTRICT_POSITIONS.get(district, Vector2(0.5, 0.5)) * size
	_player_dot.position = pos - Vector2(4, 4)
	queue_redraw()

func _process(_delta: float) -> void:
	pass
