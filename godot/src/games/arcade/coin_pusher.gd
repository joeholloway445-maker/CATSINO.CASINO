extends Node2D

signal coins_pushed(fallen: int, payout: int)

const GRID_WIDTH: int = 10
const GRID_HEIGHT: int = 8
const CASCADE_THRESHOLD: int = 5

var _coin_grid: Dictionary = {}
var _pending_coins: Array[Dictionary] = []

func _ready() -> void:
	_init_grid()

func _init_grid() -> void:
	_coin_grid.clear()
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			_coin_grid[Vector2i(x, y)] = randf() < 0.35

func drop_coin(column: int, bet: int) -> void:
	if EconomyManager == null or not EconomyManager.spend_currency_local("chips", bet, "coin_pusher"):
		push_warning("CoinPusher: insufficient chips")
		return
	column = clampi(column, 0, GRID_WIDTH - 1)
	# Animate new coin dropping into column
	var drop_anim = create_tween()
	var start_y: float = -40.0
	var target_y: float = 40.0
	drop_anim.tween_method(_dummy_tween_cb, start_y, target_y, 0.4)
	await drop_anim.finished
	# Push all coins down one row
	_push_column(column)
	# Count fallen coins (bottom row)
	var fallen: int = _count_fallen()
	var payout: int = _calculate_payout(fallen, bet)
	if payout > 0:
		EconomyManager.earn_currency_local("chips", payout, "coin_pusher_win")
	# Animate fallen coins
	var fall_anim = create_tween()
	fall_anim.tween_interval(0.3)
	await fall_anim.finished
	queue_redraw()
	coins_pushed.emit(fallen, payout)

func _dummy_tween_cb(_v: float) -> void:
	queue_redraw()

func _push_column(column: int) -> void:
	# Shift coins down, add new coin at top
	for y in range(GRID_HEIGHT - 1, 0, -1):
		_coin_grid[Vector2i(column, y)] = _coin_grid.get(Vector2i(column, y - 1), false)
	_coin_grid[Vector2i(column, 0)] = true
	# Apply gravity across full grid — shift all rows down by 1
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT - 1, 0, -1):
			if _coin_grid.get(Vector2i(x, y), false) == false and _coin_grid.get(Vector2i(x, y - 1), false):
				_coin_grid[Vector2i(x, y)] = true
				_coin_grid[Vector2i(x, y - 1)] = false

func _count_fallen() -> int:
	var count: int = 0
	for x in range(GRID_WIDTH):
		if _coin_grid.get(Vector2i(x, GRID_HEIGHT - 1), false):
			count += 1
			_coin_grid[Vector2i(x, GRID_HEIGHT - 1)] = false
	return count

func _calculate_payout(fallen_coins: int, bet: int) -> int:
	if fallen_coins == 0:
		return 0
	var base: int = (bet / 10) * fallen_coins
	var cascade_bonus: int = 0
	if fallen_coins > CASCADE_THRESHOLD:
		cascade_bonus = base * (fallen_coins - CASCADE_THRESHOLD)
	return base + cascade_bonus

func _draw() -> void:
	var cell_size: float = 40.0
	var offset: Vector2 = Vector2(50, 50)
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var rect = Rect2(offset + Vector2(x, y) * cell_size, Vector2(cell_size - 2, cell_size - 2))
			draw_rect(rect, Color(0.2, 0.2, 0.3), true)
			if _coin_grid.get(Vector2i(x, y), false):
				var center = offset + Vector2(x, y) * cell_size + Vector2(cell_size * 0.5, cell_size * 0.5)
				draw_circle(center, cell_size * 0.4, Color.GOLD)
