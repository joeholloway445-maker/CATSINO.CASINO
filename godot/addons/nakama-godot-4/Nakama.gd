class_name NakamaClient
extends RefCounted
## REST client against a real Nakama server's public /v2 API. Original
## implementation (see README.md for confidence levels per endpoint) —
## sized to the exact call surface AccountManager/SocialManager/
## ChatManager already code against.

var _scheme: String
var _host: String
var _port: int
var _server_key: String
var _timeout: float

static func create_client(server_key: String, host: String = "127.0.0.1",
		port: int = 7350, scheme: String = "http", timeout: float = 10.0) -> NakamaClient:
	var c := NakamaClient.new()
	c._scheme = scheme
	c._host = host
	c._port = port
	c._server_key = server_key
	c._timeout = timeout
	return c

func _base_url() -> String:
	return "%s://%s:%d" % [_scheme, _host, _port]

func _basic_auth() -> String:
	return "Authorization: Basic " + Marshalls.utf8_to_base64(_server_key + ":")

func _bearer_auth(session: NakamaSession) -> String:
	return "Authorization: Bearer " + session.token

## Generic request. Returns either the parsed JSON body (Dictionary) on
## 2xx, or {"_error": true, "status": code, "message": msg} otherwise.
func _request(method: int, path: String, headers: Array, body: String = "") -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = _timeout
	Engine.get_main_loop().root.add_child(http)
	var err := http.request(_base_url() + path, headers, method, body)
	if err != OK:
		http.queue_free()
		return {"_error": true, "status": 0, "message": "Request failed to start (%d)" % err}
	var result: Array = await http.request_completed
	http.queue_free()
	var code: int = result[1]
	var text: String = (result[3] as PackedByteArray).get_string_from_utf8()
	if code < 200 or code >= 300:
		var msg := text
		var parsed = JSON.parse_string(text)
		if parsed is Dictionary and parsed.has("message"):
			msg = str(parsed.message)
		return {"_error": true, "status": code, "message": msg if msg != "" else "HTTP %d" % code}
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {"_raw": parsed}

func _session_from(resp: Dictionary) -> Variant:
	if resp.get("_error", false):
		return NakamaException.new(resp.status, resp.message)
	return NakamaSession.from_token(str(resp.get("token", "")), str(resp.get("refresh_token", "")), bool(resp.get("created", false)))

# ---------------------------------------------------------------- auth

func authenticate_device_async(device_id: String, create: bool = true, username: String = "") -> Variant:
	var q := "?create=%s" % str(create)
	if username != "":
		q += "&username=" + username.uri_encode()
	var resp := await _request(HTTPClient.METHOD_POST, "/v2/account/authenticate/device" + q,
		["Content-Type: application/json", _basic_auth()], JSON.stringify({"id": device_id}))
	return _session_from(resp)

func authenticate_email_async(email: String, password: String, create: bool = false, username: String = "") -> Variant:
	var q := "?create=%s" % str(create)
	if username != "":
		q += "&username=" + username.uri_encode()
	var resp := await _request(HTTPClient.METHOD_POST, "/v2/account/authenticate/email" + q,
		["Content-Type: application/json", _basic_auth()], JSON.stringify({"email": email, "password": password}))
	return _session_from(resp)

func authenticate_custom_async(id: String, create: bool = true, username: String = "") -> Variant:
	var q := "?create=%s" % str(create)
	if username != "":
		q += "&username=" + username.uri_encode()
	var resp := await _request(HTTPClient.METHOD_POST, "/v2/account/authenticate/custom" + q,
		["Content-Type: application/json", _basic_auth()], JSON.stringify({"id": id}))
	return _session_from(resp)

func session_refresh_async(session: NakamaSession) -> Variant:
	var resp := await _request(HTTPClient.METHOD_POST, "/v2/account/session/refresh",
		["Content-Type: application/json", _basic_auth()], JSON.stringify({"refresh_token": session.refresh_token}))
	return _session_from(resp)

## Synchronous — just decodes the JWTs, matches the real SDK's behavior
## (a cached token doesn't need a round trip to reconstruct a session).
func restore_session(token: String, refresh_token: String = "") -> NakamaSession:
	return NakamaSession.from_token(token, refresh_token)

# ---------------------------------------------------------------- account

func get_account_async(session: NakamaSession) -> Variant:
	var resp := await _request(HTTPClient.METHOD_GET, "/v2/account", [_bearer_auth(session)])
	if resp.get("_error", false):
		return NakamaException.new(resp.status, resp.message)
	return NakamaModels.Account.new(resp)

func update_account_async(session: NakamaSession, username = null, display_name = null,
		avatar_url = null, lang_tag = null, location = null) -> Variant:
	var body := {}
	if username != null: body["username"] = username
	if display_name != null: body["display_name"] = display_name
	if avatar_url != null: body["avatar_url"] = avatar_url
	if lang_tag != null: body["lang_tag"] = lang_tag
	if location != null: body["location"] = location
	var resp := await _request(HTTPClient.METHOD_PUT, "/v2/account",
		["Content-Type: application/json", _bearer_auth(session)], JSON.stringify(body))
	if resp.get("_error", false):
		return NakamaException.new(resp.status, resp.message)
	return NakamaModels.Ack.new()

# ---------------------------------------------------------------- rpc

func rpc_async(session: NakamaSession, rpc_id: String, payload: String) -> Variant:
	var resp := await _request(HTTPClient.METHOD_POST, "/v2/rpc/%s" % rpc_id.uri_encode(),
		[_bearer_auth(session), "Content-Type: application/json"], payload)
	if resp.get("_error", false):
		return NakamaException.new(resp.status, resp.message)
	return NakamaModels.Rpc.new(resp, rpc_id)

# ---------------------------------------------------------------- storage

