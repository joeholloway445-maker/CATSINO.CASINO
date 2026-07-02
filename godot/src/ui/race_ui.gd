extends Control
class_name RaceUI
# Racing game UI — pick a track and frame, pay the entry fee, place a bet,
# view live results. Tracks come from RaceData.TRACKS; when the Nakama
# server isn't reachable the race resolves locally via RaceAI.simulate_race.

signal race_started(frame_id: String, bet: int)
signal race_finished(position: int, payout: int)

var _track_selector: OptionButton
var _track_info: Label
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

## Bet payout multiplier by finish position (1st..3rd), scaled by difficulty.
const POSITION_MULT = {1: 3.0, 2: 1.5, 3: 1.0}
const DIFFICULTY_BONUS = {"beginner": 1.0, "intermediate": 1.25, "expert": 1.6}

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var root = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title = Label.new()
	title.text = "🏁 CATSINO GRAND RACING"
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Pick a track, choose your frame, place your bet, and race!"
	subtitle.modulate = Color(0.7, 0.7, 0.7)
	root.add_child(subtitle)

	root.add_child(HSeparator.new())

	var track_row = HBoxContainer.new()
	root.add_child(track_row)

	var track_lbl = Label.new()
	track_lbl.text = "Track: "
	track_row.add_child(track_lbl)

	_track_selector = OptionButton.new()
	_track_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var player_level: int = PlayerProfile.level
	for i in range(RaceData.TRACKS.size()):
		var t: Dictionary = RaceData.TRACKS[i]
		if RaceData.is_unlocked(t, player_level):
			_track_selector.add_item("%s — %s (entry %d 🪙)" % [t.name, t.difficulty, t.entry_fee])
		else:
			_track_selector.add_item("🔒 %s — unlocks at level %d" % [t.name, RaceData.unlock_level(t)])
			_track_selector.set_item_disabled(i, true)
	_track_selector.item_selected.connect(func(_i): _refresh_track_info())
	track_row.add_child(_track_selector)

	_track_info = Label.new()
	_track_info.modulate = Color(0.75, 0.85, 1.0)
	_track_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_track_info)

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

	for i in range(8):
		var row = Label.new()
		row.name = "ResultRow%d" % i
		_results_panel.add_child(row)

	var payout_lbl = Label.new()
	payout_lbl.name = "PayoutLabel"
	payout_lbl.add_theme_font_size_override("font_size", 16)
	_results_panel.add_child(payout_lbl)

	_refresh_track_info()

func _selected_track() -> Dictionary:
	return RaceData.TRACKS[_track_selector.selected].duplicate()

func _refresh_track_info() -> void:
	var t := _selected_track()
	_track_info.text = "%s  •  %d lap%s, %.0fm  •  %s" % [
		t.description, t.laps, "s" if t.laps > 1 else "", t.distance, t.district]

func _on_race_pressed() -> void:
	var track := _selected_track()
	if not RaceData.is_unlocked(track, PlayerProfile.level):
		_status_label.text = "Track locked — reach level %d." % RaceData.unlock_level(track)
		return
	var entry_fee: int = int(track.entry_fee)
	var bet := int(_bet_spinbox.value)

	if not await EconomyManager.spend_coins(entry_fee + bet, "race_" + str(track.id)):
		_status_label.text = "Not enough coins (entry %d + bet %d)." % [entry_fee, bet]
		return

	_race_btn.disabled = true
	_status_label.text = "Racing %s..." % track.name
	_results_panel.visible = false

	var frame_id: String = FRAME_OPTIONS[_frame_selector.selected].id
	race_started.emit(frame_id, bet)

	if NetworkManager.is_connected_to_server():
		var payload := {"frame_id": frame_id, "bet": bet, "track_id": track.id, "race_type": "standard"}
		NetworkManager.call_rpc("start_race", payload, func(r): _on_race_result(r, track, bet))
	else:
		# Offline/local: resolve the race client-side with the same payout rules.
		var sim := RaceAI.simulate_race(frame_id, track)
		sim["success"] = true
		sim["payout"] = _local_payout(sim.get("position", 99), bet, track)
		_on_race_result(sim, track, bet)

## Payout for locally-simulated races: podium finishes return the bet times a
## position multiplier, scaled up on harder tracks; 1st also refunds the entry fee.
func _local_payout(position: int, bet: int, track: Dictionary) -> int:
	if position > 3:
		return 0
	var mult: float = POSITION_MULT.get(position, 0.0) * DIFFICULTY_BONUS.get(str(track.difficulty), 1.0)
	var payout := int(bet * mult)
	if position == 1:
		payout += int(track.entry_fee)
	return payout

func _on_race_result(result: Dictionary, track: Dictionary, bet: int) -> void:
	_race_btn.disabled = false

	if not result.get("success", false):
		# Server rejected the race — refund what we charged up front.
		EconomyManager.add_coins(int(track.entry_fee) + bet, "race_refund")
		_status_label.text = "Error: " + str(result.get("error", "Unknown"))
		return

	_status_label.text = ""
	_results_panel.visible = true

	var results: Array = result.get("results", [])
	var position: int = result.get("position", 4)
	var payout: int = result.get("payout", 0)

	if payout > 0:
		EconomyManager.add_coins(payout, "race_win_" + str(track.id))

	for i in range(8):
		var row = _results_panel.get_node_or_null("ResultRow%d" % i)
		if not row: continue
		if i >= results.size():
			row.text = ""
			continue
		var r: Dictionary = results[i]
		var is_player: bool = r.get("id", "") in ["player", "YOU"] or i == position - 1
		var medal: String = ["🥇", "🥈", "🥉"][i] if i < 3 else "%dth" % (i + 1)
		row.text = "%s %s — %ss" % [medal, r.get("id", "?"), str(r.get("time", "?"))]
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
