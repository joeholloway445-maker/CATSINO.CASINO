extends Control
class_name FactionSelectUI
# UI for choosing or changing faction allegiance

signal faction_selected(faction: String)

const FACTION_DATA = [
	{
		id = "SovereignCrown",
		name = "SovereignCrown",
		icon = "👑",
		color = Color(1.0, 0.84, 0.0),
		tagline = "Elite. Exclusive. Absolute.",
		slot_bonus = "+10% slot multiplier",
		combat_bonus = "+5% combat damage",
		companion_bonus = "High-rarity companions",
		lore = "The SovereignCrown rules Paws Vegas from the Crown Tower. Membership is by invitation only — or by proving yourself undeniable.",
	},
	{
		id = "WildlandsAscendant",
		name = "WildlandsAscendant",
		icon = "🌿",
		color = Color(0.2, 0.8, 0.2),
		tagline = "Nature's fury, harnessed.",
		slot_bonus = "+5% slot multiplier",
		combat_bonus = "+10% combat damage",
		companion_bonus = "+5 race SPD bonus",
		lore = "Born from Cat Forest, the Wildlands faction believes nature is the ultimate power.",
	},
	{
		id = "VeiledCurrent",
		name = "VeiledCurrent",
		icon = "🌊",
		color = Color(0.2, 0.6, 1.0),
		tagline = "Flow unseen. Strike true.",
		slot_bonus = "+12% slot multiplier",
		combat_bonus = "+8% combat damage",
		companion_bonus = "+8 race SPD bonus",
		lore = "The Veiled Current operates beneath the surface. Neon Alley's water district is their stronghold.",
	},
	{
		id = "Factionless",
		name = "Factionless",
		icon = "⚡",
		color = Color(0.6, 0.6, 0.6),
		tagline = "Bound by nothing.",
		slot_bonus = "No faction bonuses",
		combat_bonus = "No faction restrictions",
		companion_bonus = "Use any companion type",
		lore = "Some cats answer to no one. They receive no faction bonuses — but suffer no faction restrictions either.",
	},
]

var _cards: Array[Control] = []
var _selected_faction: String = ""
var _confirm_btn: Button

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var root = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title = Label.new()
	title.text = "CHOOSE YOUR FACTION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Your faction shapes your bonuses, companions, and allegiance in Paws Vegas."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(subtitle)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(grid)

	for faction in FACTION_DATA:
		var card = _make_faction_card(faction)
		grid.add_child(card)
		_cards.append(card)

	_confirm_btn = Button.new()
	_confirm_btn.text = "CONFIRM FACTION"
	_confirm_btn.disabled = true
	_confirm_btn.add_theme_font_size_override("font_size", 16)
	_confirm_btn.pressed.connect(_on_confirm)
	root.add_child(_confirm_btn)

func _make_faction_card(faction: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(300, 180)
	btn.text = "%s %s\n%s\n\n%s\n%s\n%s" % [
		faction.icon,
		faction.name,
		faction.tagline,
		"Slots: " + faction.slot_bonus,
		"Combat: " + faction.combat_bonus,
		"Companions: " + faction.companion_bonus,
	]
	btn.modulate = faction.color
	btn.pressed.connect(func(): _select_faction(faction.id))
	return btn

func _select_faction(faction_id: String) -> void:
	_selected_faction = faction_id
	_confirm_btn.disabled = false
	_confirm_btn.text = "JOIN %s" % faction_id.to_upper()

func _on_confirm() -> void:
	if _selected_faction.is_empty(): return
	if PlayerProfile:
		PlayerProfile.set_faction(_selected_faction)
	faction_selected.emit(_selected_faction)
