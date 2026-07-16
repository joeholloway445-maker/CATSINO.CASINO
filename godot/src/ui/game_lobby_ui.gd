extends PanelContainer

class_name GameLobbyUI

# ─── Child node references ────────────────────────────────────────────────────
@onready var game_grid: VBoxContainer = $MarginContainer/VBoxContainer/GameGrid
@onready var events_container: VBoxContainer = $MarginContainer/VBoxContainer/EventsPanel/EventsList
@onready var bp_xp_bar: ProgressBar = $MarginContainer/VBoxContainer/BattlepassBar
@onready var bp_label: Label = $MarginContainer/VBoxContainer/BattlepassLabel
@onready var close_button: Button = $MarginContainer/VBoxContainer/TopBar/CloseButton
@onready var title_label: Label = $MarginContainer/VBoxContainer/TopBar/TitleLabel

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	title_label.text = "PAWS VEGAS — Game Lobby"
	close_button.pressed.connect(_on_close_pressed)

	if LiveOpsManager.has_signal("event_started"):
		LiveOpsManager.event_started.connect(_on_event_updated)
	if LiveOpsManager.has_signal("battlepass_xp_gained"):
		LiveOpsManager.battlepass_xp_gained.connect(_on_bp_xp_changed)

	refresh()

# ─── Public API ───────────────────────────────────────────────────────────────
func refresh() -> void:
	_populate_games()
	_populate_events()
	_refresh_battlepass()

# ─── Game cards ──────────────────────────────────────────────────────────────
func _populate_games() -> void:
	# Clear existing children
	for child in game_grid.get_children():
		child.queue_free()

	var catalog: Array = GameFactory.get_game_catalog()
	for entry in catalog:
		var card := _make_game_card(entry)
		game_grid.add_child(card)

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
	bet_label.text = "Min Bet: %d Coins" % entry.get("min_bet", 0)
	bet_label.modulate = Color(1.0, 0.85, 0.2)
	vbox.add_child(bet_label)

	var play_btn := Button.new()
	play_btn.text = "PLAY"
	play_btn.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(play_btn)

	var game_type: int = entry.get("game_type", 0)
	var variant_id: int = entry.get("variant_id", 0)
	play_btn.pressed.connect(func() -> void:
		_on_game_card_pressed(game_type, variant_id)
	)

	return card

# ─── Events panel ────────────────────────────────────────────────────────────
func _populate_events() -> void:
	for child in events_container.get_children():
		child.queue_free()

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
		ev_label.text = "%s  —  Ends: %s" % [
			event.get("name", "Event"),
			event.get("ends_at", "?")
		]
		ev_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(ev_label)
		events_container.add_child(row)

# ─── Battlepass bar ──────────────────────────────────────────────────────────
func _refresh_battlepass() -> void:
	var bp: Dictionary = LiveOpsManager.get_battlepass_progress()
	var current: int = bp.get("current_xp", 0)
	var max_xp: int = bp.get("xp_to_next", 1000)
	var tier: int = bp.get("tier", 1)

	bp_xp_bar.max_value = max(max_xp, 1)
	bp_xp_bar.value = current
	bp_label.text = "Battlepass Tier %d — %d / %d XP" % [tier, current, max_xp]

# ─── Signal handlers ─────────────────────────────────────────────────────────
func _on_game_card_pressed(game_type: int, variant_id: int) -> void:
	GameManager.enter_game(game_type, variant_id)

func _on_close_pressed() -> void:
	visible = false

func _on_event_updated(_event: Dictionary) -> void:
	_populate_events()

func _on_bp_xp_changed(current: int, max_xp: int) -> void:
	bp_xp_bar.max_value = max(max_xp, 1)
	bp_xp_bar.value = current
