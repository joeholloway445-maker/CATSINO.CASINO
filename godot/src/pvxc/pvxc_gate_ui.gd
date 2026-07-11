extends Control
## The PVXC gate — where the casino floor ends. Stake your chips, read the
## rules, see who you owe revenge, and step in. This screen is also where
## the future "light" version hangs its hooks: spectate/bet-on-runs without
## entering (planned web-app spinoff; PvxcManager.run_started/run_ended/
## kill_recorded are the event feed it will consume).

var _stake: SpinBox
var _status: Label

func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title := Label.new()
	title.text = "🔴 THE PVXC"
	title.add_theme_font_size_override("font_size", 26)
	root.add_child(title)

	var rules := Label.new()
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.text = ("Survival pit under the casino floor. Everything inside pays 6x. " +
		"The red core at the center pays 12x and is never, ever safe. " +
		"Every 15 minutes the floor flips: PvE you're house cats hunting wildlife; " +
		"PvP you shed the cat skin and fight as your race/frame/mod — yourselves. " +
		"Your stake is the house's the moment you walk in. Die and everything you " +
		"carry is seized — the house takes its cut, your killer takes the rest, " +
		"and the PVXC remembers who did it to you. Kill your killer for a double share. " +
		"Extraction gates are on the rim; the house keeps 10%% of whatever walks out.")
	rules.modulate = Color(0.85, 0.75, 0.75)
	root.add_child(rules)

	var phase := Label.new()
	var secs := int(PvxcManager.phase_seconds_left())
	phase.text = "Now: %s  ·  flips in %d:%02d" % [
		PvxcManager.phase_label(), secs / 60, secs % 60]
	phase.modulate = Color(1.0, 0.45, 0.4) if PvxcManager.is_pvp_phase() else Color(1.0, 0.85, 0.5)
	root.add_child(phase)

	root.add_child(HSeparator.new())

	var chips := Label.new()
	chips.text = "Your chips: %d 🎰   (chips only — buy at the cage with coins)" % EconomyManager.get_balance("chips")
	root.add_child(chips)

	var target := PvxcManager.my_target()
	if target != "":
		var revenge := Label.new()
		revenge.text = "⚔️ %s took everything from you last run. They're probably still in there." % target
		revenge.modulate = Color(1, 0.35, 0.35)
		root.add_child(revenge)

	var house := Label.new()
	house.text = "House recovered to date: %d 🎰" % PvxcManager.house_take
	house.modulate = Color(0.6, 0.6, 0.6)
	root.add_child(house)

	var stake_row := HBoxContainer.new()
	root.add_child(stake_row)
	var lbl := Label.new()
	lbl.text = "Stake (chips): "
	stake_row.add_child(lbl)
	_stake = SpinBox.new()
	_stake.min_value = PvxcManager.MIN_STAKE
	_stake.max_value = 100000
	_stake.step = 50
	_stake.value = PvxcManager.MIN_STAKE
	stake_row.add_child(_stake)

	var enter := Button.new()
	enter.text = "STAKE & ENTER 🔴"
	enter.add_theme_font_size_override("font_size", 18)
	enter.pressed.connect(_on_enter)
	root.add_child(enter)

	_status = Label.new()
	root.add_child(_status)

	var back := Button.new()
	back.text = "⬅ Back to the floor"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	root.add_child(back)

func _on_enter() -> void:
	if await PvxcManager.enter(int(_stake.value)):
		get_tree().change_scene_to_file("res://scenes/pvxc/pvxc_zone.tscn")
	else:
		_status.text = "The house looked at your chips and laughed."
