class_name NPCDialogueUI
extends Control
# Branching dialogue UI — driven entirely by world_data/dialogue.json
# Non-coders: add dialogue nodes in the JSON to add new conversations.

signal quest_accepted(quest_id: String)
signal shop_opened(shop_id: String)
signal game_opened(game_id: String)
signal closed()

@onready var npc_name_label: Label = $Panel/VBox/NPCName
@onready var portrait_label: Label = $Panel/VBox/Portrait
@onready var disposition_label: Label = $Panel/VBox/DispositionRow/DispositionLabel
@onready var disposition_bar: ProgressBar = $Panel/VBox/DispositionRow/DispositionBar
@onready var dialogue_text: RichTextLabel = $Panel/VBox/DialogueText
@onready var options_container: VBoxContainer = $Panel/VBox/Options
@onready var typewriter_toggle: CheckButton = $Panel/VBox/TypewriterToggle
@onready var close_btn: Button = $Panel/VBox/CloseBtn

var _npc: Dictionary = {}
var _npc_id: String = ""
var _dialogue_id: String = ""
var _start_node: String = "greeting"
var _opening_line: String = ""
var _typewriter_tween: Tween = null

func open_for_npc(npc_id: String) -> void:
	_npc = WorldLoader.get_npc(npc_id)
	if _npc.is_empty():
		push_warning("[NPCDialogueUI] NPC not found: " + npc_id)
		return
	_npc_id = npc_id
	_dialogue_id = _npc.get("dialogue_id", "")
	var dlg := WorldLoader.get_dialogue(_dialogue_id)
	_start_node = str(dlg.get("start_node", "greeting"))
	portrait_label.text = str(_npc.get("emoji", "?"))
	npc_name_label.text = str(_npc.get("name", "NPC"))
	# Word of mouth, not a hive mind: this NPC's opening is based on
	# firsthand memory first, then rumors that have plausibly reached them.
	_opening_line = WordOfMouth.greeting_line(npc_id)
	_update_disposition_row()
	_show_node(_start_node)
	show()

func _show_node(node_id: String) -> void:
	if node_id == "END":
		_close()
		return
	var node := WorldLoader.get_dialogue_node(_dialogue_id, node_id)
	if node.is_empty():
		_close()
		return
	var line := _line_for_disposition(node)
	if node_id == _start_node and _opening_line != "":
		line = "[i]%s[/i]\n\n%s" % [_opening_line, line]
	_set_dialogue_text(line)
	_build_options(node.get("options", []))

func _build_options(options: Array) -> void:
	for child in options_container.get_children():
		child.queue_free()
	for opt in options:
		if not (opt is Dictionary):
			continue
		var btn := Button.new()
		btn.text = opt.get("label", "...")
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var option_data: Dictionary = opt
		btn.pressed.connect(func(): _choose_option(option_data))
		options_container.add_child(btn)
	_add_social_options()

func _choose_option(opt: Dictionary) -> void:
	_record_choice_interaction(opt)
	_update_disposition_row()
	_handle_action(str(opt.get("action", "nothing")))
	_show_node(str(opt.get("next_node", "END")))

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
		_update_disposition_row()
		_set_dialogue_text("[i]%s[/i]" % reaction)
	)
	options_container.add_child(btn)

func _handle_action(action: String) -> void:
	if action == "nothing" or action == "":
		return
	if action.begins_with("quest_accept:"):
		var qid := action.substr("quest_accept:".length())
		QuestManager.accept_quest(qid)
		quest_accepted.emit(qid)
		var quest_name := str(QuestManager.get_quest(qid).get("name", ""))
		if quest_name == "":
			quest_name = str(WorldLoader.get_quest(qid).get("title", qid))
		NotificationUI.notify("Quest accepted: " + quest_name)
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
		dialogue_text.visible_characters = -1
	if typewriter_toggle:
		typewriter_toggle.button_pressed = true
		typewriter_toggle.toggled.connect(_on_typewriter_toggled)
	if close_btn:
		close_btn.pressed.connect(_close)

func _line_for_disposition(node: Dictionary) -> String:
	var disposition := _current_disposition()
	if disposition >= 50:
		return str(node.get("text_friendly", node.get("friendly_text", node.get("text", "..."))))
	if disposition <= -50:
		return str(node.get("text_hostile", node.get("hostile_text", node.get("text", "..."))))
	return str(node.get("text", "..."))

