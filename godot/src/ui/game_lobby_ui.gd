extends PanelContainer

class_name GameLobbyUI

# Built procedurally so the lobby works even without a matching .tscn tree.

var game_grid: VBoxContainer
var events_container: VBoxContainer
var bp_xp_bar: ProgressBar
var bp_label: Label
var close_button: Button
var title_label: Label
var chips_label: Label
var buy_chips_button: Button

func _ready() -> void:
	_ensure_ui()
	title_label.text = "PAWS VEGAS — Game Lobby"
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	if buy_chips_button and not buy_chips_button.pressed.is_connected(_on_buy_chips):
		buy_chips_button.pressed.connect(_on_buy_chips)

	if LiveOpsManager and LiveOpsManager.has_signal("event_started"):
		LiveOpsManager.event_started.connect(_on_event_updated)
	if LiveOpsManager and LiveOpsManager.has_signal("battlepass_xp_gained"):
		LiveOpsManager.battlepass_xp_gained.connect(_on_bp_xp_changed)
	elif LiveOpsManager and LiveOpsManager.has_signal("xp_gained"):
		LiveOpsManager.xp_gained.connect(func(_a, _s): _refresh_battlepass())

	refresh()

func _ensure_ui() -> void:
	if get_child_count() > 0 and has_node("MarginContainer/VBoxContainer/GameGrid"):
		game_grid = $MarginContainer/VBoxContainer/GameGrid
		events_container = $MarginContainer/VBoxContainer/EventsPanel/EventsList
		bp_xp_bar = $MarginContainer/VBoxContainer/BattlepassBar
		bp_label = $MarginContainer/VBoxContainer/BattlepassLabel
		close_button = $MarginContainer/VBoxContainer/TopBar/CloseButton
		title_label = $MarginContainer/VBoxContainer/TopBar/TitleLabel
		return

	for c in get_children():
		c.queue_free()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.04, 0.1, 0.92)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var top := HBoxContainer.new()
	top.name = "TopBar"
	vbox.add_child(top)
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 22)
	top.add_child(title_label)
	chips_label = Label.new()
	chips_label.name = "ChipsLabel"
	chips_label.modulate = Color(1.0, 0.88, 0.35)
	top.add_child(chips_label)
	buy_chips_button = Button.new()
	buy_chips_button.name = "BuyChipsButton"
	buy_chips_button.text = "Buy 500 chips"
	top.add_child(buy_chips_button)
	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Close"
	top.add_child(close_button)

	bp_label = Label.new()
	bp_label.name = "BattlepassLabel"
	vbox.add_child(bp_label)
	bp_xp_bar = ProgressBar.new()
	bp_xp_bar.name = "BattlepassBar"
	bp_xp_bar.custom_minimum_size = Vector2(0, 18)
	vbox.add_child(bp_xp_bar)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	game_grid = VBoxContainer.new()
	game_grid.name = "GameGrid"
	game_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(game_grid)

	var events_panel := VBoxContainer.new()
	events_panel.name = "EventsPanel"
	vbox.add_child(events_panel)
	var ev_title := Label.new()
	ev_title.text = "Live Events"
	events_panel.add_child(ev_title)
	events_container = VBoxContainer.new()
	events_container.name = "EventsList"
	events_panel.add_child(events_container)

func refresh() -> void:
	_refresh_chips()
	_populate_games()
	_populate_events()
	_refresh_battlepass()

func _refresh_chips() -> void:
	if chips_label == null:
		return
	var chips := 0
	var coins := 0
	if EconomyManager:
		chips = EconomyManager.get_balance("chips")
		coins = EconomyManager.get_coins()
	chips_label.text = "Chips: %d  ·  Coins: %d" % [chips, coins]

func _on_buy_chips() -> void:
	# Local cage exchange — avoid await hang when Nakama isn't up.
	if EconomyManager == null:
		return
	const AMOUNT := 500
	if not EconomyManager.spend_coins_local(AMOUNT, "chip_exchange"):
		NotificationUI.notify_error("Need %d coins at the cage." % AMOUNT)
		return
	EconomyManager.earn_currency_local("chips", AMOUNT, "chip_exchange")
	NotificationUI.notify_win("Cage exchange — +%d chips." % AMOUNT)
	_refresh_chips()

