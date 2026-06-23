extends PanelContainer

class_name SocialPanel

# ─── Child node references ────────────────────────────────────────────────────
@onready var friend_list: VBoxContainer = $Layout/LeftColumn/FriendListScroll/FriendList
@onready var guild_label: Label = $Layout/LeftColumn/GuildLabel
@onready var member_count_label: Label = $Layout/LeftColumn/MemberCountLabel
@onready var add_friend_input: LineEdit = $Layout/LeftColumn/AddFriendRow/AddFriendInput
@onready var add_friend_button: Button = $Layout/LeftColumn/AddFriendRow/AddFriendButton
@onready var chat_log: RichTextLabel = $Layout/RightColumn/ChatScroll/ChatLog
@onready var chat_input: LineEdit = $Layout/RightColumn/ChatRow/ChatInput
@onready var send_button: Button = $Layout/RightColumn/ChatRow/SendButton
@onready var close_button: Button = $Layout/TopBar/CloseButton
@onready var channel_option: OptionButton = $Layout/RightColumn/ChannelRow/ChannelOption

# ─── State ────────────────────────────────────────────────────────────────────
var _current_channel: String = "general"
var _friend_entries: Dictionary = {}  # user_id -> HBoxContainer node

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	send_button.pressed.connect(_on_send_pressed)
	add_friend_button.pressed.connect(_on_add_friend_button_pressed)
	chat_input.text_submitted.connect(_on_chat_submitted)

	channel_option.add_item("general")
	channel_option.add_item("guild")
	channel_option.add_item("district")
	channel_option.item_selected.connect(_on_channel_selected)

	# Connect SocialManager signals
	if SocialManager.has_signal("chat_received"):
		SocialManager.chat_received.connect(_on_chat_received)
	if SocialManager.has_signal("friend_online"):
		SocialManager.friend_online.connect(_on_friend_online)
	if SocialManager.has_signal("friend_offline"):
		SocialManager.friend_offline.connect(_on_friend_offline)
	if SocialManager.has_signal("friend_list_updated"):
		SocialManager.friend_list_updated.connect(_on_friend_list_updated)
	if SocialManager.has_signal("guild_updated"):
		SocialManager.guild_updated.connect(_on_guild_updated)

	_load_initial_state()

# ─── Init ─────────────────────────────────────────────────────────────────────
func _load_initial_state() -> void:
	var friends: Array = SocialManager.get_friend_list()
	for friend_data in friends:
		_add_or_update_friend_entry(friend_data)

	var guild := SocialManager.get_guild_info()
	_apply_guild_info(guild)

	# Populate recent chat history if available
	var history: Array = SocialManager.get_chat_history(_current_channel)
	for msg in history:
		_append_chat_message(msg.get("sender", "?"), msg.get("text", ""), msg.get("ts", ""))

# ─── Friend list ─────────────────────────────────────────────────────────────
func _add_or_update_friend_entry(friend_data: Dictionary) -> void:
	var uid: String = friend_data.get("user_id", "")
	if uid.is_empty():
		return

	var online: bool = friend_data.get("online", false)

	if _friend_entries.has(uid):
		var row: HBoxContainer = _friend_entries[uid]
		if is_instance_valid(row):
			var dot: Label = row.get_node_or_null("OnlineDot")
			if dot:
				dot.modulate = Color.GREEN if online else Color(0.4, 0.4, 0.4)
		return

	var row := HBoxContainer.new()
	row.name = "Friend_" + uid

	var dot := Label.new()
	dot.name = "OnlineDot"
	dot.text = "●"
	dot.modulate = Color.GREEN if online else Color(0.4, 0.4, 0.4)
	dot.custom_minimum_size = Vector2(20, 0)
	row.add_child(dot)

	var name_label := Label.new()
	name_label.text = friend_data.get("display_name", uid)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var whisper_btn := Button.new()
	whisper_btn.text = "W"
	whisper_btn.tooltip_text = "Whisper"
	whisper_btn.custom_minimum_size = Vector2(28, 0)
	whisper_btn.pressed.connect(func() -> void:
		chat_input.text = "/w %s " % uid
		chat_input.grab_focus()
	)
	row.add_child(whisper_btn)

	friend_list.add_child(row)
	_friend_entries[uid] = row

func _set_friend_online(user_id: String, online: bool) -> void:
	if not _friend_entries.has(user_id):
		return
	var row: HBoxContainer = _friend_entries[user_id]
	if is_instance_valid(row):
		var dot: Label = row.get_node_or_null("OnlineDot")
		if dot:
			dot.modulate = Color.GREEN if online else Color(0.4, 0.4, 0.4)

# ─── Guild info ───────────────────────────────────────────────────────────────
func _apply_guild_info(guild: Dictionary) -> void:
	guild_label.text = "Guild: %s" % guild.get("name", "—")
	member_count_label.text = "%d members" % guild.get("member_count", 0)

# ─── Chat ─────────────────────────────────────────────────────────────────────
func _append_chat_message(sender: String, text: String, ts: String) -> void:
	var time_str := ts.substr(11, 5) if ts.length() >= 16 else ""
	var line := "[color=#aaaaaa][%s][/color] [b]%s:[/b] %s" % [time_str, sender, text]
	chat_log.append_text(line + "\n")
	# Auto-scroll to bottom
	await get_tree().process_frame
	var scroll: VScrollBar = chat_log.get_v_scroll_bar()
	if scroll:
		scroll.value = scroll.max_value

# ─── Signal handlers ─────────────────────────────────────────────────────────
func _on_send_pressed() -> void:
	_send_chat()

func _on_chat_submitted(_text: String) -> void:
	_send_chat()

func _send_chat() -> void:
	var message := chat_input.text.strip_edges()
	if message.is_empty():
		return
	SocialManager.chat_send(_current_channel, message)
	chat_input.clear()

func _on_add_friend_button_pressed() -> void:
	var uid := add_friend_input.text.strip_edges()
	if uid.is_empty():
		return
	SocialManager.add_friend(uid)
	add_friend_input.clear()

func _on_close_pressed() -> void:
	visible = false

func _on_channel_selected(index: int) -> void:
	_current_channel = channel_option.get_item_text(index)
	chat_log.clear()
	var history: Array = SocialManager.get_chat_history(_current_channel)
	for msg in history:
		_append_chat_message(msg.get("sender", "?"), msg.get("text", ""), msg.get("ts", ""))

func _on_chat_received(channel: String, sender: String, text: String, ts: String) -> void:
	if channel == _current_channel:
		_append_chat_message(sender, text, ts)

func _on_friend_online(user_id: String) -> void:
	_set_friend_online(user_id, true)

func _on_friend_offline(user_id: String) -> void:
	_set_friend_online(user_id, false)

func _on_friend_list_updated(friends: Array) -> void:
	for friend_data in friends:
		_add_or_update_friend_entry(friend_data)

func _on_guild_updated(guild: Dictionary) -> void:
	_apply_guild_info(guild)
