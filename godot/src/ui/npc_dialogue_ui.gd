class_name NPCDialogueUI
extends Control

signal dialogue_closed
signal quest_accepted(quest_id: String)
signal shop_opened(shop_type: String)

@onready var portrait_label: Label = $Panel/VBox/Portrait
@onready var name_label: Label = $Panel/VBox/NameLabel
@onready var dialogue_label: Label = $Panel/VBox/DialogueLabel
@onready var options_container: VBoxContainer = $Panel/VBox/Options
@onready var close_btn: Button = $Panel/VBox/CloseBtn

var current_npc: Dictionary = {}

func show_npc(npc_id: String) -> void:
	current_npc = NPCData.get_npc(npc_id)
	if current_npc.is_empty():
		return
	_populate_ui()
	show()

func _populate_ui() -> void:
	name_label.text = current_npc.get("name", "???")
	dialogue_label.text = current_npc.get("greeting", "...")
	_build_options()

func _build_options() -> void:
	for child in options_container.get_children():
		child.queue_free()

	for quest_id in current_npc.get("quest_ids", []):
		var btn := Button.new()
		btn.text = "📋 Accept Quest: %s" % quest_id.replace("_", " ").capitalize()
		btn.pressed.connect(func(): quest_accepted.emit(quest_id))
		options_container.add_child(btn)

	var shop := current_npc.get("shop_type", "none")
	if shop != "none":
		var btn := Button.new()
		btn.text = "🛒 Open Shop"
		btn.pressed.connect(func(): shop_opened.emit(shop))
		options_container.add_child(btn)

func _ready() -> void:
	hide()
	close_btn.pressed.connect(_close)

func _close() -> void:
	hide()
	dialogue_closed.emit()
