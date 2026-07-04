extends CanvasLayer

class_name HUD

# ─── Child node references ────────────────────────────────────────────────────
@onready var coins_label: Label = $MarginContainer/HBoxContainer/CoinsLabel
@onready var xp_bar: ProgressBar = $MarginContainer/HBoxContainer/XPBar
@onready var district_label: Label = $MarginContainer/HBoxContainer/DistrictLabel
@onready var win_popup: PanelContainer = $WinPopup
@onready var win_amount_label: Label = $WinPopup/VBoxContainer/AmountLabel
@onready var win_multiplier_label: Label = $WinPopup/VBoxContainer/MultiplierLabel
@onready var event_banner: PanelContainer = $EventBanner
@onready var event_name_label: Label = $EventBanner/EventNameLabel

# ─── Internal state ───────────────────────────────────────────────────────────
var _event_tween: Tween = null
var _win_tween: Tween = null

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Hide popups initially
	win_popup.modulate.a = 0.0
	win_popup.visible = false

	event_banner.position.x = -event_banner.size.x - 32.0
	event_banner.visible = false

	# Connect to EconomyManager signals
	if EconomyManager.has_signal("coins_changed"):
		EconomyManager.coins_changed.connect(_on_coins_changed)
	if EconomyManager.has_signal("gems_changed"):
		EconomyManager.gems_changed.connect(_on_gems_changed)

	# Connect to LiveOpsManager signals
	if LiveOpsManager.has_signal("event_started"):
		LiveOpsManager.event_started.connect(_on_event_started)
	if LiveOpsManager.has_signal("battlepass_xp_gained"):
		LiveOpsManager.battlepass_xp_gained.connect(_on_battlepass_xp_gained)

	# Seed initial values from managers
	update_coins(EconomyManager.get_coins())
	var bp := LiveOpsManager.get_battlepass_progress()
	if bp.size() > 0:
		update_xp(bp.get("current_xp", 0), bp.get("xp_to_next", 1000))

# ─── Public API ───────────────────────────────────────────────────────────────
func update_coins(amount: int) -> void:
	if not is_instance_valid(coins_label):
		return
	coins_label.text = "🪙 %s" % _format_number(amount)

func update_xp(current: int, max_xp: int) -> void:
	if not is_instance_valid(xp_bar):
		return
	xp_bar.max_value = max(max_xp, 1)
	xp_bar.value = current
	xp_bar.tooltip_text = "%d / %d XP" % [current, max_xp]

func update_district(district_name: String) -> void:
	if not is_instance_valid(district_label):
		return
	district_label.text = district_name

func show_win_popup(amount: int, multiplier: float) -> void:
	if not is_instance_valid(win_popup):
		return

	win_amount_label.text = "+%s Coins" % _format_number(amount)
	win_multiplier_label.text = "%.1fx Multiplier!" % multiplier

	win_popup.visible = true

	# Kill any existing tween cleanly
	if _win_tween and _win_tween.is_valid():
		_win_tween.kill()

	_win_tween = create_tween()
	_win_tween.set_parallel(true)

	# Fade in + scale punch
	win_popup.scale = Vector2(0.7, 0.7)
	_win_tween.tween_property(win_popup, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	_win_tween.tween_property(win_popup, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Hold then fade out
	_win_tween.set_parallel(false)
	_win_tween.tween_interval(1.8)
	_win_tween.tween_property(win_popup, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	_win_tween.tween_callback(func() -> void: win_popup.visible = false)

func show_event_notification(event_name: String) -> void:
	if not is_instance_valid(event_banner):
		return

	event_name_label.text = "⭐ %s" % event_name
	event_banner.visible = true

	if _event_tween and _event_tween.is_valid():
		_event_tween.kill()

	_event_tween = create_tween()

	# Slide in from left
	var screen_left_x := -event_banner.size.x - 32.0
	var visible_x := 16.0
	event_banner.position.x = screen_left_x
	_event_tween.tween_property(event_banner, "position:x", visible_x, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Hold
	_event_tween.tween_interval(3.5)

	# Slide out
	_event_tween.tween_property(event_banner, "position:x", screen_left_x, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_event_tween.tween_callback(func() -> void: event_banner.visible = false)

# ─── Signal handlers ─────────────────────────────────────────────────────────
func _on_coins_changed(new_amount: int) -> void:
	update_coins(new_amount)

func _on_gems_changed(_new_amount: int) -> void:
	pass # Gem label not part of this HUD variant but could be added

func _on_event_started(event: Dictionary) -> void:
	show_event_notification(event.get("name", "Unknown Event"))

func _on_battlepass_xp_gained(current: int, max_xp: int) -> void:
	update_xp(current, max_xp)

# ─── Helpers ─────────────────────────────────────────────────────────────────
func _format_number(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)
