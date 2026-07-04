extends Control

enum InventoryTab { EQUIPMENT, COMPANIONS, CONSUMABLES, COSMETICS }

var _current_tab: InventoryTab = InventoryTab.EQUIPMENT
var _selected_item: Dictionary = {}
var _item_list: VBoxContainer
var _detail_panel: PanelContainer
var _equip_btn: Button
var _unequip_btn: Button

func _ready() -> void:
	_build_ui()
	_refresh_current_tab()
	InventoryManager.item_added.connect(_on_item_changed)
	InventoryManager.item_removed.connect(_on_item_changed)
	InventoryManager.item_equipped.connect(_on_equip_changed)

func _build_ui() -> void:
	var root = HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Left: tab list
	var left = VBoxContainer.new()
	left.custom_minimum_size = Vector2(200, 0)
	root.add_child(left)

	var tabs_label = Label.new()
	tabs_label.text = "INVENTORY"
	tabs_label.add_theme_font_size_override("font_size", 18)
	left.add_child(tabs_label)

	for tab_name in ["Equipment", "Companions", "Consumables", "Cosmetics"]:
		var btn = Button.new()
		btn.text = tab_name
		var idx = InventoryTab.get(tab_name.upper())
		btn.pressed.connect(func(): _switch_tab(idx if idx != null else 0))
		left.add_child(btn)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)

	_item_list = VBoxContainer.new()
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_item_list)

	# Right: detail panel
	_detail_panel = PanelContainer.new()
	_detail_panel.custom_minimum_size = Vector2(300, 0)
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_detail_panel)

	var detail_vbox = VBoxContainer.new()
	_detail_panel.add_child(detail_vbox)

	var name_lbl = Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = "Select an item"
	name_lbl.add_theme_font_size_override("font_size", 16)
	detail_vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.name = "DescLabel"
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_vbox.add_child(desc_lbl)

	var stats_lbl = Label.new()
	stats_lbl.name = "StatsLabel"
	stats_lbl.add_theme_font_size_override("font_size", 11)
	detail_vbox.add_child(stats_lbl)

	var btn_row = HBoxContainer.new()
	detail_vbox.add_child(btn_row)

	_equip_btn = Button.new()
	_equip_btn.text = "EQUIP"
	_equip_btn.pressed.connect(_on_equip_pressed)
	_equip_btn.visible = false
	btn_row.add_child(_equip_btn)

	_unequip_btn = Button.new()
	_unequip_btn.text = "UNEQUIP"
	_unequip_btn.pressed.connect(_on_unequip_pressed)
	_unequip_btn.visible = false
	btn_row.add_child(_unequip_btn)

	var use_btn = Button.new()
	use_btn.name = "UseButton"
	use_btn.text = "USE"
	use_btn.pressed.connect(_on_use_pressed)
	use_btn.visible = false
	btn_row.add_child(use_btn)

func _switch_tab(tab: int) -> void:
	_current_tab = tab as InventoryTab
	_selected_item = {}
	_clear_detail()
	_refresh_current_tab()

func _refresh_current_tab() -> void:
	for child in _item_list.get_children():
		child.queue_free()

	var items: Array[Dictionary] = []
	match _current_tab:
		InventoryTab.EQUIPMENT:
			items = InventoryManager.get_items_by_type("equipment")
		InventoryTab.COMPANIONS:
			items = InventoryManager.get_items_by_type("companion")
		InventoryTab.CONSUMABLES:
			items = InventoryManager.get_items_by_type("consumable")
		InventoryTab.COSMETICS:
			items = InventoryManager.get_items_by_type("cosmetic")

	if items.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Nothing here yet."
		empty_lbl.modulate = Color(0.5, 0.5, 0.5)
		_item_list.add_child(empty_lbl)
		return

	for item in items:
		var row = _build_item_row(item)
		_item_list.add_child(row)

func _build_item_row(item: Dictionary) -> Button:
	var btn = Button.new()
	var rarity = item.get("rarity", 1)
	var rarity_star = "★".repeat(rarity)
	btn.text = "%s %s %s" % [item.get("icon", "📦"), item.get("name", "?"), rarity_star]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var is_equipped = InventoryManager.is_equipped(item.get("id", ""))
	if is_equipped:
		btn.modulate = Color(0.5, 1.0, 0.5)
	btn.pressed.connect(func(): _select_item(item))
	return btn

func _select_item(item: Dictionary) -> void:
	_selected_item = item
	var name_lbl = _detail_panel.get_node_or_null("VBoxContainer/NameLabel")
	var desc_lbl = _detail_panel.get_node_or_null("VBoxContainer/DescLabel")
	var stats_lbl = _detail_panel.get_node_or_null("VBoxContainer/StatsLabel")
	var use_btn = _detail_panel.get_node_or_null("VBoxContainer/HBoxContainer/UseButton")

	if name_lbl: name_lbl.text = item.get("name", "Unknown")
	if desc_lbl: desc_lbl.text = item.get("description", "")
	if stats_lbl:
		var stats = item.get("stats", {})
		var stat_text = ""
		for key in stats:
			stat_text += "%s: %+d\n" % [key.to_upper(), stats[key]]
		stats_lbl.text = stat_text if not stat_text.is_empty() else "No stat bonuses"

	var item_type = item.get("item_type", "")
	var is_equipped = InventoryManager.is_equipped(item.get("id", ""))
	_equip_btn.visible = item_type in ["weapon", "armor", "accessory"] and not is_equipped
	_unequip_btn.visible = is_equipped
	if use_btn:
		use_btn.visible = item_type == "consumable"

func _clear_detail() -> void:
	var name_lbl = _detail_panel.get_node_or_null("VBoxContainer/NameLabel")
	if name_lbl: name_lbl.text = "Select an item"
	_equip_btn.visible = false
	_unequip_btn.visible = false

func _on_equip_pressed() -> void:
	if _selected_item.is_empty(): return
	InventoryManager.equip_item(_selected_item.get("id", ""))

func _on_unequip_pressed() -> void:
	if _selected_item.is_empty(): return
	InventoryManager.unequip_item(_selected_item.get("id", ""))

func _on_use_pressed() -> void:
	if _selected_item.is_empty(): return
	InventoryManager.use_item(_selected_item.get("id", ""))

func _on_item_changed(_item) -> void:
	_refresh_current_tab()

func _on_equip_changed(_id, _equipped) -> void:
	_refresh_current_tab()
	if not _selected_item.is_empty():
		_select_item(_selected_item)
