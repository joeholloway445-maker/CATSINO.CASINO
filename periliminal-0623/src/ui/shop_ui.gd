class_name ShopUI
extends Control

@onready var item_list: VBoxContainer = $Panel/VBox/ScrollContainer/ItemList
@onready var balance_label: Label = $Panel/VBox/BalanceLabel
@onready var filter_option: OptionButton = $Panel/VBox/FilterOption

const SHOP_CATEGORIES := ["all", "consumables", "frames", "mods", "companions", "cosmetics"]

func _ready() -> void:
	for cat in SHOP_CATEGORIES:
		filter_option.add_item(cat.capitalize())
	filter_option.item_selected.connect(func(_i): _refresh())
	_refresh()
	_refresh_balance()

func _refresh() -> void:
	NetworkManager.call_rpc("get_shop_inventory", {},
		func(result: Dictionary):
			var items: Array = result.get("items", [])
			_render(items)
	)

func _refresh_balance() -> void:
	NetworkManager.call_rpc("get_wallet", {},
		func(result: Dictionary):
			balance_label.text = "Balance: 🪙 %d" % result.get("cat_coins", 0)
	)

func _render(items: Array) -> void:
	for child in item_list.get_children():
		child.queue_free()

	var cat := SHOP_CATEGORIES[filter_option.selected]
	for item in items:
		if cat != "all" and item.get("type", "") != cat:
			continue
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = item.get("name", "Item")
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var price_label := Label.new()
		price_label.text = "🪙 %d" % item.get("price", 0)
		var buy_btn := Button.new()
		buy_btn.text = "Buy"
		var item_id: String = item.get("id", "")
		buy_btn.pressed.connect(func(): _buy(item_id, item.get("price", 0)))
		row.add_child(name_label)
		row.add_child(price_label)
		row.add_child(buy_btn)
		item_list.add_child(row)

func _buy(item_id: String, price: int) -> void:
	NetworkManager.call_rpc("shop_purchase", {item_id=item_id},
		func(result: Dictionary):
			if result.get("success"):
				NotificationUI.notify_win("Purchased! -🪙 %d" % price)
				_refresh_balance()
			else:
				NotificationUI.notify_error("Purchase failed: %s" % result.get("error", ""))
	)
