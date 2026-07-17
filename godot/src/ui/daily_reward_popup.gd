extends Control
class_name DailyRewardPopup
# Shows the daily login reward dialog

signal claimed(day: int, coins: int, gems: int, item: String)
signal dismissed()

var _day_label: Label
var _reward_label: Label
var _claim_btn: Button
var _dismiss_btn: Button

func _ready() -> void:
	_build_ui()
	_check_claim()
	UINav.add_back_button(self)

func _build_ui() -> void:
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(360, 260)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🎁 Daily Login Reward!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	_day_label = Label.new()
	_day_label.text = "Day 1"
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_day_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_day_label)

	_reward_label = Label.new()
	_reward_label.text = "Checking..."
	_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_reward_label)

	var btn_row = HBoxContainer.new()
	vbox.add_child(btn_row)

	_claim_btn = Button.new()
	_claim_btn.text = "CLAIM REWARD 🎁"
	_claim_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_claim_btn.pressed.connect(_on_claim_pressed)
	btn_row.add_child(_claim_btn)

	_dismiss_btn = Button.new()
	_dismiss_btn.text = "Later"
	_dismiss_btn.pressed.connect(_on_dismiss)
	btn_row.add_child(_dismiss_btn)

func _check_claim() -> void:
	if not DailyRewards: return
	if not DailyRewards.can_claim():
		_reward_label.text = "Already claimed today! Come back tomorrow."
		_claim_btn.disabled = true
		return

	var next_reward = DailyRewards.get_next_reward()
	var streak = DailyRewards.get_streak()
	_day_label.text = "Day %d of 14" % (streak + 1)

	var reward_text = "+%d 🪙" % next_reward.get("coins", 0)
	if next_reward.get("gems", 0) > 0:
		reward_text += "  +%d 💎" % next_reward.gems
	if next_reward.get("item", "") != "":
		reward_text += "\n🎁 Bonus item: " + next_reward.item
	_reward_label.text = reward_text

func _on_claim_pressed() -> void:
	if not DailyRewards: return
	DailyRewards.reward_claimed.connect(_on_reward_claimed)
	DailyRewards.already_claimed.connect(_on_dismiss)
	DailyRewards.claim()

func _on_reward_claimed(day: int, coins: int, gems: int, item: String) -> void:
	_claim_btn.disabled = true
	_reward_label.text = "✅ Claimed! Day %d reward received." % day
	claimed.emit(day, coins, gems, item)

func _on_dismiss() -> void:
	dismissed.emit()
	queue_free()
