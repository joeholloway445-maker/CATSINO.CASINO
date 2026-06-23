class_name LeaderboardPanel
extends Control

@onready var board_list: VBoxContainer = $Panel/VBox/ScrollContainer/BoardList
@onready var board_option: OptionButton = $Panel/VBox/BoardOption

const BOARDS := {
	"global_wins": "🏆 Total Wins",
	"global_coins": "💰 Most Coins Won",
	"slot_wins": "🎰 Slot Wins",
	"race_wins": "🏁 Race Wins",
	"combat_wins": "⚔️ Combat Wins",
	"puzzle_scores": "🧩 Puzzle Scores",
}

func _ready() -> void:
	for key in BOARDS.keys():
		board_option.add_item(BOARDS[key])
	board_option.item_selected.connect(func(_i): _refresh())
	_refresh()

func _refresh() -> void:
	var board_keys := BOARDS.keys()
	var board_id := board_keys[board_option.selected]
	NetworkManager.call_rpc("get_leaderboard", {board_id=board_id, limit=20},
		func(result: Dictionary):
			_render(result.get("records", []))
	)

func _render(records: Array) -> void:
	for child in board_list.get_children():
		child.queue_free()

	const MEDALS := ["🥇", "🥈", "🥉"]
	for i in range(records.size()):
		var rec := records[i] as Dictionary
		var row := HBoxContainer.new()
		var rank_label := Label.new()
		rank_label.text = MEDALS[i] if i < 3 else "#%d" % (i + 1)
		rank_label.custom_minimum_size.x = 40
		var name_label := Label.new()
		name_label.text = rec.get("username", "Player")
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var score_label := Label.new()
		score_label.text = str(rec.get("score", 0))
		row.add_child(rank_label)
		row.add_child(name_label)
		row.add_child(score_label)
		board_list.add_child(row)
