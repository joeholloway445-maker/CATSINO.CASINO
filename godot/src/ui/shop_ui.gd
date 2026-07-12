class_name ShopUI
extends Control

const FAVORITES_PATH := "user://cosmetics_favorites.json"
const ITEMS_PER_PAGE := 24
const CATEGORY_OPTIONS := ["all", "transmog", "aura", "particle", "title", "emote"]
const RARITY_OPTIONS := ["all", "common", "uncommon", "rare", "epic", "legendary"]
const RARITY_COLORS := {
	"common": Color(0.82, 0.86, 0.90),
	"uncommon": Color(0.35, 1.00, 0.45),
	"rare": Color(0.35, 0.62, 1.00),
	"epic": Color(0.78, 0.42, 1.00),
	"legendary": Color(1.00, 0.72, 0.22),
}

var _generator: CosmeticsGenerator = null
var _all_items: Array[Dictionary] = []
var _filtered_items: Array[Dictionary] = []
var _favorite_ids: Dictionary = {}
var _current_page := 0

var _search_edit: LineEdit
var _category_option: OptionButton
var _rarity_option: OptionButton
var _favorites_only: CheckButton
var _balance_label: Label
var _stats_label: Label
var _items_container: VBoxContainer
var _page_label: Label
var _previous_button: Button
var _next_button: Button

func _ready() -> void:
	_build_ui()
	_load_favorites()
	_load_cosmetics()
	_connect_economy()
	_update_balance()
	_apply_filters(true)

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var background := ColorRect.new()
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.color = Color(0.018, 0.010, 0.045)
	add_child(background)

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.offset_left = 24.0
	margin.offset_top = 24.0
	margin.offset_right = -24.0
	margin.offset_bottom = -24.0
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)

	var title := Label.new()
	title.text = "Cosmetics Shop"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 30)
	header.add_child(title)

	_balance_label = Label.new()
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_balance_label.add_theme_font_size_override("font_size", 18)
	header.add_child(_balance_label)

	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 10)
	root.add_child(filters)

	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "Search cosmetics..."
	_search_edit.clear_button_enabled = true
	_search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_edit.text_changed.connect(_on_search_changed)
	filters.add_child(_search_edit)

	_category_option = OptionButton.new()
	for category in CATEGORY_OPTIONS:
		_category_option.add_item(_format_option(category))
	_category_option.item_selected.connect(_on_filter_selected)
	filters.add_child(_category_option)

	_rarity_option = OptionButton.new()
	for rarity in RARITY_OPTIONS:
		_rarity_option.add_item(_format_option(rarity))
	_rarity_option.item_selected.connect(_on_filter_selected)
	filters.add_child(_rarity_option)

	_favorites_only = CheckButton.new()
	_favorites_only.text = "Favorites"
	_favorites_only.toggled.connect(_on_favorites_only_toggled)
	filters.add_child(_favorites_only)

	_stats_label = Label.new()
	_stats_label.modulate = Color(0.78, 0.82, 0.92)
	root.add_child(_stats_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_items_container = VBoxContainer.new()
	_items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_items_container)

	var pager := HBoxContainer.new()
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.add_theme_constant_override("separation", 12)
	root.add_child(pager)

	_previous_button = Button.new()
	_previous_button.text = "Previous"
	_previous_button.pressed.connect(_on_previous_page_pressed)
	pager.add_child(_previous_button)

	_page_label = Label.new()
	_page_label.custom_minimum_size = Vector2(150.0, 0.0)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pager.add_child(_page_label)

	_next_button = Button.new()
	_next_button.text = "Next"
	_next_button.pressed.connect(_on_next_page_pressed)
	pager.add_child(_next_button)

func _load_cosmetics() -> void:
	_generator = _resolve_generator()
	if _generator == null:
		_all_items.clear()
		_notify_error("The cosmetics archive is unreachable.")
		return

	var source: Array = []
	if _generator.get_cosmetics_count() <= 0:
		source = _generator.generate_all_cosmetics()
	else:
		source = _generator.search_cosmetics("")

	if source.is_empty():
		source = _generator.generate_all_cosmetics()

	_all_items = _coerce_items(source)

func _resolve_generator() -> CosmeticsGenerator:
	var node := get_node_or_null("/root/CosmeticsGenerator")
	if node is CosmeticsGenerator:
		return node as CosmeticsGenerator

	var created := CosmeticsGenerator.new()
	created.name = "CosmeticsGeneratorRuntime"
	add_child(created)
	return created

