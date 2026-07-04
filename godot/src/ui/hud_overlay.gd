class_name HUDOverlay
extends CanvasLayer
# In-game overlay shown during gameplay in world scenes

@onready var coins_label: Label = $TopBar/CoinsLabel
@onready var level_label: Label = $TopBar/LevelLabel
@onready var district_label: Label = $TopBar/DistrictLabel
@onready var event_banner: PanelContainer = $EventBanner
@onready var event_label: Label = $EventBanner/EventLabel
@onready var minimap: Minimap = $Minimap
@onready var xp_bar: ProgressBar = $BottomBar/XPBar

func _ready() -> void:
	_refresh_wallet()
	_refresh_profile()
	_check_events()
	PlayerProfile.xp_changed.connect(_on_xp_changed)

func _refresh_wallet() -> void:
	NetworkManager.call_rpc("get_wallet", {},
		func(result: Dictionary):
			coins_label.text = "🪙 %d" % result.get("cat_coins", 0)
	)

func _refresh_profile() -> void:
	level_label.text = "Lv %d" % PlayerProfile.level
	var progress := PlayerProfile.xp_progress()
	xp_bar.value = progress * 100

func _check_events() -> void:
	var multiplier := EventManager.get_slot_multiplier()
	if multiplier > 1.0:
		event_label.text = "🎰 %sx SLOTS ACTIVE" % multiplier
		event_banner.show()
	elif EventManager.get_xp_multiplier() > 1.0:
		event_label.text = "⭐ %sx XP ACTIVE" % EventManager.get_xp_multiplier()
		event_banner.show()
	else:
		event_banner.hide()

func set_district(district_name: String) -> void:
	district_label.text = district_name

func _on_xp_changed(new_xp: int, new_level: int) -> void:
	level_label.text = "Lv %d" % new_level
	xp_bar.value = PlayerProfile.xp_progress() * 100
