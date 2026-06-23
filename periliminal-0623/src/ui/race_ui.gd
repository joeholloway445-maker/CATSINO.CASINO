extends Control
class_name RaceUI
# Racing game UI — select frame/mod, place bet, view live results

signal race_started(frame_id: String, bet: int)
signal race_finished(position: int, payout: int)

var _frame_selector: OptionButton
var _bet_spinbox: SpinBox
var _race_btn: Button
var _results_panel: VBoxContainer
var _status_label: Label

const FRAME_OPTIONS = [
	{id="veil",    label="Veil Frame (SPD+15)"},
	{id="zephyr",  label="Zephyr Frame (SPD+12, LCK+8)"},
	{id="bolt",    label="Bolt Frame (SPD+20) ⚡"},
	{id="phantom", label="Phantom Frame (LCK+12)"},
	{id="bastion", label="Bastion Frame (RES+20, POW+10)"},
	{id="tremor",  label="Tremor Frame (POW+18, RES+8)"},
	{id="surge",   label="Surge Frame (POW+20)"},
	{id="flux",    label="Flux Frame (balanced)"},
]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var root = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title = Label.new()
	title.text = "🏁 NEON ALLEY RACE"
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Choose your frame, place your bet, and race!"
	subtitle.modulate = Color(0.7, 0.7, 0.7)
	root.add_child(subtitle)

	var hsep = HSeparator.new()
	root.add_child(hsep)

	var frame_row = HBoxContainer.new()
	root.add_child(frame_row)

	var frame_lbl = Label.new()
	frame_lbl.text = "Frame: "
	frame_row.add_child(frame_lbl)

	_frame_selector = OptionButton.new()
	_frame_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for opt in FRAME_OPTIONS:
		_frame_selector.add_item(opt.label)
	frame_row.add_child(_frame_selector)

	var bet_row = HBoxContainer.new()
	root.add_child(bet_row)

	var bet_lbl = Label.new()
	bet_lbl.text = "Bet (coins): "
	bet_row.add_child(bet_lbl)

	_bet_spinbox = SpinBox.new()
	_bet_spinbox.min_value = 0
	_bet_spinbox.max_value = 10000
	_bet_spinbox.step = 50
	_bet_spinbox.value = 200
	bet_row.add_child(_bet_spinbox)

	_race_btn = Button.new()
	_race_btn.text = "START RACE 🏁"
	_race_btn.add_theme_font_size_override("font_size", 16)
	_race_btn.pressed.connect(_on_race_pressed)
	root.add_child(_race_btn)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_status_label)

	_results_panel = VBoxContainer.new()
	_results_panel.visible = false
	root.add_child(_results_panel)

	var results_title = Label.new()
	results_title.text = "🏆 RACE RESULTS"
	results_title.add_theme_font_size_override("font_size", 18)
	_results_panel.add_child(results_title)

	for i in range(4):
		var row = Label.new()
		row.name = "ResultRow%d" % i
		_results_panel.add_child(row)

	var payout_lbl = Label.new()
	payout_lbl.name = "PayoutLabel"
	payout_lbl.add_theme_font_size_override("font_size", 16)
	_results_panel.add_child(payout_lbl)

func _on_race_pressed() -> void:
	_race_btn.disabled = true
	_status_label.text = "Racing..."
	_results_panel.visible = false

	var frame_idx = _frame_selector.selected
	var frame_id = FRAME_OPTIONS[frame_idx].id
	var bet = int(_bet_spinbox.value)

	race_started.emit(frame_id, bet)

	var payload = JSON.stringify({"frame_id": frame_id, "bet": bet, "race_type": "standard"})
	NetworkManager.call_rpc("start_race", payload, func(r): _on_race_result(r))

func _on_race_result(result: Dictionary) -> void:
	_race_btn.disabled = false

	if not result.get("success", false):
		_status_label.text = "Error: " + result.get("error", "Unknown")
		return

	_status_label.text = ""
	_results_panel.visible = true

	var results = result.get("results", [])
	var position = result.get("position", 4)
	var payout = result.get("payout", 0)

	for i in range(mini(results.size(), 4)):
		var row = _results_panel.get_node_or_null("ResultRow%d" % i)
		if not row: continue
		var r = results[i]
		var is_player = r.get("id", "") == "player" or i == position - 1
		var medal = ["🥇", "🥈", "🥉", "4th"][i]
		row.text = "%s %s — %ss" % [medal, r.get("id", "?"), r.get("time", "?")]
		row.modulate = Color(1.0, 1.0, 0.5) if is_player else Color.WHITE

	var payout_lbl = _results_panel.get_node_or_null("PayoutLabel")
	if payout_lbl:
		if payout > 0:
			payout_lbl.text = "💰 Payout: +%d 🪙" % payout
			payout_lbl.modulate = Color(0.3, 1.0, 0.3)
		else:
			payout_lbl.text = "Better luck next race!"
			payout_lbl.modulate = Color(0.7, 0.7, 0.7)

	race_finished.emit(position, payout)