func _set_dialogue_text(text: String) -> void:
	if _typewriter_tween != null and _typewriter_tween.is_running():
		_typewriter_tween.kill()
	dialogue_text.text = text
	if typewriter_toggle and typewriter_toggle.button_pressed:
		dialogue_text.visible_characters = 0
		var character_count := maxi(dialogue_text.get_total_character_count(), 1)
		var duration := clampf(float(character_count) / 45.0, 0.25, 4.0)
		_typewriter_tween = create_tween()
		_typewriter_tween.tween_property(dialogue_text, "visible_characters", character_count, duration)
	else:
		dialogue_text.visible_characters = -1

func _on_typewriter_toggled(enabled: bool) -> void:
	if not enabled:
		if _typewriter_tween != null and _typewriter_tween.is_running():
			_typewriter_tween.kill()
		dialogue_text.visible_characters = -1

func _record_choice_interaction(opt: Dictionary) -> void:
	var tone := str(opt.get("tone", ""))
	var effect = opt.get("effect", {})
	if not _is_word_of_mouth_tone(tone) and effect is Dictionary:
		tone = str(effect.get("tone", ""))
	if not _is_word_of_mouth_tone(tone):
		tone = _tone_from_choice(opt)
	if _is_word_of_mouth_tone(tone):
		WordOfMouth.record_interaction(_npc_id, tone)

func _tone_from_choice(opt: Dictionary) -> String:
	var label := str(opt.get("label", "")).to_lower()
	var action := str(opt.get("action", ""))
	if action == "nothing" or label.contains("goodbye") or label.contains("nothing") or label.contains("maybe later"):
		return ""
	if label.contains("insult") or label.contains("threat") or label.contains("not interested"):
		return "mean"
	if action.begins_with("quest_accept:") or action.begins_with("open_game:") or action == "shop_open" or action.begins_with("give_coins:"):
		return "nice"
	if label.contains("help") or label.contains("thanks") or label.contains("understood") or label.contains("deal"):
		return "nice"
	return ""

func _is_word_of_mouth_tone(tone: String) -> bool:
	return tone in WordOfMouth.TONES

func _current_disposition() -> int:
	var score := 0
	if WordOfMouth.has_met(_npc_id):
		score += WordOfMouth.times(_npc_id, "nice") * 15
		score += WordOfMouth.times(_npc_id, "flirt") * 8
		score += WordOfMouth.times(_npc_id, "marry") * 12
		score -= WordOfMouth.times(_npc_id, "mean") * 20
	elif WordOfMouth.has_heard(_npc_id):
		match WordOfMouth.dominant_tone():
			"nice":
				score += 20
			"flirt":
				score += 10
			"marry":
				score += 5
			"mean":
				score -= 25
	score += _faction_disposition_modifier()
	return clampi(score, -100, 100)

func _faction_disposition_modifier() -> int:
	var npc_faction := str(_npc.get("faction", "Factionless"))
	if FactionSystem.has_method("get_faction_disposition_modifier"):
		return int(FactionSystem.call("get_faction_disposition_modifier", npc_faction))
	var player_faction := str(PlayerProfile.get("faction"))
	if player_faction == npc_faction and npc_faction != "Factionless":
		return 20
	if player_faction != "Factionless" and npc_faction != "Factionless":
		return -10
	return 0

func _update_disposition_row() -> void:
	var npc_faction := str(_npc.get("faction", "Factionless"))
	var faction_name := npc_faction
	if FactionSystem.has_method("display_name"):
		faction_name = str(FactionSystem.display_name(npc_faction))
	var disposition := _current_disposition()
	disposition_label.text = "%s disposition: %s (%+d)" % [faction_name, _disposition_name(disposition), disposition]
	disposition_bar.min_value = 0
	disposition_bar.max_value = 200
	disposition_bar.value = disposition + 100
	var fill := StyleBoxFlat.new()
	fill.bg_color = _disposition_color(disposition)
	disposition_bar.add_theme_stylebox_override("fill", fill)

func _disposition_name(value: int) -> String:
	if value <= -60:
		return "Hostile"
	if value <= -20:
		return "Wary"
	if value >= 60:
		return "Devoted"
	if value >= 20:
		return "Friendly"
	return "Neutral"

func _disposition_color(value: int) -> Color:
	if value < 0:
		return Color(0.95, 0.25, 0.25).lerp(Color(0.95, 0.85, 0.25), float(value + 100) / 100.0)
	return Color(0.95, 0.85, 0.25).lerp(Color(0.2, 0.95, 0.45), float(value) / 100.0)