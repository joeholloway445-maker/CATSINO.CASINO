extends Control
## Arlington's Arena hub lobby — every minigame mode in one building
## (ArenaModes registry). Each mode launches through what exists today:
## bracket modes run TournamentManager, racing opens the race screen,
## everything else queues a simulated match through CombatSystem-style
## resolution until its bespoke gameplay lands. Winning anything here
## scores the Gladiator crown board.

var _log: VBoxContainer
var _pvp: PvPArenaSystem
var _rating_label: Label
var _tier_label: Label
var _ranking_overlay: PanelContainer

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

	_setup_pvp()
	root.add_child(HSeparator.new())
	_add_pvp_summary(root)
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
		if not StoryVote.can_vote(ballot.id):
			var done := Label.new()
			done.text = "✅ Vote in. The floor reopens to you in %d min (one per server day)." % (StoryVote.vote_cooldown_left(ballot.id) / 60)
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

func _setup_pvp() -> void:
	_pvp = PvPRankingUI.get_or_create_arena_system(self)
	if not _pvp.ranked_rating_updated.is_connected(_on_pvp_rating_updated):
		_pvp.ranked_rating_updated.connect(_on_pvp_rating_updated)
	if not _pvp.match_ended.is_connected(_on_pvp_match_ended):
		_pvp.match_ended.connect(_on_pvp_match_ended)

func _add_pvp_summary(root: VBoxContainer) -> void:
	var card := HBoxContainer.new()
	card.add_theme_constant_override("separation", 14)
	root.add_child(card)

	var label := Label.new()
	label.text = "PvP standing"
	label.add_theme_font_size_override("font_size", 16)
	card.add_child(label)

	_rating_label = Label.new()
	_rating_label.custom_minimum_size = Vector2(140, 0)
	card.add_child(_rating_label)

	_tier_label = Label.new()
	_tier_label.custom_minimum_size = Vector2(140, 0)
	_tier_label.modulate = Color(1.0, 0.85, 0.45)
	card.add_child(_tier_label)

	var open_rankings := Button.new()
	open_rankings.text = "View ladder"
	open_rankings.pressed.connect(_show_pvp_rankings)
	card.add_child(open_rankings)

	_refresh_pvp_summary()

func _refresh_pvp_summary() -> void:
	if _pvp == null or _rating_label == null or _tier_label == null:
		return
	var player_id := PvPRankingUI.LOCAL_PLAYER_ID
	_rating_label.text = "Rating: %d" % _pvp.get_player_rating(player_id)
	_tier_label.text = "Tier: %s" % _pvp.get_player_tier(player_id).capitalize()

func _show_pvp_rankings() -> void:
	if _ranking_overlay != null and is_instance_valid(_ranking_overlay):
		return

	_ranking_overlay = PanelContainer.new()
	_ranking_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_ranking_overlay)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 48)
	_ranking_overlay.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)

	var title := Label.new()
	title.text = "Arena PvP ladder"
	title.add_theme_font_size_override("font_size", 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(func():
		if _ranking_overlay != null:
			_ranking_overlay.queue_free()
			_ranking_overlay = null)
	header.add_child(close)

	var ranking := PvPRankingUI.new()
	ranking.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(ranking)

func _launch(mode_id: String) -> void:
	var mode := ArenaModes.by_id(mode_id)
	var scene_path: String = str(mode.get("scene", ""))
	match mode_id:
		"race_arena":
			get_tree().change_scene_to_file("res://scenes/games/racing/race_track.tscn")
		"conflict":
			# Large faction brackets still use the tournament engine.
			get_tree().change_scene_to_file("res://scenes/ui/tournament.tscn")
		"moba":
			_launch_moba(scene_path)
		_:
			if scene_path != "" and ResourceLoader.exists(scene_path):
				Engine.set_meta("arena_queued_mode", mode_id)
				get_tree().change_scene_to_file(scene_path)
			else:
				_simulate_match(mode_id)

## Online queue when authenticated; otherwise practice (offline MobaMatch).
## Holding Shift while clicking forces practice even when online.
func _launch_moba(scene_path: String) -> void:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		_simulate_match("moba")
		return
	var force_practice: bool = Input.is_key_pressed(KEY_SHIFT)
	if force_practice or not NetworkManager.is_connected_to_server():
		_enter_moba_scene(scene_path, "")
		if force_practice:
			NotificationUI.notify_info("Practice mode (offline).")
		else:
			NotificationUI.notify_info("Offline — practice match (login for online 5v5).")
		return
	NotificationUI.notify_info("Queuing for online Paws of the Ancients…")
	NetworkManager.call_rpc("find_moba_match", {"mode": "moba"}, func(result: Dictionary):
		if not result.get("ok", false) and not result.get("match_id", ""):
			NotificationUI.notify_error("Queue failed — starting practice. (%s)" % str(result.get("error", "?")))
			_enter_moba_scene(scene_path, "")
			return
		var mid := str(result.get("match_id", ""))
		if mid.is_empty():
			NotificationUI.notify_error("No match id — practice instead.")
			_enter_moba_scene(scene_path, "")
			return
		var created: bool = bool(result.get("created", false))
		NotificationUI.notify_info("Match %s — %s" % [mid.substr(0, 8), "created" if created else "joined"])
		_enter_moba_scene(scene_path, mid)
	)

func _enter_moba_scene(scene_path: String, match_id: String) -> void:
	Engine.set_meta("arena_queued_mode", "moba")
	if match_id != "":
		Engine.set_meta("moba_online_match_id", match_id)
	elif Engine.has_meta("moba_online_match_id"):
		Engine.remove_meta("moba_online_match_id")
	get_tree().change_scene_to_file(scene_path)

## Placeholder resolution for modes without bespoke gameplay yet: your
## stats + entities vs the field, luck-rolled — pays tokens (arena = PvP)
## and feeds the crown board on a win.
func _simulate_match(mode_id: String) -> void:
	var mode := ArenaModes.by_id(mode_id)
	var stats := CharacterCreatorLogic.build_starting_stats(
		PlayerProfile.selected_race_id, PlayerProfile.faction,
		PlayerProfile.selected_frame, PlayerProfile.selected_mod)
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
	_record_pvp_result(mode_id, won)
	_log.add_child(line)
	if _log.get_child_count() > 5:
		_log.get_child(0).queue_free()

func _record_pvp_result(mode_id: String, won: bool) -> void:
	if _pvp == null:
		return
	var player_id := PvPRankingUI.LOCAL_PLAYER_ID
	var opponent_id := "arena_%s_field" % mode_id
	var match_id := _pvp.create_match(player_id, opponent_id, mode_id)
	_pvp.start_match(match_id)
	_pvp.end_match(match_id, player_id if won else opponent_id)
	PvPRankingUI.save_arena_state(_pvp)
	_refresh_pvp_summary()

func _on_pvp_rating_updated(player_id: String, _new_rating: int) -> void:
	if player_id == PvPRankingUI.LOCAL_PLAYER_ID:
		_refresh_pvp_summary()

func _on_pvp_match_ended(_match_id: String, _winner_id: String) -> void:
	_refresh_pvp_summary()
