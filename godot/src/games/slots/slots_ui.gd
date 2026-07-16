class_name SlotsUI
extends Control

@onready var reel1: VBoxContainer = $VBox/Reels/Reel1
@onready var reel2: VBoxContainer = $VBox/Reels/Reel2
@onready var reel3: VBoxContainer = $VBox/Reels/Reel3
@onready var spin_btn: Button = $VBox/Controls/SpinBtn
@onready var bet_spin: SpinBox = $VBox/Controls/BetSpin
@onready var balance_label: Label = $VBox/BalanceLabel
@onready var result_label: Label = $VBox/ResultLabel

const SYMBOLS := ["🐱", "🌟", "🎭", "🐾", "💎", "🔔", "🍀", "💰"]
var _spinning := false

func _ready() -> void:
	spin_btn.pressed.connect(_spin)
	_show_idle_reels()

func _show_idle_reels() -> void:
	for reel in [reel1, reel2, reel3]:
		for child in reel.get_children():
			child.queue_free()
		for i in range(3):
			var lbl := Label.new()
			lbl.text = SYMBOLS[randi() % SYMBOLS.size()]
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 32)
			reel.add_child(lbl)

func _spin() -> void:
	if _spinning:
		return
	_spinning = true
	spin_btn.disabled = true
	result_label.text = "Spinning..."
	var multiplier := EventManager.get_slot_multiplier() if EventManager else 1.0
	NetworkManager.call_rpc("spin_slots", {bet=int(bet_spin.value), multiplier=multiplier},
		func(result: Dictionary):
			_spinning = false
			spin_btn.disabled = false
			if result.get("error"):
				NotificationUI.notify_error(result.error)
				result_label.text = "Error!"
				return
			var symbols: Array = result.get("symbols", ["🐱", "🐱", "🐱"])
			_animate_result(symbols, result)
	)

func _animate_result(symbols: Array, result: Dictionary) -> void:
	for i in range(3):
		var reels := [reel1, reel2, reel3]
		for child in reels[i].get_children():
			child.queue_free()
		var lbl := Label.new()
		lbl.text = symbols[i]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 40)
		reels[i].add_child(lbl)

	var payout: int = result.get("payout", 0)
	if payout > 0:
		result_label.text = "WIN! +%d chips 🎉" % payout
		NotificationUI.notify_win("Slots: +%d chips!" % payout)
		AchievementManager.check("win", payout)
		AchievementManager.check("spin")
		if payout >= 10000:
			AchievementManager.check("big_win", payout)
	else:
		result_label.text = "No win. Try again!"
		AchievementManager.check("spin")
	XPManager.award_game("slots", payout > 0)
