class_name MobaShopUI
extends CanvasLayer
## In-match shop with categories, inventory sellback, and base-only gating.

signal closed()

var shop: MobaShop
var can_shop_cb: Callable # () -> bool
var _panel: PanelContainer
var _list: VBoxContainer
var _inv: VBoxContainer
var _gold_lbl: Label
var _status: Label
var _open := false
var _category := ""

func setup(p_shop: MobaShop, p_can_shop: Callable = Callable()) -> void:
	shop = p_shop
	can_shop_cb = p_can_shop
	layer = 20
	_build()
	shop.gold_changed.connect(_on_gold)
	shop.inventory_changed.connect(_rebuild_inv)
	visible = false

func toggle() -> void:
	if _open:
		close()
	else:
		open()

func open() -> void:
	if can_shop_cb.is_valid() and not can_shop_cb.call():
		NotificationUI.notify_error("Shop only at the ally fountain — recall (R) or walk home.")
		return
	_open = true
	visible = true
	_rebuild_list()
	_rebuild_inv()
	_on_gold(shop.gold)

func close() -> void:
	_open = false
	visible = false
	closed.emit()

func is_open() -> bool:
	return _open

func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(420, 520)
	_panel.position = Vector2(24, 72)
	root.add_child(_panel)
	var margin := MarginContainer.new()
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(m, 10)
	_panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	margin.add_child(col)
	var header := HBoxContainer.new()
	col.add_child(header)
	var title := Label.new()
	title.text = "Item Shop"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)
	_gold_lbl = Label.new()
	_gold_lbl.text = "0g"
	header.add_child(_gold_lbl)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.pressed.connect(close)
	header.add_child(close_btn)
	_status = Label.new()
	_status.text = "Fountain only · B toggle · sell 50%"
	_status.modulate = Color(0.7, 0.75, 0.85)
	col.add_child(_status)
	var cats := HBoxContainer.new()
	col.add_child(cats)
	for c in ["", "offense", "defense", "utility", "consumable"]:
		var b := Button.new()
		b.text = "All" if c.is_empty() else c.capitalize()
		var cat := c
		b.pressed.connect(func():
			_category = cat
			_rebuild_list())
		cats.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 260)
	col.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 5)
	scroll.add_child(_list)
	var inv_title := Label.new()
	inv_title.text = "Inventory (sell 50%)"
	col.add_child(inv_title)
	_inv = VBoxContainer.new()
	_inv.add_theme_constant_override("separation", 4)
	col.add_child(_inv)

func _rebuild_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	for item in shop.catalog(_category):
		var row := HBoxContainer.new()
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_lbl := Label.new()
		name_lbl.text = "%s — %dg" % [item.name, int(item.price)]
		info.add_child(name_lbl)
		var desc := Label.new()
		desc.text = str(item.desc)
		desc.modulate = Color(0.75, 0.8, 0.9)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(desc)
		row.add_child(info)
		var buy := Button.new()
		buy.text = "Buy"
		buy.disabled = not shop.can_afford(str(item.id))
		var item_id := str(item.id)
		buy.pressed.connect(func(): _buy(item_id))
		row.add_child(buy)
		_list.add_child(row)

func _rebuild_inv() -> void:
	if _inv == null:
		return
	for c in _inv.get_children():
		c.queue_free()
	if shop.inventory.is_empty():
		var empty := Label.new()
		empty.text = "(empty)"
		empty.modulate = Color(0.6, 0.6, 0.7)
		_inv.add_child(empty)
		return
	for i in shop.inventory.size():
		var entry: Dictionary = shop.inventory[i]
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "%s (%dg)" % [entry.get("name", "?"), int(round(float(entry.get("price", 0)) * 0.5))]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var sell := Button.new()
		sell.text = "Sell"
		var slot := i
		sell.pressed.connect(func(): _sell(slot))
		row.add_child(sell)
		_inv.add_child(row)

func _buy(item_id: String) -> void:
	if can_shop_cb.is_valid() and not can_shop_cb.call():
		NotificationUI.notify_error("Leave fountain — shop closed.")
		close()
		return
	var result := shop.buy(item_id)
	if not result.get("success", false):
		NotificationUI.notify_error(str(result.get("error", "Purchase failed")))
		return
	NotificationUI.notify_win("Bought %s" % str(result.item.name))
	_rebuild_list()
	_rebuild_inv()

func _sell(slot: int) -> void:
	var result := shop.sell(slot)
	if not result.get("success", false):
		NotificationUI.notify_error(str(result.get("error", "Sell failed")))
		return
	NotificationUI.notify_info("Sold for %dg" % int(result.get("refund", 0)))
	_rebuild_list()
	_rebuild_inv()

func _on_gold(amount: int) -> void:
	if _gold_lbl:
		_gold_lbl.text = "%dg · %d/%d slots" % [amount, shop.inventory.size(), MobaShop.MAX_SLOTS]
	if _open:
		_rebuild_list()
