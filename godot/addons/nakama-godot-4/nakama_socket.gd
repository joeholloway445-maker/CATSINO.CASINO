class_name NakamaSocket
extends Node
## Real-time client over Nakama's WebSocket protocol — JSON envelopes per
## the documented rtapi wire format (one populated field per message:
## match_join / match_data_send / channel_join / channel_message_send /
## status_update outbound; match_data / channel_message /
## status_presence_event / notifications / error inbound).
##
## Extends Node (not RefCounted) purely so _process can drive the poll
## loop — connect_async() self-adds to the scene tree root.

signal connected()
signal closed()
signal received_error(error)
signal received_notification(notification)
signal received_channel_message(message)
signal received_channel_presence_event(event)
signal received_match_presence_event(event)
signal received_status_presence(event)
signal received_match_state(state)

enum ChannelType { ROOM = 1, DIRECT_MESSAGE = 2, GROUP = 3 }

var _peer: WebSocketPeer
var _host: String
var _port: int
var _ssl: bool
var _connected := false
var _cid_counter := 0
var _pending: Dictionary = {} # cid -> "__pending__" | result

func _setup(host: String, port: int, ssl: bool) -> void:
	_host = host
	_port = port
	_ssl = ssl

func _process(_delta: float) -> void:
	if _peer == null:
		return
	_peer.poll()
	var state := _peer.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while _peer.get_available_packet_count() > 0:
			_handle_message(_peer.get_packet().get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSED and _connected:
		_connected = false
		closed.emit()

func is_connected_to_host() -> bool:
	return _connected

func connect_async(session: NakamaSession, timeout: float = 8.0) -> Variant:
	if not is_inside_tree():
		Engine.get_main_loop().root.add_child(self)
	_peer = WebSocketPeer.new()
	var scheme := "wss" if _ssl else "ws"
	var url := "%s://%s:%d/ws?token=%s&lang=en&status=true" % [scheme, _host, _port, session.token.uri_encode()]
	var err := _peer.connect_to_url(url)
	if err != OK:
		return NakamaException.new(0, "WebSocket connect_to_url failed (%d)" % err)
	var waited := 0.0
	while waited < timeout:
		_peer.poll()
		var state := _peer.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			_connected = true
			connected.emit()
			return NakamaModels.Ack.new()
		if state == WebSocketPeer.STATE_CLOSED:
			return NakamaException.new(0, "WebSocket closed during handshake")
		await get_tree().process_frame
		waited += get_process_delta_time()
	return NakamaException.new(0, "WebSocket connect timed out")

func disconnect_async() -> void:
	if _peer:
		_peer.close()
	_connected = false
	closed.emit()

func _next_cid() -> String:
	_cid_counter += 1
	return str(_cid_counter)

## Sends an envelope with a correlation id and awaits the matching reply
## (or a timeout). Used for requests the caller checks is_exception() on.
func _send_and_wait(envelope: Dictionary, timeout: float = 8.0) -> Variant:
	if not is_connected_to_host():
		return NakamaException.new(0, "Socket not connected")
	var cid := _next_cid()
	envelope["cid"] = cid
	_pending[cid] = "__pending__"
	_peer.send_text(JSON.stringify(envelope))
	var waited := 0.0
	while _pending.get(cid) == "__pending__" and waited < timeout:
		await get_tree().process_frame
		waited += get_process_delta_time()
	var res = _pending.get(cid, null)
	_pending.erase(cid)
	if res == null or res == "__pending__":
		return NakamaException.new(0, "Realtime request timed out")
	return res

func _handle_message(text: String) -> void:
	var msg = JSON.parse_string(text)
	if not msg is Dictionary:
		return
	if msg.has("cid") and _pending.has(str(msg.cid)):
		var cid := str(msg.cid)
		if msg.has("error"):
			var e: Dictionary = msg.error
			_pending[cid] = NakamaException.new(int(e.get("code", 0)), str(e.get("message", "realtime error")))
		elif msg.has("match"):
			_pending[cid] = {"match_id": str(msg.match.get("match_id", ""))}
		else:
			_pending[cid] = NakamaModels.Ack.new()
		return
	if msg.has("match_data"):
		var md: Dictionary = msg.match_data
		received_match_state.emit({
			"match_id": str(md.get("match_id", "")),
			"op_code": int(md.get("op_code", 0)),
			"data": _decode_data(str(md.get("data", ""))),
		})
	elif msg.has("channel_message"):
		received_channel_message.emit(NakamaModels.ChannelMessage.new(msg.channel_message))
	elif msg.has("status_presence_event"):
		received_status_presence.emit(NakamaModels.StatusPresenceEvent.new(msg.status_presence_event))
	elif msg.has("channel_presence_event"):
		received_channel_presence_event.emit(NakamaModels.StatusPresenceEvent.new(msg.channel_presence_event))
	elif msg.has("match_presence_event"):
		received_match_presence_event.emit(NakamaModels.StatusPresenceEvent.new(msg.match_presence_event))
	elif msg.has("notifications"):
		for n in msg.notifications.get("notifications", []):
			received_notification.emit(NakamaModels.Notification.new(n))
	elif msg.has("error"):
		var e: Dictionary = msg.error
		received_error.emit(NakamaException.new(int(e.get("code", 0)), str(e.get("message", ""))))

func _decode_data(raw: String) -> String:
	# match_data.data is base64 bytes on the wire; fall back to raw if a
	# server/version sends it unencoded.
	var bytes := Marshalls.base64_to_raw(raw)
	if bytes.is_empty() and raw != "":
		return raw
	var s := bytes.get_string_from_utf8()
	return s if s != "" else raw

# ---------------------------------------------------------------- outbound

func join_match_async(match_id: String) -> Variant:
	return await _send_and_wait({"match_join": {"match_id": match_id}})

func send_match_state_async(match_id: String, op_code: int, data: String) -> void:
	if not is_connected_to_host():
		return
	_peer.send_text(JSON.stringify({
		"match_data_send": {
			"match_id": match_id, "op_code": op_code,
			"data": Marshalls.utf8_to_base64(data),
		},
	}))

func join_chat_async(channel_id: String, type: int, persistence: bool, hidden: bool) -> Variant:
	return await _send_and_wait({
		"channel_join": {"target": channel_id, "type": type, "persistence": persistence, "hidden": hidden},
	})

func write_chat_message_async(channel_id: String, message: String) -> Variant:
	return await _send_and_wait({
		"channel_message_send": {"channel_id": channel_id, "content": JSON.stringify({"text": message})},
	})

func update_status_async(status: String) -> void:
	if not is_connected_to_host():
		return
	_peer.send_text(JSON.stringify({"status_update": {"status": status}}))
	await get_tree().process_frame
