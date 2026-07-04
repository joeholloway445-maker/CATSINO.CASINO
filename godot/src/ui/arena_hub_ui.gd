extends Control
## Arlington's Arena hub lobby — every minigame mode in one building
## (ArenaModes registry). Each mode launches through what exists today:
## bracket modes run TournamentManager, racing opens the race screen,
## everything else queues a simulated match through CombatSystem-style
## resolution until its bespoke gameplay lands. Winning anything here
## scores the Gladiator crown board.

var _log: VBoxContainer

func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title := Label.new()
	title.text = "🏟️ ARLINGTON ARENA"
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	var sub := Label.new()
	sub.text = "Every mode. One building. Winners feed the Gladiator crown."
	sub.modulate = Color(0.7, 0.7, 0.7)
	root.add_child(sub)

	root.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for mode in ArenaModes.MODES:
		var card := VBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = "%s  (%s)" % [mode.name, ("team of %d" % mode.team_size) if mode.team_size > 1 else "solo"]
		name_lbl.add_theme_font_size_override("font_size", 17)
		card.add_child(name_lbl)

		var desc := Label.new()
		desc.text = mode.desc
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.modulate = Color(0.75, 0.75, 0.8)
		card.add_child(desc)

		var btn := Button.new()
		btn.text = "Queue up"
		var mid: String = mode.id
		btn.pressed.connect(func(): _launch(mid))
		card.add_child(btn)
		list.add_child(card)
		list.add_child(HSeparator.new())

	# The referendum floor: vote on where the story and DLCs go.
	var vote_hdr := Label.new()
	vote_hdr.text = "🗳️ SHAPE WHAT COMES NEXT"
	vote_hdr.add_theme_font_size_override("font_size", 18)
	vote_hdr.modulate = Color(1.0, 0.85, 0.4)
	list.add_child(vote_hdr)
	for ballot in StoryVote.BALLOTS:
		var bcard := VBoxContainer.new()
		var bt := Label.new()
		bt.text = ballot.title
		bt.add_theme_font_size_override("font_size", 15)
		bcard.add_child(bt)
		var bd := Label.new()
		bd.text = ballot.desc
		bd.modulate = Color(0.7, 0.7, 0.75)
		bd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bcard.add_child(bd)
		if StoryVote.has_voted(ballot.id):
			var done := Label.new()
			done.text = "✅ Your vote is in."
			done.modulate = Color(0.5, 0.9, 0.5)
			bcard.add_child(done)
		else:
			for oi in range(ballot.options.size()):
				var ob := Button.new()
				ob.text = ballot.options[oi]
				var bid: String = ballot.id
				var opt := oi
				ob.pressed.connect(func():
					StoryVote.vote(bid, opt)
					get_tree().reload_current_scene())
				bcard.add_child(ob)
		list.add_child(bcard)
		list.add_child(HSeparator.new())

	_log = VBoxContainer.new()
	root.add_child(_log)

	var back := Button.new()
	back.text = "⬅ Back"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	root.add_child(back)

func _launch(mode_id: String) -> void:
	match mode_id:
		"race_arena":
			get_tree().change_scene_to_file("res://scenes/games/racing/race_track.tscn")
		"moba", "conflict":
			# Bracket team modes run through the tournament engine today.
			get_tree().change_scene_to_file("res://scenes/ui/tournament.tscn")
		_:
			_simulate_match(mode_id)

## Placeholder resolution for modes without bespoke gameplay yet: your
## stats + entities vs the field, luck-rolled — pays tokens (arena = PvP)
## and feeds the crown board on a win.
func _simulate_match(mode_id: String) -> void:
	var mode := ArenaModes.by_id(mode_id)
	var stats := CharacterCreatorLogic.build_starting_stats(
		PlayerProfile.selected_race_id, PlayerProfile.faction, PlayerProfile.selected_frame)
	var entity_boost := 0
	for cid in PlayerProfile.active_companion_ids:
		var e := CompanionRegistry.get_by_id(str(cid))
		entity_boost += int(e.get("pow", 0)) / 10 if mode.get("uses_entities", false) else 0
	var mine: int = int(stats.pow) + int(stats.spd) + entity_boost + PlayerProfile.level * 2 + randi() % 40
	var field := 60 + randi() % 60
	var won := mine >= field
	var line := Label.new()
	if won:
		var payout := 40 + randi() % 60
		EconomyManager.earn_currency("tokens", payout, "arena_%s" % mode_id)
		CrownManager.add_score("Top Arena Victories", "local_player", 1, PlayerProfile.faction)
		EconomyManager.earn_prestige(8, "arena_win")
		line.text = "🏆 %s: WON (+%d ⚔️ tokens)" % [mode.name, payout]
		line.modulate = Color(0.4, 1.0, 0.4)
	else:
		EconomyManager.earn_prestige(3, "arena_loss")
		line.text = "💥 %s: eliminated. The arena remembers effort too (+3 🌟)." % mode.name
		line.modulate = Color(1.0, 0.5, 0.4)
	_log.add_child(line)
	if _log.get_child_count() > 5:
		_log.get_child(0).queue_free()
