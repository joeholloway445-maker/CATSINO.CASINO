extends Control
class_name CombatUI
# Main combat screen for RPS-style battle system

signal combat_finished(won: bool, payout: int)

var _player_hp_bar: ProgressBar
var _opponent_hp_bar: ProgressBar
var _player_hp_label: Label
var _opponent_hp_label: Label
var _log_label: Label
var _result_label: Label
var _btn_light: Button
var _btn_heavy: Button
var _btn_tech: Button
var _game_state: Dictionary = {}
var _bet: int = 0
var _active: bool = false

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var root = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var battle_row = HBoxContainer.new()
	battle_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(battle_row)

	# Player side
	var player_panel = _make_combatant_panel("YOU", true)
	battle_row.add_child(player_panel)

	var vs = Label.new()
	vs.text = "VS"
	vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vs.add_theme_font_size_override("font_size", 24)
	battle_row.add_child(vs)

	# Opponent side
	var opp_panel = _make_combatant_panel("OPPONENT", false)
	battle_row.add_child(opp_panel)

	# Move buttons
	var btn_row = HBoxContainer.new()
	root.add_child(btn_row)

	for move_name in ["Light ⚡", "Heavy 🪨", "Tech 🔧"]:
		var btn = Button.new()
		btn.text = move_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): _on_move_pressed(move_name.split(" ")[0].to_lower()))
		btn.disabled = true
		btn_row.add_child(btn)
		match move_name:
			"Light ⚡": _btn_light = btn
			"Heavy 🪨": _btn_heavy = btn
			"Tech 🔧":  _btn_tech = btn

	_log_label = Label.new()
	_log_label.text = "Select your move."
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(_log_label)

	_result_label = Label.new()
	_result_label.text = ""
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 20)
	root.add_child(_result_label)

func _make_combatant_panel(label_text: String, is_player: bool) -> VBoxContainer:
	var panel = VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl = Label.new()
	name_lbl.text = label_text
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(name_lbl)

	var hp_bar = ProgressBar.new()
	hp_bar.max_value = 300
	hp_bar.value = 300
	panel.add_child(hp_bar)

	var hp_lbl = Label.new()
	hp_lbl.text = "300 / 300"
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(hp_lbl)

	if is_player:
		_player_hp_bar = hp_bar
		_player_hp_label = hp_lbl
	else:
		_opponent_hp_bar = hp_bar
		_opponent_hp_label = hp_lbl

	return panel

func start_combat(bet: int, frame_id: String = "phantom") -> void:
	_bet = bet
	_active = false
	_result_label.text = "Starting combat..."
	_set_buttons_disabled(true)

	var payload = JSON.stringify({"action": "start", "bet": bet, "frame_id": frame_id})
	NetworkManager.call_rpc("combat_action", payload, _on_combat_result)

func _on_move_pressed(move: String) -> void:
	if not _active: return
	_set_buttons_disabled(true)
	var payload = JSON.stringify({"action": "move", "move": move, "game_state": _game_state})
	NetworkManager.call_rpc("combat_action", payload, _on_combat_result)

func _on_combat_result(result: Dictionary) -> void:
	if not result.get("success", false):
		_result_label.text = "Error: " + result.get("error", "Unknown")
		return

	_game_state = result.get("state", {})
	_update_hp_display()

	var logs = _game_state.get("log", [])
	if logs.size() > 0:
		_log_label.text = logs[logs.size() - 1]

	var status = result.get("status", "")
	match status:
		"active":
			_active = true
			_set_buttons_disabled(false)
		"player_win":
			_active = false
			_result_label.text = "🎉 You WIN! +%d 🪙" % result.get("payout", 0)
			combat_finished.emit(true, result.get("payout", 0))
		"opponent_win":
			_active = false
			_result_label.text = "💀 You lost."
			combat_finished.emit(false, 0)

func _update_hp_display() -> void:
	var php = _game_state.get("player_hp", 0)
	var ohp = _game_state.get("opponent_hp", 0)
	var pmax = _player_hp_bar.max_value
	var omax = _opponent_hp_bar.max_value

	_player_hp_bar.value = maxf(0, php)
	_opponent_hp_bar.value = maxf(0, ohp)
	_player_hp_label.text = "%d / %d" % [maxi(0, php), pmax]
	_opponent_hp_label.text = "%d / %d" % [maxi(0, ohp), omax]

func _set_buttons_disabled(disabled: bool) -> void:
	_btn_light.disabled = disabled
	_btn_heavy.disabled = disabled
	_btn_tech.disabled = disabled
