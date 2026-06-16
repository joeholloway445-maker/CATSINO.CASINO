extends Node
class_name NetworkManager
# Nakama client wrapper — all RPC calls go through here

signal connected()
signal disconnected()
signal rpc_error(code: int, message: String)

var _client: NakamaClient
var _session: NakamaSession
var _socket: NakamaSocket
var _is_connected: bool = false

const NAKAMA_HOST = "127.0.0.1"
const NAKAMA_PORT = 7350
const NAKAMA_KEY = "defaultkey"
const NAKAMA_SSL = false

func _ready() -> void:
	_client = Nakama.create_client(NAKAMA_KEY, NAKAMA_HOST, NAKAMA_PORT, "http")

func authenticate(email: String, password: String) -> bool:
	var result = await _client.authenticate_email_async(email, password, true)
	if result.is_exception():
		push_error("Nakama auth failed: " + result.get_exception().message)
		return false
	_session = result
	await _open_socket()
	return true

func _open_socket() -> void:
	_socket = Nakama.create_socket_from(_client)
	var result = await _socket.connect_async(_session)
	if result.is_exception():
		push_error("Nakama socket failed: " + result.get_exception().message)
		return
	_is_connected = true
	connected.emit()
	_socket.closed.connect(_on_socket_closed)

func _on_socket_closed() -> void:
	_is_connected = false
	disconnected.emit()

func call_rpc(rpc_id: String, payload: String, callback: Callable) -> void:
	if not _session or _session.is_expired():
		rpc_error.emit(401, "Not authenticated")
		return

	var result = await _client.rpc_async(_session, rpc_id, payload)
	if result.is_exception():
		var ex = result.get_exception()
		rpc_error.emit(ex.status_code, ex.message)
		callback.call({"success": false, "error": ex.message})
		return

	var parsed = JSON.parse_string(result.payload)
	if parsed == null:
		callback.call({"success": false, "error": "Invalid JSON response"})
		return

	callback.call(parsed)

func is_connected_to_server() -> bool:
	return _is_connected

func get_session() -> NakamaSession:
	return _session
