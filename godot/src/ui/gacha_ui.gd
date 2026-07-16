class_name GachaUI
extends Control

signal companion_obtained(companion_id: String, rarity: String)

@onready var result_container: VBoxContainer = $Panel/VBox/ResultContainer
@onready var single_btn: Button = $Panel/VBox/Controls/SingleBtn
@onready var multi_btn: Button = $Panel/VBox/Controls/MultiBtn
@onready var faction_option: OptionButton = $Panel/VBox/Controls/FactionOption
@onready var pity_label: Label = $Panel/VBox/PityLabel

const RARITY_COLORS := {
	"common": Color.WHITE,
	"uncommon": Color.GREEN,
	"rare": Color.CYAN,
	"epic": Color.PURPLE,
	"legendary": Color.GOLD,
}

var _pity_counter := 0  # increments until epic/legendary

func _ready() -> void:
	if single_btn:
		single_btn.pressed.connect(func(): _summon(1))
	if multi_btn:
		multi_btn.pressed.connect(func(): _summon(10))
	if faction_option:
		faction_option.add_item("Any Faction")
		faction_option.add_item("SovereignCrown")
		faction_option.add_item("WildlandsAscendant")
		faction_option.add_item("VeiledCurrent")
		faction_option.add_item("Factionless")
	UINav.add_back_button(self)

func _summon(count: int) -> void:
	var factions := ["", "SovereignCrown", "WildlandsAscendant", "VeiledCurrent", "Factionless"]
	var faction := factions[faction_option.selected] if faction_option else ""
	if single_btn:
		single_btn.disabled = true
	if multi_btn:
		multi_btn.disabled = true

	NetworkManager.call_rpc("summon_companion", {count=count, faction=faction},
		func(result: Dictionary):
			if single_btn:
				single_btn.disabled = false
			if multi_btn:
				multi_btn.disabled = false
			if result.get("error"):
				NotificationUI.notify_error(result.error)
				return
			var companions: Array = result.get("companions", [])
			_show_results(companions)
	)

func _show_results(companions: Array) -> void:
	for child in result_container.get_children():
		child.queue_free()

	for c in companions:
		var row := HBoxContainer.new()
		var id_label := Label.new()
		id_label.text = c.get("companion_id", "???")
		id_label.modulate = RARITY_COLORS.get(c.get("rarity", "common"), Color.WHITE)
		var rarity_label := Label.new()
		rarity_label.text = "[%s]" % c.get("rarity", "common").to_upper()
		rarity_label.modulate = RARITY_COLORS.get(c.get("rarity", "common"), Color.WHITE)
		row.add_child(id_label)
		row.add_child(rarity_label)
		result_container.add_child(row)

		_pity_counter += 1
		if c.get("rarity") in ["epic", "legendary"]:
			_pity_counter = 0
			NotificationUI.notify_achievement("✨ %s obtained! [%s]" % [c.companion_id, c.rarity])

		AchievementManager.check("companion_collect")
		companion_obtained.emit(c.get("companion_id", ""), c.get("rarity", "common"))

	pity_label.text = "Pity: %d/50 (guaranteed Epic)" % _pity_counter
