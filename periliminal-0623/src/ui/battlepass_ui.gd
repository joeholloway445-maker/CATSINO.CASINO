extends Control

const TOTAL_TIERS: int = 100
const PREMIUM_COST_GEMS: int = 800

var _scroll: ScrollContainer
var _tier_container: HBoxContainer
var _xp_bar: ProgressBar
var _xp_label: Label
var _premium_btn: Button
var _has_premium: bool = false
var _current_tier: int = 0
var _current_xp: int = 0
var _xp_per_tier: int = 1000

func _ready() -> void:
	_load_player_data()
	_build_ui()
	_populate_tiers()

func _load_player_data() -> void:
	if LiveOpsManager.has_method("get_battlepass_data"):
		var data = LiveOpsManager.get_battlepass_data()
		_current_tier = data.get("tier", 0)
		_current_xp = data.get("xp", 0)
		_has_premium = data.get("premium", false)
		_xp_per_tier = data.get("xp_per_tier", 1000)

func _build_ui() -> void:
	var root = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Header
	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 60)
	root.add_child(header)

	var title = Label.new()
	title.text = "BATTLE PASS"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_premium_btn = Button.new()
	_premium_btn.custom_minimum_size = Vector2(200, 40)
	_premium_btn.pressed.connect(_on_premium_unlock_pressed)
	header.add_child(_premium_btn)
	_update_premium_button()

	# XP Bar
	var xp_row = VBoxContainer.new()
	xp_row.custom_minimum_size = Vector2(0, 50)
	root.add_child(xp_row)

	_xp_label = Label.new()
	xp_row.add_child(_xp_label)

	_xp_bar = ProgressBar.new()
	_xp_bar.min_value = 0.0
	_xp_bar.max_value = float(_xp_per_tier)
	_xp_bar.value = float(_current_xp % _xp_per_tier)
	_xp_bar.custom_minimum_size = Vector2(0, 20)
	xp_row.add_child(_xp_bar)

	_update_xp_display()

	# Tier scroll
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)

	_tier_container = HBoxContainer.new()
	_tier_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_tier_container)

func _populate_tiers() -> void:
	for child in _tier_container.get_children():
		child.queue_free()
	for tier in range(1, TOTAL_TIERS + 1):
		var card = _build_tier_card(tier)
		_tier_container.add_child(card)
	# Scroll to current tier
	await get_tree().process_frame
	var scroll_target: float = (_current_tier - 1) * 110.0
	_scroll.scroll_horizontal = int(max(0, scroll_target))

func _build_tier_card(tier: int) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(100, 160)
	var is_current = (tier == _current_tier + 1)
	var is_unlocked = (tier <= _current_tier)
	if is_current:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(1.0, 0.85, 0.0, 0.3)
		style.border_width_top = 3
		style.border_color = Color.YELLOW
		card.add_theme_stylebox_override("panel", style)
	var vbox = VBoxContainer.new()
	card.add_child(vbox)

	var tier_lbl = Label.new()
	tier_lbl.text = "Tier %d" % tier
	tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tier_lbl)

	# Free reward
	var free_lbl = Label.new()
	free_lbl.text = _get_free_reward_icon(tier)
	free_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(free_lbl)

	# Premium reward
	var prem_lbl = Label.new()
	prem_lbl.text = _get_premium_reward_icon(tier)
	prem_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not _has_premium:
		prem_lbl.modulate = Color(0.4, 0.4, 0.4, 1.0)
	vbox.add_child(prem_lbl)

	# Claim button if applicable
	var is_claimable_free = is_unlocked and _can_claim(tier, false)
	var is_claimable_prem = is_unlocked and _has_premium and _can_claim(tier, true)
	if is_claimable_free or is_claimable_prem:
		var claim_btn = Button.new()
		claim_btn.text = "Claim"
		var t = tier
		var p = is_claimable_prem and not is_claimable_free
		claim_btn.pressed.connect(func(): _on_claim_pressed(t, p))
		vbox.add_child(claim_btn)

	return card

func _get_free_reward_icon(tier: int) -> String:
	var icons = ["💰", "⭐", "🎁", "🏆", "💎"]
	return icons[(tier - 1) % icons.size()]

func _get_premium_reward_icon(tier: int) -> String:
	var icons = ["👑", "🌟", "🎭", "🔮", "🐱"]
	return icons[(tier - 1) % icons.size()]

func _can_claim(tier: int, premium: bool) -> bool:
	if LiveOpsManager.has_method("is_battlepass_tier_claimed"):
		return not LiveOpsManager.is_battlepass_tier_claimed(tier, premium)
	return false

func _on_claim_pressed(tier: int, premium: bool) -> void:
	if LiveOpsManager.has_method("claim_battlepass_reward"):
		var result = await LiveOpsManager.claim_battlepass_reward(tier, premium)
		if result:
			_populate_tiers()

func _on_premium_unlock_pressed() -> void:
	if _has_premium:
		return
	if EconomyManager.has_method("spend_gems"):
		if EconomyManager.spend_gems(PREMIUM_COST_GEMS):
			_has_premium = true
			_update_premium_button()
			_populate_tiers()

func _update_premium_button() -> void:
	if _premium_btn:
		if _has_premium:
			_premium_btn.text = "PREMIUM ACTIVE"
			_premium_btn.disabled = true
		else:
			_premium_btn.text = "Unlock Premium (%d Gems)" % PREMIUM_COST_GEMS
			_premium_btn.disabled = false

func _update_xp_display() -> void:
	if _xp_label:
		_xp_label.text = "Tier %d — XP: %d / %d" % [_current_tier, _current_xp % _xp_per_tier, _xp_per_tier]
	if _xp_bar:
		_xp_bar.value = float(_current_xp % _xp_per_tier)
