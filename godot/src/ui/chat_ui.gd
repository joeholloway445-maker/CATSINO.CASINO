class_name ChatUI
extends CanvasLayer
## The 5-channel chat panel: tab row (Local/Global/Guild/Faction/Whisper),
## scrollback per channel, Enter to send, `/w name message` for whispers.
## Toggle with T. Add to any scene: add_child(ChatUI.new()).

var _tabs: TabBar
var _log: RichTextLabel
var _input: LineEdit
var _root: PanelContainer
var _logs: Dictionary = {} # channel -> Array[String]

const CHANNEL_COLORS := {
	"local": "aaffaa", "global": "ffffff", "guild": "aaddff",
	"faction": "ffcc88", "whisper": "ff99dd",
}

func _ready() -> void:
	_root = PanelContainer.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_root.position += Vector2(8, -220)
	_root.custom_minimum_size = Vector2(420, 210)
	_root.modulate.a = 0.9
	add_child(_root)

	var box := VBoxContainer.new()
	_root.add_child(box)

	_tabs = TabBar.new()
	for c in ChatManager.CHANNELS:
		_tabs.add_tab(c.capitalize())
	_tabs.tab_changed.connect(func(_i): _refresh())
	box.add_child(_tabs)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.custom_minimum_size = Vector2(0, 130)
	box.add_child(_log)

	_input = LineEdit.new()
	_input.placeholder_text = "Enter to send • /w name msg whispers • T toggles"
	_input.text_submitted.connect(_on_submit)
	box.add_child(_input)

	for c in ChatManager.CHANNELS:
		_logs[c] = []
	ChatManager.message_received.connect(_on_message)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		if not _input.has_focus():
			_root.visible = not _root.visible

func _current_channel() -> String:
	return ChatManager.CHANNELS[_tabs.current_tab]

func _on_submit(text: String) -> void:
	_input.clear()
	text = text.strip_edges()
	if text == "":
		return
	if text.begins_with("/w "):
		var parts := text.substr(3).split(" ", true, 1)
		if parts.size() == 2:
			ChatManager.send("whisper", parts[1], parts[0])
		return
	ChatManager.send(_current_channel(), text)

func _on_message(channel: String, from: String, text: String) -> void:
	var color: String = CHANNEL_COLORS.get(channel, "ffffff")
	_logs[channel].append("[color=#%s][%s] %s:[/color] %s" % [color, channel.to_upper(), from, text])
	if _logs[channel].size() > 100:
		_logs[channel].pop_front()
	if channel == _current_channel():
		_refresh()

func _refresh() -> void:
	_log.text = "\n".join(_logs.get(_current_channel(), []))
