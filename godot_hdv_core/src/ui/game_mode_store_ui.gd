extends Control
## Lists purchasable game modes, lets the player buy/activate them, and
## shows which is currently active. Backed by GameModeStore/GameModeManager.

const GameModeData = preload("res://src/data/game_mode_data.gd")

@onready var mode_list: ItemList = $ModeList
@onready var status_label: Label = $StatusLabel
@onready var buy_button: Button = $BuyButton
@onready var activate_button: Button = $ActivateButton

func _ready() -> void:
	_populate()
	mode_list.item_selected.connect(_on_mode_selected)
	buy_button.pressed.connect(_on_buy_pressed)
	activate_button.pressed.connect(_on_activate_pressed)
	GameModeManager.active_mode_changed.connect(func(_id): _populate())

func _populate() -> void:
	mode_list.clear()
	for mode in GameModeData.MODES:
		var label: String = mode["name"]
		if GameModeManager.owns(mode["id"]):
			label += " (owned)"
		if mode["id"] == GameModeManager.active_mode_id:
			label += " — ACTIVE"
		mode_list.add_item(label)
	status_label.text = "Active mode: %s" % GameModeManager.active_mode().get("name", "")

func _on_mode_selected(index: int) -> void:
	var mode: Dictionary = GameModeData.MODES[index]
	status_label.text = "%s\n%s\nPrice: $%.2f" % [mode["name"], mode["description"], GameModeStore.price_usd(mode["id"])]

func _on_buy_pressed() -> void:
	var index := mode_list.get_selected_items()
	if index.is_empty():
		return
	var mode: Dictionary = GameModeData.MODES[index[0]]
	GameModeStore.purchase(mode["id"])
	_populate()

func _on_activate_pressed() -> void:
	var index := mode_list.get_selected_items()
	if index.is_empty():
		return
	var mode: Dictionary = GameModeData.MODES[index[0]]
	if not GameModeManager.set_active(mode["id"]):
		return
	if mode.get("sandboxed", false):
		get_tree().change_scene_to_file("res://scenes/ui/creator_mode.tscn")
		return
	_populate()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/worlds/world_select.tscn")
