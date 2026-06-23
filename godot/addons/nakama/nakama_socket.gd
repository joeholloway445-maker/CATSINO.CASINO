class_name NakamaSocket
extends RefCounted

signal connected()
signal closed()
signal received_error(error)
signal received_notification(notification)
signal received_channel_message(message)
signal received_match_state(state)

var _connected: bool = false

func connect_async(session: NakamaSession) -> void:
	# Real impl would open WebSocket to Nakama; stub emits connected
	_connected = true
	connected.emit()

func disconnect_async() -> void:
	_connected = false
	closed.emit()

func is_connected_to_host() -> bool:
	return _connected

func send_match_state_async(match_id: String, op_code: int, data: String) -> void:
	pass

func join_match_async(match_id: String) -> Dictionary:
	return {}
