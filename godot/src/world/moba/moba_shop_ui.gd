class_name MobaShopUI
extends CanvasLayer
## Toggleable in-match shop for Paws of the Ancients. Open with B / shop button.

signal closed()

var shop: MobaShop
var _panel: PanelContainer
var _list: VBoxContainer
var _gold_lbl: Label
var _open := false

func setup(p_shop: MobaShop) -> void:
	shop = p_shop
	layer = 20
	_build()
	shop.gold_changed.connect(_on_gold)
	visible = false

func toggle() -> void:
	if _open:
		close()
	else:
		open()

func open() -> void:
	_open = true
	visible = true
	_rebuild_list()
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
	_panel.custom_minimum_size = Vector2(360, 420)
	_panel.position = Vector2(24, 80)
	root.add_child(_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
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
	var hint := Label.new()
	hint.text = "Match gold only — press B to toggle"
	hint.modulate = Color(0.7, 0.75, 0.85)
	col.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 300)
	col.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

func _rebuild_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	for item in shop.catalog():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
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

func _buy(item_id: String) -> void:
	var result := shop.buy(item_id)
	if not result.get("success", false):
		NotificationUI.notify_error(str(result.get("error", "Purchase failed")))
		return
	NotificationUI.notify_win("Bought %s" % str(result.item.name))
	_rebuild_list()

func _on_gold(amount: int) -> void:
	if _gold_lbl:
		_gold_lbl.text = "%dg" % amount
	if _open:
		_rebuild_list()