func write_storage_objects_async(session: NakamaSession, objects: Array) -> Variant:
	var wire: Array = []
	for o in objects:
		wire.append(o.to_dict())
	var resp := await _request(HTTPClient.METHOD_PUT, "/v2/storage",
		["Content-Type: application/json", _bearer_auth(session)], JSON.stringify({"objects": wire}))
	if resp.get("_error", false):
		return NakamaException.new(resp.status, resp.message)
	return NakamaModels.Ack.new()

func read_storage_objects_async(session: NakamaSession, ids: Array) -> Variant:
	var wire: Array = []
	for i in ids:
		wire.append(i.to_dict())
	var resp := await _request(HTTPClient.METHOD_POST, "/v2/storage/get",
		["Content-Type: application/json", _bearer_auth(session)], JSON.stringify({"object_ids": wire}))
	if resp.get("_error", false):
		return NakamaException.new(resp.status, resp.message)
	return NakamaModels.StorageObjectList.new(resp)

# ---------------------------------------------------------------- friends

func list_friends_async(session: NakamaSession, state: int = -1, limit: int = 100, cursor: String = "") -> Variant:
	var q := "?limit=%d" % limit
	if state >= 0: q += "&state=%d" % state
	if cursor != "": q += "&cursor=" + cursor.uri_encode()
	var resp := await _request(HTTPClient.METHOD_GET, "/v2/friend" + q, [_bearer_auth(session)])
	if resp.get("_error", false):
		return NakamaException.new(resp.status, resp.message)
	return NakamaModels.FriendList.new(resp)

func add_friends_async(session: NakamaSession, ids: Array) -> Variant:
	var q := "?" + "&".join(ids.map(func(i): return "ids=" + str(i).uri_encode()))
	var resp := await _request(HTTPClient.METHOD_POST, "/v2/friend" + q, [_bearer_auth(session)])
	if resp.get("_error", false):
		return NakamaException.new(resp.status, resp.message)
	return NakamaModels.Ack.new()

func delete_friends_async(session: NakamaSession, ids: Array) -> Variant:
	var q := "?" + "&".join(ids.map(func(i): return "ids=" + str(i).uri_encode()))
	var resp := await _request(HTTPClient.METHOD_DELETE, "/v2/friend" + q, [_bearer_auth(session)])
	if resp.get("_error", false):
		return NakamaException.new(resp.status, resp.message)
	return NakamaModels.Ack.new()

# ---------------------------------------------------------------- groups

func create_group_async(session: NakamaSession, name: String, description: String = "",
		avatar_url: String = "", lang_tag: String = "", open: bool = true, max_count: int = 100) -> Variant:
	var body := {
		"name": name, "description": description, "avatar_url": avatar_url,
		"lang_tag": lang_tag, "open": open, "max_count": max_count,
	}
	var resp := await _request(HTTPClient.METHOD_POST, "/v2/group",
		["Content-Type: application/json", _bearer_auth(session)], JSON.stringify(body))
	if resp.get("_error", false):
		return NakamaException.new(resp.status, resp.message)
	return NakamaModels.Group.new(resp)

func join_group_async(session: NakamaSession, group_id: String) -> Variant:
	var resp := await _request(HTTPClient.METHOD_POST, "/v2/group/%s/join" % group_id.uri_encode(), [_bearer_auth(session)])
	if resp.get("_error", false):
		return NakamaException.new(resp.status, resp.message)
	return NakamaModels.Ack.new()

func leave_group_async(session: NakamaSession, group_id: String) -> Variant:
	var resp := await _request(HTTPClient.METHOD_POST, "/v2/group/%s/leave" % group_id.uri_encode(), [_bearer_auth(session)])
	if resp.get("_error", false):
		return NakamaException.new(resp.status, resp.message)
	return NakamaModels.Ack.new()

func add_group_users_async(session: NakamaSession, group_id: String, ids: Array) -> Variant:
	var q := "?" + "&".join(ids.map(func(i): return "user_ids=" + str(i).uri_encode()))
	var resp := await _request(HTTPClient.METHOD_POST, "/v2/group/%s/add" % group_id.uri_encode() + q, [_bearer_auth(session)])
	if resp.get("_error", false):
		return NakamaException.new(resp.status, resp.message)
	return NakamaModels.Ack.new()

func list_groups_async(session: NakamaSession, query: String = "", limit: int = 20, cursor: String = "") -> Variant:
	var q := "?limit=%d" % limit
	if query != "": q += "&name=" + query.uri_encode()
	if cursor != "": q += "&cursor=" + cursor.uri_encode()
	var resp := await _request(HTTPClient.METHOD_GET, "/v2/group" + q, [_bearer_auth(session)])
	if resp.get("_error", false):
		return NakamaException.new(resp.status, resp.message)
	return NakamaModels.GroupList.new(resp)

# ---------------------------------------------------------------- leaderboards

func list_leaderboard_records_async(session: NakamaSession, leaderboard_id: String, limit: int = 20) -> Array:
	var resp := await _request(HTTPClient.METHOD_GET, "/v2/leaderboard/%s?limit=%d" % [leaderboard_id.uri_encode(), limit], [_bearer_auth(session)])
	if resp.get("_error", false):
		return []
	return resp.get("records", [])

func write_leaderboard_record_async(session: NakamaSession, leaderboard_id: String, score: int) -> void:
	await _request(HTTPClient.METHOD_POST, "/v2/leaderboard/%s" % leaderboard_id.uri_encode(),
		["Content-Type: application/json", _bearer_auth(session)], JSON.stringify({"score": score}))

# ---------------------------------------------------------------- realtime

func create_socket() -> NakamaSocket:
	var s := NakamaSocket.new()
	s._setup(_host, _port, _scheme == "https")
	return s
