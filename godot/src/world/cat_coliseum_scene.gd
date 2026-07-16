extends Node

signal battle_result(won: bool, xp_gained: int, coins_gained: int)
signal tournament_complete(wins: int, total_prize: int)

var _opponent_queue: Array[CharacterData] = []
var _current_opponent_index: int = 0
var _battle_log: RichTextLabel

func _ready() -> void:
	_build_opponent_queue()
	_build_ui()

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var title := Label.new()
	title.text = "⚔️ CAT COLISEUM"
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	_battle_log = RichTextLabel.new()
	_battle_log.bbcode_enabled = true
	_battle_log.custom_minimum_size = Vector2(600, 320)
	_battle_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_battle_log)

	var challenge := Button.new()
	challenge.text = "Challenge Next Opponent"
	challenge.pressed.connect(func() -> void: challenge_next(_make_player()))
	root.add_child(challenge)

	var tournament := Button.new()
	tournament.text = "Start Gauntlet"
	tournament.pressed.connect(func() -> void: await start_tournament(_make_player()))
	root.add_child(tournament)

	var arena := Button.new()
	arena.text = "Open Arlington Arena Hub"
	arena.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/arena_hub.tscn"))
	root.add_child(arena)

	var back := Button.new()
	back.text = "⬅ Menu"
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	root.add_child(back)

	_log("[color=gray]The sand remembers every claw mark.[/color]")

func _make_player() -> CharacterData:
	var player := CharacterData.new()
	player.character_name = "You"
	player.base_pow = 25 + PlayerProfile.level * 3
	player.base_res = 20 + PlayerProfile.level * 2
	player.base_spd = 18 + PlayerProfile.level
	player.base_lck = 15 + PlayerProfile.level
	return player

func _build_opponent_queue() -> void:
	_opponent_queue.clear()
	var names = ["Arena Kitten", "Bronze Claw", "Silver Fang", "Golden Paw", "Diamond Overlord"]
	for i in range(5):
		var opp: CharacterData = CharacterData.new()
		opp.character_name = names[i]
		opp.base_pow = 20 + i * 15
		opp.base_res = 15 + i * 10
		opp.base_spd = 10 + i * 8
		opp.base_lck = 5 + i * 5
		_opponent_queue.append(opp)

func challenge_next(player: CharacterData) -> void:
	if _current_opponent_index >= _opponent_queue.size():
		_log("[color=yellow]No more opponents![/color]")
		return
	var opponent = _opponent_queue[_current_opponent_index]
	_log("[color=cyan]--- Battle vs %s ---[/color]" % opponent.character_name)
	var result = CombatSystem.resolve_encounter(player, opponent)
	var won: bool = str(result.outcome) == "win"
	if won:
		var xp: int = 50 + _current_opponent_index * 30
		var coins: int = 100 + _current_opponent_index * 75
		_log("[color=green]Victory! Earned %d XP and %d coins[/color]" % [xp, coins])
		EconomyManager.add_coins(coins, "coliseum_win")
		if XPManager and XPManager.has_method("award_amount"):
			XPManager.award_amount(xp, "coliseum")
		_current_opponent_index += 1
		battle_result.emit(true, xp, coins)
	else:
		_log("[color=red]Defeat! Better luck next time.[/color]")
		battle_result.emit(false, 0, 0)

func start_tournament(player: CharacterData) -> void:
	_current_opponent_index = 0
	var win_streak: int = 0
	var base_prize: int = 500
	_log("[color=gold]=== TOURNAMENT BEGINS ===[/color]")
	for i in range(_opponent_queue.size()):
		var opponent = _opponent_queue[i]
		_log("[color=cyan]Round %d vs %s[/color]" % [i + 1, opponent.character_name])
		var result = CombatSystem.resolve_encounter(player, opponent)
		var won: bool = str(result.outcome) == "win"
		if won:
			win_streak += 1
			_log("[color=green]Round %d: WIN (streak: %d)[/color]" % [i + 1, win_streak])
		else:
			_log("[color=red]Round %d: LOSS — Tournament Over[/color]" % (i + 1))
			tournament_complete.emit(win_streak, 0)
			return
		await get_tree().create_timer(0.5).timeout
	var total_prize: int = base_prize
	if win_streak == 5:
		total_prize = base_prize * 2
	EconomyManager.add_coins(total_prize, "coliseum_tournament")
	_log("[color=gold]=== TOURNAMENT COMPLETE! Prize: %d coins ===[/color]" % total_prize)
	tournament_complete.emit(win_streak, total_prize)

func _log(text: String) -> void:
	if _battle_log:
		_battle_log.append_text(text + "\n")
