extends Node
class_name CatPuzzle
# Tile-matching puzzle game — match cat symbols for coins
# Completely client-side visual; server validates final score

signal puzzle_complete(score: int, payout: int)
signal move_made(remaining_moves: int)
signal board_updated(board: Array)

const SYMBOLS = ["🐱", "🌟", "🎭", "🐾", "💎", "⭐"]
const BOARD_SIZE = 6
const MOVE_LIMIT = 30
const MIN_MATCH = 3

var _board: Array = []
var _moves_remaining: int = MOVE_LIMIT
var _score: int = 0
var _bet: int = 0
var _grid: GridContainer
var _score_label: Label
var _moves_label: Label
var _selected: Vector2i = Vector2i(-1, -1)
var _tile_buttons: Array = []

func _ready() -> void:
	var root := get_parent() if get_parent() else self
	_grid = root.get_node_or_null("BoardGrid") as GridContainer
	var info := root.get_node_or_null("InfoBar")
	if info:
		_score_label = info.get_node_or_null("ScoreLabel") as Label
		_moves_label = info.get_node_or_null("MovesLabel") as Label
	if not board_updated.is_connected(_on_board_updated_ui):
		board_updated.connect(_on_board_updated_ui)
	if not move_made.is_connected(_on_move_ui):
		move_made.connect(_on_move_ui)
	if not puzzle_complete.is_connected(_on_puzzle_complete_ui):
		puzzle_complete.connect(_on_puzzle_complete_ui)
	if root is Control:
		var start_btn := Button.new()
		start_btn.text = "Start (15 chips)"
		start_btn.position = Vector2(12, 12)
		start_btn.pressed.connect(func() -> void: start_puzzle(15))
		root.add_child(start_btn)
	start_puzzle(0)  # free practice board; paid start spends via RPC on finish

func _on_board_updated_ui(board: Array) -> void:
	_render_board(board)

func _on_move_ui(remaining: int) -> void:
	if _moves_label:
		_moves_label.text = "Moves: %d" % remaining
	if _score_label:
		_score_label.text = "Score: %d" % _score

func _on_puzzle_complete_ui(score: int, payout: int) -> void:
	if _bet > 0:
		NetworkManager.call_rpc("submit_puzzle_score", {bet = _bet, score = score},
			func(result: Dictionary) -> void:
				var paid := int(result.get("payout", payout))
				if _score_label:
					_score_label.text = "Done! Score %d — +%d chips" % [score, paid]
				if paid > 0 and NotificationUI:
					NotificationUI.notify_win("Puzzle: +%d" % paid)
		)
	elif _score_label:
		_score_label.text = "Done! Score %d (practice)" % score

func _render_board(board: Array) -> void:
	if _grid == null:
		return
	for c in _grid.get_children():
		c.queue_free()
	_tile_buttons.clear()
	for r in board.size():
		var row_btns: Array = []
		for c in board[r].size():
			var btn := Button.new()
			btn.text = str(board[r][c])
			btn.custom_minimum_size = Vector2(48, 48)
			var pos := Vector2i(r, c)
			btn.pressed.connect(func() -> void: _on_tile_pressed(pos))
			_grid.add_child(btn)
			row_btns.append(btn)
		_tile_buttons.append(row_btns)

func _on_tile_pressed(pos: Vector2i) -> void:
	if _selected.x < 0:
		_selected = pos
		return
	swap(_selected.x, _selected.y, pos.x, pos.y)
	_selected = Vector2i(-1, -1)

func start_puzzle(bet: int) -> void:
	_bet = bet
	_moves_remaining = MOVE_LIMIT
	_score = 0
	_generate_board()
	board_updated.emit(_board)

func _generate_board() -> void:
	_board = []
	for row in range(BOARD_SIZE):
		var r = []
		for col in range(BOARD_SIZE):
			r.append(SYMBOLS[randi() % SYMBOLS.size()])
		_board.append(r)

func swap(row1: int, col1: int, row2: int, col2: int) -> bool:
	if _moves_remaining <= 0: return false
	if not _is_adjacent(row1, col1, row2, col2): return false

	var temp = _board[row1][col1]
	_board[row1][col1] = _board[row2][col2]
	_board[row2][col2] = temp

	var matches = _find_matches()
	if matches.is_empty():
		# Swap back
		temp = _board[row1][col1]
		_board[row1][col1] = _board[row2][col2]
		_board[row2][col2] = temp
		return false

	_moves_remaining -= 1
	_clear_matches(matches)
	_drop_tiles()
	_refill_board()
	_score += matches.size() * 10

	board_updated.emit(_board)
	move_made.emit(_moves_remaining)

	if _moves_remaining <= 0 or _score >= 500:
		_finish_puzzle()
	return true

func _is_adjacent(r1: int, c1: int, r2: int, c2: int) -> bool:
	return abs(r1 - r2) + abs(c1 - c2) == 1

func _find_matches() -> Array:
	var matched = []
	# Horizontal
	for row in range(BOARD_SIZE):
		var run = 1
		for col in range(1, BOARD_SIZE):
			if _board[row][col] == _board[row][col - 1]:
				run += 1
			else:
				if run >= MIN_MATCH:
					for i in range(run):
						matched.append(Vector2i(row, col - i - 1))
				run = 1
		if run >= MIN_MATCH:
			for i in range(run):
				matched.append(Vector2i(row, BOARD_SIZE - i - 1))
	# Vertical
	for col in range(BOARD_SIZE):
		var run = 1
		for row in range(1, BOARD_SIZE):
			if _board[row][col] == _board[row - 1][col]:
				run += 1
			else:
				if run >= MIN_MATCH:
					for i in range(run):
						matched.append(Vector2i(row - i - 1, col))
				run = 1
		if run >= MIN_MATCH:
			for i in range(run):
				matched.append(Vector2i(BOARD_SIZE - i - 1, col))
	return matched

func _clear_matches(matches: Array) -> void:
	for pos in matches:
		_board[pos.x][pos.y] = ""

func _drop_tiles() -> void:
	for col in range(BOARD_SIZE):
		var write_row = BOARD_SIZE - 1
		for row in range(BOARD_SIZE - 1, -1, -1):
			if _board[row][col] != "":
				_board[write_row][col] = _board[row][col]
				if write_row != row:
					_board[row][col] = ""
				write_row -= 1

func _refill_board() -> void:
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			if _board[row][col] == "":
				_board[row][col] = SYMBOLS[randi() % SYMBOLS.size()]

func _finish_puzzle() -> void:
	var mult = 0.0
	if _score >= 500: mult = 2.0
	elif _score >= 300: mult = 1.5
	elif _score >= 150: mult = 1.0
	elif _score >= 50: mult = 0.5

	var payout = int(_bet * mult)
	# Server validation would happen here via RPC
	puzzle_complete.emit(_score, payout)

func get_board() -> Array:
	return _board.duplicate(true)

func get_score() -> int:
	return _score

func get_moves_remaining() -> int:
	return _moves_remaining
