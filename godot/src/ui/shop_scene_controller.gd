extends Control
## Wires the shop.tscn tree to ShopManager so the store is playable.

@onready var wallet_info: Label = $Header/WalletInfo
@onready var tab_bar: TabContainer = $TabBar
@onready var close_button: Button = $CloseButton

var _manager: Node

func _ready() -> void:
	_manager = get_node_or_null("ShopManager")
	if close_button:
		close_button.pressed.connect(func() -> void:
			get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	UINav.add_back_button(self)
	_refresh_wallet()
	_populate_tabs()
	if EconomyManager and EconomyManager.has_signal("balance_changed"):
		EconomyManager.balance_changed.connect(func(_c, _o, _n): _refresh_wallet())

func _refresh_wallet() -> void:
	if wallet_info == null or EconomyManager == null:
		return
	wallet_info.text = "🪙 %d  💎 %d" % [EconomyManager.get_coins(), EconomyManager.get_gems()]

func _populate_tabs() -> void:
	if _manager == null or not _manager.has_method("get_available_items"):
		return
	var items: Array = _manager.get_available_items()
	var buckets := {
		"Boosts": [],
		"Equipment": [],
		"Companions": [],
		"Consumables": [],
	}
	for item in items:
		var t = item.get("type", 0)
		# ShopManager.ShopType: COMPANION=0 COSMETIC=1 UPGRADE=2 CONSUMABLE=3
		match int(t):
			0: buckets["Companions"].append(item)
			1: buckets["Equipment"].append(item)
			2: buckets["Boosts"].append(item)
			3: buckets["Consumables"].append(item)
			_: buckets["Boosts"].append(item)
	for tab_name in buckets.keys():
		var tab := tab_bar.get_node_or_null(tab_name) as Control
		if tab == null:
			continue
		for c in tab.get_children():
			c.queue_free()
		var list := VBoxContainer.new()
		list.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tab.add_child(list)
		for item in buckets[tab_name]:
			list.add_child(_make_item_row(item))

func _make_item_row(item: Dictionary) -> Control:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	var price_c: int = int(item.get("price_coins", 0))
	var price_g: int = int(item.get("price_gems", 0))
	var price_txt := ("%d 🪙" % price_c) if price_c > 0 else ("%d 💎" % price_g)
	lbl.text = "%s %s — %s (%s) stock %d" % [
		item.get("icon", "•"), item.get("name", "?"), item.get("desc", ""),
		price_txt, int(item.get("stock_remaining", 0)),
	]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var buy := Button.new()
	buy.text = "Buy"
	var item_id: String = str(item.get("id", ""))
	buy.pressed.connect(func() -> void: _buy(item_id))
	row.add_child(buy)
	return row

func _buy(item_id: String) -> void:
	if _manager == null or not _manager.has_method("purchase"):
		return
	var result = await _manager.purchase(item_id)
	if result is Dictionary:
		if result.get("success", false):
			NotificationUI.notify_win("Purchased!")
		else:
			NotificationUI.notify_error(str(result.get("reason", "Purchase failed")))
	_refresh_wallet()
	_populate_tabs()