func _coerce_items(source: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in source:
		if item is Dictionary:
			result.append(item)
	return result

func _connect_economy() -> void:
	var economy := _economy()
	if economy == null:
		return
	var callback := Callable(self, "_on_balance_changed")
	if economy.has_signal("balance_changed") and not economy.is_connected("balance_changed", callback):
		economy.connect("balance_changed", callback)

func _economy():
	return get_node_or_null("/root/EconomyManager")

func _on_balance_changed(currency: String, _old_balance: int, _new_balance: int) -> void:
	if currency == "cat_coins":
		_update_balance()

func _update_balance() -> void:
	if _balance_label == null:
		return
	var economy := _economy()
	if economy == null:
		_balance_label.text = "Coins unavailable"
		return
	if economy.has_method("get_balance"):
		_balance_label.text = "Coins: %d" % int(economy.get_balance("cat_coins"))
	elif economy.has_method("get_coins"):
		_balance_label.text = "Coins: %d" % int(economy.get_coins())
	else:
		_balance_label.text = "Coins unavailable"

func _apply_filters(reset_page: bool) -> void:
	if reset_page:
		_current_page = 0

	_filtered_items.clear()
	var query := _search_edit.text.strip_edges().to_lower()
	var category := _selected_option(CATEGORY_OPTIONS, _category_option)
	var rarity := _selected_option(RARITY_OPTIONS, _rarity_option)
	var favorites_only := _favorites_only.button_pressed

	for item in _all_items:
		var item_id := str(item.get("id", ""))
		if favorites_only and not _is_favorite(item_id):
			continue
		if category != "all" and str(item.get("category", "")) != category:
			continue
		if rarity != "all" and str(item.get("rarity", "")) != rarity:
			continue
		if query != "" and not _search_text(item).contains(query):
			continue
		_filtered_items.append(item)

	_render_page()

func _selected_option(options: Array, option: OptionButton) -> String:
	if option == null:
		return "all"
	if option.selected < 0 or option.selected >= options.size():
		return "all"
	return str(options[option.selected])

func _search_text(item: Dictionary) -> String:
	var parts := [
		str(item.get("id", "")),
		str(item.get("name", "")),
		str(item.get("category", "")),
		str(item.get("rarity", "")),
		_describe_item(item),
	]
	return " ".join(parts).to_lower()

func _render_page() -> void:
	for child in _items_container.get_children():
		child.queue_free()

	var max_page := _max_page()
	if _current_page > max_page:
		_current_page = max_page
	if _current_page < 0:
		_current_page = 0

	if _filtered_items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No cosmetics match those filters."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.custom_minimum_size = Vector2(0.0, 180.0)
		_items_container.add_child(empty_label)
		_update_pager()
		_update_stats()
		return

	var start_index := _current_page * ITEMS_PER_PAGE
	var end_index := mini(start_index + ITEMS_PER_PAGE, _filtered_items.size())
	for index in range(start_index, end_index):
		_items_container.add_child(_create_item_card(_filtered_items[index]))

	_update_pager()
	_update_stats()

func _create_item_card(item: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _card_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 3)
	row.add_child(copy)

	var name_label := Label.new()
	name_label.text = str(item.get("name", "Unnamed Cosmetic"))
	name_label.modulate = _rarity_color(str(item.get("rarity", "common")))
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	copy.add_child(name_label)

	var meta_label := Label.new()
	meta_label.text = "%s / %s" % [
		_format_option(str(item.get("category", "unknown"))),
		_format_option(str(item.get("rarity", "unknown"))),
	]
	meta_label.modulate = Color(0.72, 0.76, 0.86)
	copy.add_child(meta_label)

	var details_label := Label.new()
	details_label.text = _describe_item(item)
	details_label.modulate = Color(0.62, 0.66, 0.76)
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	copy.add_child(details_label)

	var price_label := Label.new()
	price_label.text = "%d Coins" % int(item.get("price", 0))
	price_label.custom_minimum_size = Vector2(110.0, 0.0)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(price_label)

	var favorite_button := Button.new()
	var item_id := str(item.get("id", ""))
	favorite_button.text = "Saved" if _is_favorite(item_id) else "Save"
	favorite_button.custom_minimum_size = Vector2(82.0, 40.0)
	favorite_button.pressed.connect(_toggle_favorite.bind(item_id))
	row.add_child(favorite_button)

	var buy_button := Button.new()
	buy_button.text = "Buy"
	buy_button.custom_minimum_size = Vector2(78.0, 40.0)
	buy_button.disabled = item_id == "" or int(item.get("price", 0)) <= 0
	buy_button.pressed.connect(_purchase_item.bind(item))
	row.add_child(buy_button)

	return panel

func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.060, 0.045, 0.100, 0.96)
	style.border_color = Color(0.20, 0.16, 0.32, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func _describe_item(item: Dictionary) -> String:
	var category := str(item.get("category", ""))
	match category:
		"transmog":
			return "%s %s %s" % [
				_format_option(str(item.get("material", ""))),
				_format_option(str(item.get("style", ""))),
				_format_option(str(item.get("type", ""))),
			]
		"aura":
			return "%s %s %s aura" % [
				_format_option(str(item.get("element", ""))),
				_format_option(str(item.get("intensity", ""))),
				_format_option(str(item.get("shape", ""))),
			]
		"particle":
			return "%s %s %s particles" % [
				_format_option(str(item.get("frequency", ""))),
				_format_option(str(item.get("size", ""))),
				_format_option(str(item.get("effect", ""))),
			]
		"title":
			var boosts: Dictionary = item.get("stat_boost", {})
			return "Title boost: %s" % _format_stat_boosts(boosts)
		"emote":
			return "%s emote, %.1fs" % [
				_format_option(str(item.get("variant", item.get("type", "")))),
				float(item.get("duration", 0.0)),
			]
		_:
			return str(item.get("id", ""))

func _format_stat_boosts(boosts: Dictionary) -> String:
	if boosts.is_empty():
		return "none"
	var parts: Array[String] = []
	for key in boosts.keys():
		parts.append("%s +%s" % [str(key).to_upper(), str(boosts[key])])
	parts.sort()
	return ", ".join(parts)

func _purchase_item(item: Dictionary) -> void:
	var item_id := str(item.get("id", ""))
	var price := int(item.get("price", 0))
	if item_id == "" or price <= 0:
		_notify_error("That cosmetic cannot be purchased.")
		return

	var economy := _economy()
	if economy == null:
		_notify_error("Your wallet is unreachable.")
		return

	var success := false
	if economy.has_method("spend_currency"):
		success = await economy.spend_currency("cat_coins", price, "cosmetic_%s" % item_id)
	elif economy.has_method("spend_coins"):
		success = await economy.spend_coins(price, "cosmetic_%s" % item_id)
	else:
		_notify_error("Your wallet cannot spend coins here.")
		return

	if success:
		_notify_win("You bought %s for %d Coins." % [str(item.get("name", "a cosmetic")), price])
		_update_balance()
	else:
		_notify_error("%s needs %d Coins." % [str(item.get("name", "That cosmetic")), price])

func _toggle_favorite(item_id: String) -> void:
	if item_id == "":
		return
	if _favorite_ids.has(item_id):
		_favorite_ids.erase(item_id)
		_notify_info("Removed from cosmetics favorites.")
	else:
		_favorite_ids[item_id] = true
		_notify_info("Saved to cosmetics favorites.")
	_save_favorites()
	_apply_filters(false)

func _is_favorite(item_id: String) -> bool:
	return item_id != "" and _favorite_ids.has(item_id)

func _load_favorites() -> void:
	_favorite_ids.clear()
	if not FileAccess.file_exists(FAVORITES_PATH):
		return
	var file := FileAccess.open(FAVORITES_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		for raw_id in parsed:
			_favorite_ids[str(raw_id)] = true

func _save_favorites() -> void:
	var ids: Array[String] = []
	for item_id in _favorite_ids.keys():
		ids.append(str(item_id))
	ids.sort()
	var file := FileAccess.open(FAVORITES_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(ids))

func _max_page() -> int:
	if _filtered_items.is_empty():
		return 0
	return int(ceil(float(_filtered_items.size()) / float(ITEMS_PER_PAGE))) - 1

func _update_pager() -> void:
	var max_page := _max_page()
	var total_pages := max_page + 1
	_page_label.text = "Page %d / %d" % [_current_page + 1, total_pages]
	_previous_button.disabled = _current_page <= 0
	_next_button.disabled = _current_page >= max_page

func _update_stats() -> void:
	_stats_label.text = "%d shown of %d cosmetics (%d favorites)" % [
		_filtered_items.size(),
		_all_items.size(),
		_favorite_ids.size(),
	]

func _rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE) as Color

func _format_option(value: String) -> String:
	if value == "":
		return "Unknown"
	return value.replace("_", " ").capitalize()

func _on_search_changed(_text: String) -> void:
	_apply_filters(true)

func _on_filter_selected(_index: int) -> void:
	_apply_filters(true)

func _on_favorites_only_toggled(_pressed: bool) -> void:
	_apply_filters(true)

func _on_previous_page_pressed() -> void:
	if _current_page <= 0:
		return
	_current_page -= 1
	_render_page()

func _on_next_page_pressed() -> void:
	if _current_page >= _max_page():
		return
	_current_page += 1
	_render_page()

func _notify_win(message: String) -> void:
	_notify("notify_win", message)

func _notify_info(message: String) -> void:
	_notify("notify_info", message)

func _notify_error(message: String) -> void:
	_notify("notify_error", message)

func _notify(method: String, message: String) -> void:
	var notifier := get_node_or_null("/root/NotificationUI")
	if notifier != null and notifier.has_method(method):
		notifier.call(method, message)
	else:
		print(message)
