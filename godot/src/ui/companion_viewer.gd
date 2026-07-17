extends Control
class_name CompanionViewer
# Browse, equip, and view all unlocked companions

signal companion_equipped(slot: int, companion_id: String)

var _companion_grid: GridContainer
var _detail_panel: PanelContainer
var _selected: Dictionary = {}
var _unlocked_ids: Array[String] = []
var _current_filter: String = "all"

const FACTION_COLORS = {
	"SovereignCrown":     Color(0.8, 0.6, 0.0),
	"WildlandsAscendant": Color(0.2, 0.8, 0.2),
	"VeiledCurrent":      Color(0.2, 0.6, 1.0),
	"Factionless":        Color(0.6, 0.6, 0.6),
}

const RARITY_STARS = {1: "★", 2: "★★", 3: "★★★", 4: "★★★★", 5: "★★★★★"}

func _ready() -> void:
	_build_ui()
	_load_companions()
	UINav.add_back_button(self)

func _build_ui() -> void:
	var root = HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Left: filter + grid
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(left)

	var title = Label.new()
	title.text = "COMPANIONS"
	title.add_theme_font_size_override("font_size", 20)
	left.add_child(title)

	# Faction filter buttons
	var filter_row = HBoxContainer.new()
	left.add_child(filter_row)

	for faction in ["all", "SovereignCrown", "WildlandsAscendant", "VeiledCurrent", "Factionless"]:
		var btn = Button.new()
		btn.text = "All" if faction == "all" else faction.substr(0, 6)
		btn.pressed.connect(func(): _set_filter(faction))
		filter_row.add_child(btn)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)

	_companion_grid = GridContainer.new()
	_companion_grid.columns = 4
	scroll.add_child(_companion_grid)

	# Right: detail panel
	_detail_panel = PanelContainer.new()
	_detail_panel.custom_minimum_size = Vector2(280, 0)
	root.add_child(_detail_panel)

	var detail_vbox = VBoxContainer.new()
	_detail_panel.add_child(detail_vbox)

	for node_name in ["NameLabel", "FactionLabel", "RarityLabel", "ElementLabel", "SignatureLabel", "DescLabel"]:
		var lbl = Label.new()
		lbl.name = node_name
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		detail_vbox.add_child(lbl)

	var equip_row = HBoxContainer.new()
	detail_vbox.add_child(equip_row)

	for slot in [1, 2, 3]:
		var btn = Button.new()
		btn.text = "Slot %d" % slot
		btn.pressed.connect(func(): _equip_to_slot(slot))
		btn.name = "EquipSlot%d" % slot
		btn.visible = false
		equip_row.add_child(btn)

func _load_companions() -> void:
	if CompanionManager:
		_unlocked_ids = CompanionManager.get_unlocked_ids()
	_refresh_grid()

func _set_filter(faction: String) -> void:
	_current_filter = faction
	_refresh_grid()

func _refresh_grid() -> void:
	for child in _companion_grid.get_children():
		child.queue_free()

	var all_companions = _get_all_companions()
	var shown = 0
	for c in all_companions:
		if not c.get("id", "") in _unlocked_ids:
			continue
		if _current_filter != "all" and c.get("faction", "") != _current_filter:
			continue
		var btn = _make_companion_button(c)
		_companion_grid.add_child(btn)
		shown += 1

	if shown == 0:
		var empty = Label.new()
		empty.text = "No companions unlocked in this faction yet."
		empty.modulate = Color(0.5, 0.5, 0.5)
		_companion_grid.add_child(empty)

func _make_companion_button(companion: Dictionary) -> Button:
	var btn = Button.new()
	var rarity = companion.get("rarity", 1)
	var faction = companion.get("faction", "")
	var color = FACTION_COLORS.get(faction, Color.WHITE)
	btn.text = "%s\n%s\n%s" % [
		companion.get("name", "?"),
		RARITY_STARS.get(rarity, ""),
		companion.get("element", ""),
	]
	btn.modulate = color
	btn.custom_minimum_size = Vector2(80, 80)
	btn.pressed.connect(func(): _select_companion(companion))
	return btn

func _select_companion(companion: Dictionary) -> void:
	_selected = companion

	var get_lbl = func(n: String) -> Label:
		return _detail_panel.get_node_or_null("VBoxContainer/" + n) as Label

	var name_lbl = get_lbl.call("NameLabel")
	var faction_lbl = get_lbl.call("FactionLabel")
	var rarity_lbl = get_lbl.call("RarityLabel")
	var element_lbl = get_lbl.call("ElementLabel")
	var sig_lbl = get_lbl.call("SignatureLabel")
	var desc_lbl = get_lbl.call("DescLabel")

	if name_lbl: name_lbl.text = companion.get("name", "")
	if faction_lbl:
		faction_lbl.text = companion.get("faction", "")
		faction_lbl.modulate = FACTION_COLORS.get(companion.get("faction", ""), Color.WHITE)
	if rarity_lbl: rarity_lbl.text = RARITY_STARS.get(companion.get("rarity", 1), "")
	if element_lbl: element_lbl.text = "Element: " + companion.get("element", "none")
	if sig_lbl: sig_lbl.text = "⚡ " + companion.get("signature", "")
	if desc_lbl: desc_lbl.text = companion.get("desc", "")

	for slot in [1, 2, 3]:
		var btn = _detail_panel.get_node_or_null("VBoxContainer/HBoxContainer/EquipSlot%d" % slot)
		if btn: btn.visible = true

func _equip_to_slot(slot: int) -> void:
	if _selected.is_empty(): return
	var cid = _selected.get("id", "")
	if CompanionManager:
		CompanionManager.equip_companion(cid, slot)
	companion_equipped.emit(slot, cid)

func _get_all_companions() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	# Merge all roster sources
	if CompanionRoster:
		all.append_array(CompanionRoster.get_sovereign_crown_roster())
		all.append_array(CompanionRoster.get_wildlands_roster())
		all.append_array(CompanionRoster.get_veiled_current_roster())
		all.append_array(CompanionRoster.get_factionless_roster())
	return all
