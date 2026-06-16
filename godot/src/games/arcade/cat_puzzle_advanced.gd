class_name CatPuzzleAdvanced
extends Node2D
# Advanced Cat Puzzle with combo chain tracking and server score submission

@onready var grid_container: GridContainer = $CanvasLayer/UI/Grid
@onready var score_label: Label = $CanvasLayer/UI/ScoreLabel
@onready var timer_label: Label = $CanvasLayer/UI/TimerLabel
@onready var submit_btn: Button = $CanvasLayer/UI/SubmitBtn
@onready var bet_spin: SpinBox = $CanvasLayer/UI/BetSpin

const GRID_SIZE := 6
const SYMBOLS := ["🐱", "🌟", "🎭", "🐾", "💎", "🔔"]
const GAME_TIME := 60.0

var _board: Array = []  # 6x6 of symbol indices
var _selected: Vector2i = Vector2i(-1, -1)
var _score := 0
var _combo := 0
var _time_left := GAME_TIME
var _active := false

func _ready() -> void:
	submit_btn.pressed.connect(_start_game)
	submit_btn.text = "Start Game (%d coins)" % int(bet_spin.value)
	bet_spin.value_changed.connect(func(v): submit_btn.text = "Start Game (%d coins)" % int(v))

func _start_game() -> void:
	_score = 0
	_combo = 0
	_time_left = GAME_TIME
	_active = true
	_init_board()
	_render()
	submit_btn.text = "Submit Score"
	submit_btn.pressed.disconnect(_start_game)
	submit_btn.pressed.connect(_submit_score)

func _init_board() -> void:
	_board = []
	for row in range(GRID_SIZE):
		var r := []
		for col in range(GRID_SIZE):
			r.append(randi() % SYMBOLS.size())
		_board.append(r)

func _process(delta: float) -> void:
	if not _active: return
	_time_left -= delta
	timer_label.text = "Time: %ds" % max(0, int(_time_left))
	if _time_left <= 0:
		_active = false
		_auto_submit()

func _render() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var btn := Button.new()
			btn.text = SYMBOLS[_board[row][col]]
			btn.custom_minimum_size = Vector2(55, 55)
			if Vector2i(row, col) == _selected:
				btn.modulate = Color.YELLOW
			var r := row
			var c := col
			btn.pressed.connect(func(): _on_cell_pressed(r, c))
			grid_container.add_child(btn)
	score_label.text = "Score: %d" % _score

func _on_cell_pressed(row: int, col: int) -> void:
	if not _active: return
	if _selected == Vector2i(-1, -1):
		_selected = Vector2i(row, col)
	else:
		var dr := abs(row - _selected.x)
		var dc := abs(col - _selected.y)
		if (dr == 1 and dc == 0) or (dr == 0 and dc == 1):
			_swap(_selected, Vector2i(row, col))
		_selected = Vector2i(-1, -1)
	_render()

func _swap(a: Vector2i, b: Vector2i) -> void:
	var tmp: int = _board[a.x][a.y]
	_board[a.x][a.y] = _board[b.x][b.y]
	_board[b.x][b.y] = tmp
	var matches := _find_matches()
	if matches.is_empty():
		var tmp2: int = _board[a.x][a.y]
		_board[a.x][a.y] = _board[b.x][b.y]
		_board[b.x][b.y] = tmp2
	else:
		_combo += 1
		_score += matches.size() * _combo * 10
		_clear_matches(matches)
		_drop_and_fill()

func _find_matches() -> Array[Vector2i]:
	var matches: Array[Vector2i] = []
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE - 2):
			if _board[row][col] == _board[row][col+1] and _board[row][col] == _board[row][col+2]:
				for i in range(3): matches.append(Vector2i(row, col + i))
	for col in range(GRID_SIZE):
		for row in range(GRID_SIZE - 2):
			if _board[row][col] == _board[row+1][col] and _board[row][col] == _board[row+2][col]:
				for i in range(3): matches.append(Vector2i(row + i, col))
	return matches

func _clear_matches(matches: Array[Vector2i]) -> void:
	for cell in matches:
		_board[cell.x][cell.y] = -1

func _drop_and_fill() -> void:
	for col in range(GRID_SIZE):
		var empty_rows: Array[int] = []
		for row in range(GRID_SIZE - 1, -1, -1):
			if _board[row][col] == -1:
				empty_rows.append(row)
		for row in empty_rows:
			_board[row][col] = randi() % SYMBOLS.size()

func _submit_score() -> void:
	_active = false
	NetworkManager.call_rpc("submit_puzzle_score", {score=_score, bet=int(bet_spin.value)},
		func(result: Dictionary):
			var payout: int = result.get("payout", 0)
			if payout > 0:
				NotificationUI.notify_win("Puzzle score %d — +%d coins!" % [_score, payout])
				AchievementManager.check("win", payout)
			if result.get("achieved_500"):
				AchievementManager.check("puzzle_score", _score)
				QuestManager.complete_quest("arcade_champion")
			XPManager.award_game("cat_puzzle", payout > 0)
	)

func _auto_submit() -> void:
	_submit_score()
