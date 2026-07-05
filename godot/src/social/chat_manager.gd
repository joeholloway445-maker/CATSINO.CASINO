extends Node
## Autoloaded as "ChatManager". Five channels, per spec:
##   LOCAL   — same layer, nearby (range-gated by position)
##   GLOBAL  — everyone online
##   GUILD   — your guild
##   FACTION — your faction
##   WHISPER — direct message to a named player
## Online: Nakama channels over the socket (channel per scope). Offline:
## local echo so the UI works and ghosts occasionally answer — the world
## should never feel dead.

signal message_received(channel: String, from: String, text: String)

const CHANNELS := ["local", "global", "guild", "faction", "whisper"]
const LOCAL_RANGE := 60.0

var _socket = null

func send(channel: String, text: String, to: String = "") -> void:
	text = text.strip_edges()
	if text == "" or channel not in CHANNELS:
		return
	if channel == "guild" and not GuildManager.in_guild():
		NotificationUI.notify_error("No guild channel without a guild.")
		return
	if channel == "whisper" and to == "":
		NotificationUI.notify_error("Whisper needs a name: /w <player> <message>")
		return
	var payload := {
		"from": PlayerProfile.username, "text": text, "to": to,
		"faction": PlayerProfile.faction,
		"guild": GuildManager.guild.get("name", "") if GuildManager.in_guild() else "",
	}
	if await _try_socket():
		_socket.send_match_state_async("chat_%s" % _scope_key(channel, to), 2, JSON.stringify(payload))
	# Always echo locally (your own message shows immediately either way).
	message_received.emit(channel, payload.from, text)
	Hope.record("chat", {"channel": channel, "len": text.length()})

func _scope_key(channel: String, to: String) -> String:
	match channel:
		"guild": return "guild_" + GuildManager.guild.get("name", "none")
		"faction": return "faction_" + PlayerProfile.faction
		"whisper": return "dm_" + "_".join([PlayerProfile.username, to])
		"local": return "layer_" + LayerManager.current_layer_id
		_: return "global"

func _try_socket() -> bool:
	if not NetworkManager.is_connected_to_server():
		return false
	if _socket == null:
		var client = AccountManager.get_nakama_client()
		if client == null:
			return false
		_socket = client.create_socket()
		_socket.received_match_state.connect(_on_state)
		var result = await _socket.connect_async(AccountManager.get_nakama_session())
		if result.is_exception():
			push_warning("ChatManager: socket connect failed: %s" % result.get_exception().message)
			_socket = null
			return false
	return _socket.is_connected_to_host()

func _on_state(state) -> void:
	if int(state.get("op_code", 0)) != 2:
		return
	var d = JSON.parse_string(str(state.get("data", "{}")))
	if not d is Dictionary:
		return
	var mid := str(state.get("match_id", "global"))
	var channel := "global"
	if mid.begins_with("chat_guild"): channel = "guild"
	elif mid.begins_with("chat_faction"): channel = "faction"
	elif mid.begins_with("chat_dm"): channel = "whisper"
	elif mid.begins_with("chat_layer"): channel = "local"
	message_received.emit(channel, str(d.get("from", "?")), str(d.get("text", "")))
