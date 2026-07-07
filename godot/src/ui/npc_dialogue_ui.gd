class_name NPCDialogueUI
extends Control
# Branching dialogue UI — driven entirely by world_data/dialogue.json
# Non-coders: add dialogue nodes in the JSON to add new conversations.

signal quest_accepted(quest_id: String)
signal shop_opened(shop_id: String)
signal game_opened(game_id: String)
signal closed()

@onready var npc_name_label: Label = $Panel/VBox/NPCName
@onready var dialogue_text: RichTextLabel = $Panel/VBox/DialogueText
@onready var options_container: VBoxContainer = $Panel/VBox/Options
@onready var close_btn: Button = $Panel/VBox/CloseBtn

var _npc: Dictionary = {}
var _npc_id: String = ""
var _dialogue_id: String = ""

func open_for_npc(npc_id: String) -> void:
	_npc = WorldLoader.get_npc(npc_id)
	if _npc.is_empty():
		push_warning("[NPCDialogueUI] NPC not found: " + npc_id)
		return
	_npc_id = npc_id
	_dialogue_id = _npc.get("dialogue_id", "")
	var dlg := WorldLoader.get_dialogue(_dialogue_id)
	var start := dlg.get("start_node", "greeting")
	npc_name_label.text = "%s %s" % [_npc.get("emoji", ""), _npc.get("name", "NPC")]
	_show_node(start)
	# Word of mouth, not a hive mind: what this specific NPC says first
	# depends on whether they've MET you, whether the talk about you has
	# reached them yet, and what that talk mostly says (WordOfMouth).
	var heard := WordOfMouth.greeting_line(npc_id)
	if heard != "":
		dialogue_text.text = "[i]%s[/i]\n\n%s" % [heard, dialogue_text.text]
	show()

func _show_node(node_id: String) -> void:
	if node_id == "END":
		_close()
		return
	var node := WorldLoader.get_dialogue_node(_dialogue_id, node_id)
	if node.is_empty():
		_close()
		return
	dialogue_text.text = node.get("text", "...")
	_build_options(node.get("options", []))

func _build_options(options: Array) -> void:
	for child in options_container.get_children():
		child.queue_free()
	for opt in options:
		var btn := Button.new()
		btn.text = opt.get("label", "...")
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var next: String = opt.get("next_node", "END")
		var action: String = opt.get("action", "nothing")
		btn.pressed.connect(func():
			_handle_action(action)
			_show_node(next)
		)
		options_container.add_child(btn)
	_add_social_options()

## Universal social moves on every NPC — be kind, be cruel, flirt, and
## (after enough flirting with the same person) propose. Each one feeds
## WordOfMouth, so the treatment comes back to you across the whole world,
## gradually, as gossip spreads.
func _add_social_options() -> void:
	_social_btn("😊 Be kind", "nice",
		"They soften. \"...Thank you. Not many bother.\"")
	_social_btn("😠 Insult them", "mean",
		"Their face closes like a door. They will remember this. So will their friends.")
	_social_btn("😘 Flirt", "flirt",
		"A beat of surprise — then the smallest smile. Word of THIS will definitely get around.")
	if WordOfMouth.times(_npc_id, "flirt") >= 5:
		_social_btn("💍 Propose", "marry",
			"They stare at you for a long moment. \"Ask me again when the layers stop shifting... but ask me again.\"")

func _social_btn(label: String, tone: String, reaction: String) -> void:
	var btn := Button.new()
	btn.text = label
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.modulate = Color(1, 1, 1, 0.75)
	btn.pressed.connect(func():
		WordOfMouth.record_interaction(_npc_id, tone)
		dialogue_text.text = "[i]%s[/i]" % reaction)
	options_container.add_child(btn)

func _handle_action(action: String) -> void:
	if action == "nothing" or action == "":
		return
	if action.begins_with("quest_accept:"):
		var qid := action.substr("quest_accept:".length())
		QuestManager.accept_quest(qid)
		quest_accepted.emit(qid)
		NotificationUI.notify("Quest accepted: " + WorldLoader.get_quest(qid).get("title", qid))
	elif action == "shop_open":
		var shop_id: String = _npc.get("shop_id", "")
		shop_opened.emit(shop_id)
	elif action.begins_with("open_game:"):
		game_opened.emit(action.substr("open_game:".length()))
	elif action.begins_with("give_coins:"):
		NotificationUI.notify_win("Received %s Cat Coins!" % action.substr("give_coins:".length()))

func _close() -> void:
	hide()
	closed.emit()

func _ready() -> void:
	hide()
	if dialogue_text:
		dialogue_text.bbcode_enabled = true # word-of-mouth lines use [i]…[/i]
	if close_btn:
		close_btn.pressed.connect(_close)
