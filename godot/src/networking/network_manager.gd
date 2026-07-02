extends Node
class_name NetworkManager
# Nakama RPC dispatcher — delegates to AccountManager's authenticated client
# and session rather than holding its own. AccountManager owns the single
# Nakama client/session for this game (created in _init_nakama_client(),
# populated on auth_device()/auth_email()/auth_custom()); NetworkManager used
# to authenticate a second, independent client/session that nothing ever
# populated, so every call_rpc() caller (slots, racing, combat, guilds,
# leaderboards, shop, tournaments, gacha, quests) silently failed with
# 401 "Not authenticated" even after a successful login.

signal connected()
signal disconnected()
signal rpc_error(code: int, message: String)

func _get_client():
	return AccountManager.get_nakama_client() if AccountManager else null

func _get_session():
	return AccountManager.get_nakama_session() if AccountManager else null

func call_rpc(rpc_id: String, payload: Variant, callback: Callable) -> void:
	var payload_str: String = JSON.stringify(payload) if payload is Dictionary or payload is Array else str(payload)
	var client = _get_client()
	var session = _get_session()
	if not client or not session or session.is_expired():
		rpc_error.emit(401, "Not authenticated")
		callback.call({"success": false, "error": "Not authenticated"})
		return

	var result = await client.rpc_async(session, rpc_id, payload_str)
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
	return AccountManager.is_authenticated if AccountManager else false

func get_session():
	return _get_session()