func _populate_games() -> void:
	if game_grid == null:
		return
	for child in game_grid.get_children():
		child.queue_free()

	var catalog: Array = GameFactory.get_game_catalog() if GameFactory else []
	for entry in catalog:
		game_grid.add_child(_make_game_card(entry))

func _make_game_card(entry: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 72)
	var hbox := HBoxContainer.new()
	card.add_child(hbox)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_label := Label.new()
	name_label.text = entry.get("name", "Unknown Game")
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)

	var type_label := Label.new()
	type_label.text = "Type: %s" % entry.get("type_label", "?")
	type_label.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(type_label)

	var bet_label := Label.new()
	bet_label.text = "Min Bet: %d Chips" % entry.get("min_bet", 0)
	bet_label.modulate = Color(1.0, 0.85, 0.2)
	vbox.add_child(bet_label)

	var play_btn := Button.new()
	play_btn.text = "PLAY"
	play_btn.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(play_btn)

	var game_type: int = int(entry.get("game_type", 0))
	var variant_id: int = int(entry.get("variant_id", 0))
	var scene_path: String = str(entry.get("scene", ""))
	play_btn.pressed.connect(func() -> void:
		_on_game_card_pressed(game_type, variant_id, scene_path)
	)
	return card

func _populate_events() -> void:
	if events_container == null:
		return
	for child in events_container.get_children():
		child.queue_free()
	if LiveOpsManager == null:
		return

	var active_events: Array = LiveOpsManager.get_active_events()
	if active_events.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No active events right meow."
		empty_label.modulate = Color(0.7, 0.7, 0.7)
		events_container.add_child(empty_label)
		return

	for event in active_events:
		var row := HBoxContainer.new()
		var icon := Label.new()
		icon.text = "⭐"
		row.add_child(icon)
		var ev_label := Label.new()
		var ev_name := "Event"
		var ends_at := "?"
		if event is Dictionary:
			ev_name = str(event.get("name", "Event"))
			ends_at = str(event.get("ends_at", "?"))
		elif event != null and event.has_method("to_dict"):
			var d: Dictionary = event.to_dict()
			ev_name = str(d.get("name", "Event"))
			ends_at = str(d.get("ends_at", "?"))
		elif event != null and "name" in event:
			ev_name = str(event.name)
		ev_label.text = "%s  —  Ends: %s" % [ev_name, ends_at]
		ev_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(ev_label)
		events_container.add_child(row)

func _refresh_battlepass() -> void:
	if bp_xp_bar == null or bp_label == null or LiveOpsManager == null:
		return
	var bp: Dictionary = {}
	if LiveOpsManager.has_method("get_battlepass_progress"):
		bp = LiveOpsManager.get_battlepass_progress()
	else:
		bp = {
			"current_xp": LiveOpsManager.get_battlepass_xp() if LiveOpsManager.has_method("get_battlepass_xp") else 0,
			"xp_to_next": LiveOpsManager.get_xp_for_tier(LiveOpsManager.get_battlepass_tier() + 1) if LiveOpsManager.has_method("get_xp_for_tier") else 1000,
			"tier": LiveOpsManager.get_battlepass_tier() if LiveOpsManager.has_method("get_battlepass_tier") else 1,
		}
	var current: int = int(bp.get("current_xp", 0))
	var max_xp: int = int(bp.get("xp_to_next", 1000))
	var tier: int = int(bp.get("tier", 1))
	bp_xp_bar.max_value = max(max_xp, 1)
	bp_xp_bar.value = current
	bp_label.text = "Battlepass Tier %d — %d / %d XP" % [tier, current, max_xp]

func _on_game_card_pressed(game_type: int, variant_id: int, scene_path: String = "") -> void:
	if scene_path != "" and ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
		return
	if GameManager and GameManager.has_method("enter_game"):
		GameManager.enter_game(game_type, variant_id, scene_path)
	else:
		NotificationUI.notify_error("Cannot launch game")

func _on_close_pressed() -> void:
	visible = false

func _on_event_updated(_event = null) -> void:
	_populate_events()

func _on_bp_xp_changed(current: int, max_xp: int) -> void:
	if bp_xp_bar == null:
		return
	bp_xp_bar.max_value = max(max_xp, 1)
	bp_xp_bar.value = current
