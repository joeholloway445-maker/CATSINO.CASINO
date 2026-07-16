class_name TournamentUI
extends Control

@onready var tournament_list: VBoxContainer = $Panel/VBox/ScrollContainer/TournamentList
@onready var my_rank_label: Label = $Panel/VBox/MyRankLabel

## Local racing cups run through the TournamentManager bracket when the
## server isn't reachable (or in addition to server tournaments).
const LOCAL_CUPS = [
	{name="Alley Cat Cup", entry_fee=250, field=8},
	{name="Paws Vegas Invitational", entry_fee=750, field=16},
]

var _local_log: VBoxContainer

func _ready() -> void:
	TournamentManager.tournament_round_complete.connect(_on_round_complete)
	TournamentManager.tournament_finished.connect(_on_tournament_finished)
	_refresh()
	UINav.add_back_button(self)

func _refresh() -> void:
	if NetworkManager.is_connected_to_server():
		NetworkManager.call_rpc("get_tournaments", {},
			func(result: Dictionary):
				var tournaments: Array = result.get("tournaments", [])
				_render(tournaments)
		)
	else:
		_render([])

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

	_render_local_cups()

func _render_local_cups() -> void:
	var header := Label.new()
	header.text = "🏁 LOCAL RACING CUPS"
	header.add_theme_font_size_override("font_size", 18)
	header.modulate = Color(1.0, 0.85, 0.4)
	tournament_list.add_child(header)

	for cup in LOCAL_CUPS:
		var card := VBoxContainer.new()

		var title := Label.new()
		title.text = "🏆 %s" % cup.name
		title.add_theme_font_size_override("font_size", 16)
		card.add_child(title)

		var info := Label.new()
		info.text = "Entry: %d 🪙 | %d racers | winner takes pot ×%d" % [
			cup.entry_fee, cup.field, TournamentManager.PRIZE_POOL_MULTIPLIER]
		info.modulate = Color(0.75, 0.75, 0.75)
		card.add_child(info)

		var enter_btn := Button.new()
		enter_btn.text = "Race Now"
		enter_btn.pressed.connect(func(): _run_local_cup(cup))
		card.add_child(enter_btn)

		tournament_list.add_child(card)
		tournament_list.add_child(HSeparator.new())

	_local_log = VBoxContainer.new()
	tournament_list.add_child(_local_log)

func _run_local_cup(cup: Dictionary) -> void:
	if TournamentManager.state != TournamentManager.TournamentState.IDLE:
		NotificationUI.notify_error("A tournament is already running.")
		return
	TournamentManager.create_tournament(
		TournamentManager.TournamentType.RACING, int(cup.entry_fee), str(cup.name))

	var player := {
		"id": "player", "name": PlayerProfile.get_display_name(),
		"is_player": true,
		"spd": 50 + PlayerProfile.level * 2,
	}
	if not await TournamentManager.register(player):
		NotificationUI.notify_error("Not enough coins for the %d 🪙 entry fee." % int(cup.entry_fee))
		TournamentManager.state = TournamentManager.TournamentState.IDLE
		TournamentManager.current_tournament = {}
		return

	for i in range(int(cup.field) - 1):
		var ai_name: String = RaceAI.AI_NAMES[i % RaceAI.AI_NAMES.size()]
		await TournamentManager.register({
			"id": "ai_%d" % i, "name": ai_name,
			"is_player": false,
			"spd": 40 + randi() % 30,
		})

	_log_line("— %s: bracket of %d, racing! —" % [cup.name, int(cup.field)])
	TournamentManager.start()

func _log_line(text: String) -> void:
	if not is_instance_valid(_local_log):
		return
	var line := Label.new()
	line.text = text
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_local_log.add_child(line)

func _on_round_complete(round_num: int, results: Array) -> void:
	for r in results:
		var w: Dictionary = r.get("winner", {})
		if w.get("is_player", false):
			_log_line("Round %d: YOU won your heat! ⚡" % round_num)
			return
	_log_line("Round %d complete." % round_num)

func _on_tournament_finished(winner: Dictionary, _standings: Array) -> void:
	if winner.get("is_player", false):
		_log_line("🥇 CHAMPION! You take the pot!")
		NotificationUI.notify_win("Tournament champion! 🏆")
	else:
		_log_line("Winner: %s. Better luck next cup." % winner.get("name", "?"))
	if is_instance_valid(my_rank_label):
		my_rank_label.text = "Last cup: %s" % ("CHAMPION 🏆" if winner.get("is_player", false) else "eliminated")

func _enter(tournament_id: String) -> void:
	NetworkManager.call_rpc("join_tournament", {tournament_id=tournament_id},
		func(result: Dictionary):
			if result.get("success"):
				NotificationUI.notify_win("Entered tournament!")
				_refresh()
			else:
				NotificationUI.notify_error(result.get("error", "Could not enter tournament"))
	)
