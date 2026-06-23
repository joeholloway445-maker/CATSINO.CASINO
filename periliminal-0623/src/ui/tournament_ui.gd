class_name TournamentUI
extends Control

@onready var tournament_list: VBoxContainer = $Panel/VBox/ScrollContainer/TournamentList
@onready var my_rank_label: Label = $Panel/VBox/MyRankLabel

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	NetworkManager.call_rpc("get_tournaments", {},
		func(result: Dictionary):
			var tournaments: Array = result.get("tournaments", [])
			_render(tournaments)
	)

func _render(tournaments: Array) -> void:
	for child in tournament_list.get_children():
		child.queue_free()

	for t in tournaments:
		var card := VBoxContainer.new()

		var title := Label.new()
		title.text = "🏆 %s" % t.get("name", "Tournament")
		title.add_theme_font_size_override("font_size", 18)
		card.add_child(title)

		var info := Label.new()
		info.text = "Prize: %d coins | Entry: %d | Players: %d" % [
			t.get("prize_pool", 0), t.get("entry_fee", 0), t.get("entry_count", 0)
		]
		card.add_child(info)

		var enter_btn := Button.new()
		enter_btn.text = "Enter Tournament"
		var tid := t.get("id", "")
		enter_btn.pressed.connect(func(): _enter(tid))
		card.add_child(enter_btn)

		var sep := HSeparator.new()
		tournament_list.add_child(card)
		tournament_list.add_child(sep)

func _enter(tournament_id: String) -> void:
	NetworkManager.call_rpc("join_tournament", {tournament_id=tournament_id},
		func(result: Dictionary):
			if result.get("success"):
				NotificationUI.notify_win("Entered tournament!")
				_refresh()
			else:
				NotificationUI.notify_error(result.get("error", "Could not enter tournament"))
	)
