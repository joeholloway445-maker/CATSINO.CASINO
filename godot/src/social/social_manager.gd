extends Node

# ── Signals ────────────────────────────────────────────────────────────────────
signal friend_online(user_id: String, username: String)
signal friend_offline(user_id: String)
signal friend_request_received(user_id: String, username: String)
signal guild_message(guild_id: String, sender: String, content: String)
signal chat_received(channel: String, sender: String, content: String, timestamp: int)
signal guild_joined(guild_id: String, guild_name: String)
signal guild_left(guild_id: String)
signal guild_created(guild: Dictionary)
signal invite_received(guild_id: String, guild_name: String, inviter: String)

# ── Constants ──────────────────────────────────────────────────────────────────
const CHANNEL_GLOBAL  := "global"
const CHANNEL_DISTRICT := "district"  # appended with district name
const CHANNEL_GUILD   := "guild"

# ── State ──────────────────────────────────────────────────────────────────────
var _socket            = null
var _nakama_client     = null
var _session           = null
var friend_list:  Array[Dictionary] = []
var online_friends: Dictionary = {}  # user_id -> presence data
var current_guild: Dictionary  = {}
var chat_history: Dictionary   = {}  # channel -> Array[Dictionary]

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	pass

func initialize() -> void:
	if AccountManager and AccountManager.is_authenticated:
		_nakama_client = AccountManager.get_nakama_client()
		_session       = AccountManager.get_nakama_session()
		await _connect_socket()
		await _load_friends()

# ── Chat ───────────────────────────────────────────────────────────────────────
func chat_send(channel: String, message: String) -> void:
	if not _socket:
		push_warning("SocialManager: socket not connected")
		return
	if message.strip_edges().is_empty():
		return
	var channel_id := _channel_id(channel)
	await _socket.write_chat_message_async(channel_id, message)

func join_channel(channel: String) -> void:
	if not _socket:
		return
	var channel_id := _channel_id(channel)
	var result = await _socket.join_chat_async(channel_id, NakamaSocket.ChannelType.ROOM, false, false)
	if result.is_exception():
		push_error("SocialManager: join_channel %s failed: %s" % [channel, result.get_exception().message])

# ── Friends ────────────────────────────────────────────────────────────────────
func add_friend(user_id: String) -> void:
	if not _nakama_client or not _session:
		return
	var result = await _nakama_client.add_friends_async(_session, [user_id])
	if result.is_exception():
		push_error("SocialManager: add_friend failed: %s" % result.get_exception().message)
		return
	await _load_friends()

func remove_friend(user_id: String) -> void:
	if not _nakama_client or not _session:
		return
	await _nakama_client.delete_friends_async(_session, [user_id])
	friend_list = friend_list.filter(func(f): return f.get("id", "") != user_id)

func get_online_friends() -> Array:
	return online_friends.values()

# ── Guilds / Clubs ─────────────────────────────────────────────────────────────
func create_guild(name: String, description: String = "", max_members: int = 50) -> Dictionary:
	if not _nakama_client or not _session:
		return {}
	var result = await _nakama_client.create_group_async(
		_session, name, description, "", "", false, max_members
	)
	if result.is_exception():
		push_error("SocialManager: create_guild failed: %s" % result.get_exception().message)
		return {}
	var guild_dict := _group_to_dict(result)
	current_guild = guild_dict
	emit_signal("guild_created", guild_dict)
	return guild_dict

func join_guild(guild_id: String) -> bool:
	if not _nakama_client or not _session:
		return false
	var result = await _nakama_client.join_group_async(_session, guild_id)
	if result.is_exception():
		push_error("SocialManager: join_guild failed: %s" % result.get_exception().message)
		return false
	current_guild = {"id": guild_id}
	emit_signal("guild_joined", guild_id, "")
	return true

func leave_guild(guild_id: String) -> void:
	if not _nakama_client or not _session:
		return
	await _nakama_client.leave_group_async(_session, guild_id)
	current_guild = {}
	emit_signal("guild_left", guild_id)

func invite_to_guild(guild_id: String, user_id: String) -> void:
	if not _nakama_client or not _session:
		return
	await _nakama_client.add_group_users_async(_session, guild_id, [user_id])

func search_guilds(query: String) -> Array:
	if not _nakama_client or not _session:
		return []
	var result = await _nakama_client.list_groups_async(_session, query, 20, "")
	if result.is_exception():
		return []
	var out: Array = []
	for group in result.groups:
		out.append(_group_to_dict(group))
	return out

# ── Private ────────────────────────────────────────────────────────────────────
func _connect_socket() -> void:
	if not _nakama_client or not _session:
		return
	_socket = _nakama_client.create_socket()
	var result = await _socket.connect_async(_session)
	if result.is_exception():
		push_error("SocialManager: socket connect failed: %s" % result.get_exception().message)
		return
	_socket.received_channel_message.connect(_on_channel_message)
	_socket.received_status_presence.connect(_on_status_presence)
	_socket.received_notification.connect(_on_notification)
	# Follow own status
	await _socket.update_status_async("online")

func _load_friends() -> void:
	if not _nakama_client or not _session:
		return
	var result = await _nakama_client.list_friends_async(_session, 0, 100, "")
	if result.is_exception():
		return
	friend_list.clear()
	for friend_data in result.friends:
		friend_list.append({
			"id":       friend_data.user.id,
			"username": friend_data.user.username,
			"state":    friend_data.state,
		})

func _channel_id(channel: String) -> String:
	return "catsino_%s" % channel

func _group_to_dict(group) -> Dictionary:
	return {
		"id":          group.id,
		"name":        group.name,
		"description": group.description,
		"max_count":   group.max_count,
		"edge_count":  group.edge_count,
		"open":        group.open,
	}

func _on_channel_message(message) -> void:
	var channel: String = str(message.channel_id)
	var sender: String = str(message.sender_id)
	var content = message.content
	if not channel in chat_history:
		chat_history[channel] = []
	chat_history[channel].append({
		"sender":    sender,
		"content":   content,
		"timestamp": message.create_time,
	})
	emit_signal("chat_received", channel, sender, content, 0)

func _on_status_presence(presence) -> void:
	for join_data in presence.joins:
		online_friends[join_data.user_id] = join_data
		emit_signal("friend_online", join_data.user_id, join_data.username)
	for leave_data in presence.leaves:
		online_friends.erase(leave_data.user_id)
		emit_signal("friend_offline", leave_data.user_id)

func _on_notification(notification) -> void:
	match notification.code:
		1:  # Friend request
			emit_signal("friend_request_received", notification.sender_id, "")
		2:  # Guild invite
			emit_signal("invite_received", notification.subject, notification.content, notification.sender_id)
