class_name NakamaClient
extends RefCounted

var _scheme: String
var _host: String
var _port: int
var _server_key: String
var _timeout: float

func _init(scheme: String = "http", host: String = "127.0.0.1", port: int = 7350, server_key: String = "defaultkey", timeout: float = 10.0) -> void:
	_scheme = scheme
	_host = host
	_port = port
	_server_key = server_key
	_timeout = timeout

func _base_url() -> String:
	return "%s://%s:%d" % [_scheme, _host, _port]

func authenticate_email_async(email: String, password: String, create: bool = false, username: String = "") -> NakamaSession:
	var http := HTTPRequest.new()
	Engine.get_main_loop().root.add_child(http)
	var body := JSON.stringify({"email": email, "password": password, "username": username})
	var url := _base_url() + "/v2/account/authenticate/email?create=%s" % ("true" if create else "false")
	var headers := ["Content-Type: application/json", "Authorization: Basic " + Marshalls.utf8_to_base64(_server_key + ":")]
	http.request(url, headers, HTTPClient.METHOD_POST, body)
	var result: Array = await http.request_completed
	http.queue_free()
	var code: int = result[1]
	if code != 200:
		push_error("Nakama auth error: HTTP %d" % code)
		return NakamaSession.new("", "", "", 0)
	var data: Dictionary = JSON.parse_string(result[3].get_string_from_utf8())
	return NakamaSession.new(data.get("token", ""), data.get("user_id", ""), data.get("username", ""))

func authenticate_device_async(device_id: String, create: bool = true, username: String = "") -> NakamaSession:
	var http := HTTPRequest.new()
	Engine.get_main_loop().root.add_child(http)
	var body := JSON.stringify({"id": device_id, "username": username})
	var url := _base_url() + "/v2/account/authenticate/device?create=%s" % ("true" if create else "false")
	var headers := ["Content-Type: application/json", "Authorization: Basic " + Marshalls.utf8_to_base64(_server_key + ":")]
	http.request(url, headers, HTTPClient.METHOD_POST, body)
	var result: Array = await http.request_completed
	http.queue_free()
	var code: int = result[1]
	if code != 200:
		push_error("Nakama device auth error: HTTP %d" % code)
		return NakamaSession.new("", "", "", 0)
	var data: Dictionary = JSON.parse_string(result[3].get_string_from_utf8())
	return NakamaSession.new(data.get("token", ""), data.get("user_id", ""), data.get("username", ""))

func rpc_async(session: NakamaSession, rpc_id: String, payload: String) -> Dictionary:
	var http := HTTPRequest.new()
	Engine.get_main_loop().root.add_child(http)
	var url := _base_url() + "/v2/rpc/%s" % rpc_id
	var headers := ["Content-Type: application/json", "Authorization: Bearer " + session.token]
	http.request(url, headers, HTTPClient.METHOD_POST, payload)
	var result: Array = await http.request_completed
	http.queue_free()
	var code: int = result[1]
	if code != 200:
		push_error("Nakama RPC error [%s]: HTTP %d" % [rpc_id, code])
		return {"error": "HTTP %d" % code}
	var raw: String = result[3].get_string_from_utf8()
	var wrapper: Dictionary = JSON.parse_string(raw)
	if wrapper.has("payload"):
		var inner = JSON.parse_string(wrapper["payload"])
		return inner if inner is Dictionary else {"raw": inner}
	return wrapper

func create_socket() -> NakamaSocket:
	return NakamaSocket.new()

func list_leaderboard_records_async(session: NakamaSession, leaderboard_id: String, limit: int = 20) -> Array:
	var http := HTTPRequest.new()
	Engine.get_main_loop().root.add_child(http)
	var url := _base_url() + "/v2/leaderboard/%s?limit=%d" % [leaderboard_id, limit]
	var headers := ["Authorization: Bearer " + session.token]
	http.request(url, headers, HTTPClient.METHOD_GET)
	var result: Array = await http.request_completed
	http.queue_free()
	if result[1] != 200:
		return []
	var data: Dictionary = JSON.parse_string(result[3].get_string_from_utf8())
	return data.get("records", [])

func write_leaderboard_record_async(session: NakamaSession, leaderboard_id: String, score: int) -> void:
	var http := HTTPRequest.new()
	Engine.get_main_loop().root.add_child(http)
	var url := _base_url() + "/v2/leaderboard/%s" % leaderboard_id
	var headers := ["Content-Type: application/json", "Authorization: Bearer " + session.token]
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify({"score": score}))
	var result: Array = await http.request_completed
	http.queue_free()
