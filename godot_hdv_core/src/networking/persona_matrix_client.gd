extends Node
## Autoloaded as "PersonaMatrixClient". HTTP bridge from the Godot multiverse
## client to this repo's PersonaMatrix backend (/api/personamatrix/*), which
## is what gives ambient NPCs/companions their AI-driven persona behavior.
## Mirrors CATSINO.CASINO's godot/src/networking/http_client.gd convention —
## awaitable methods returning {ok, data, error, _status_code} — rather than
## NetworkManager.call_rpc's Callable style, since this is plain HTTP, not a
## Nakama RPC.
##
## This is a second, independent backend connection. It does not touch (and
## must never touch) CATSINO.CASINO's Nakama networking — that's a completely
## separate multiplayer backbone for a separate game.

## One-line edit between local dev and the deployed Vercel URL.
const BASE_URL: String = "http://localhost:3000/api/personamatrix"
const REQUEST_TIMEOUT: float = 10.0

## module is one of "dream", "hope", "no_one", "vision", "apex" per
## lib/personamatrix/types.ts. api_key is optional — only needed once a
## tenant row exists for billing; unauthenticated requests still work.
func request_persona(module: String, role: String, task: Dictionary, api_key: String = "") -> Dictionary:
	var headers := PackedStringArray(["Content-Type: application/json"])
	if not api_key.is_empty():
		headers.append("X-Api-Key: %s" % api_key)
	return await _request("POST", "/request", {"module": module, "role": role, "task": task}, headers)

## Lists known persona identities (for displaying Dream/Hope NPCs sourced
## from the Entity Roster instead of hardcoded names). module empty = all.
func list_personas(module: String = "") -> Dictionary:
	var path := "/personas"
	if not module.is_empty():
		path += "?module=%s" % module.uri_encode()
	return await _request("GET", path, {}, PackedStringArray())

## Running session/tenant spend, same idea as the Nakama wallet display.
func get_ledger(tenant_id: String = "") -> Dictionary:
	var path := "/ledger"
	if not tenant_id.is_empty():
		path += "?tenant_id=%s" % tenant_id.uri_encode()
	return await _request("GET", path, {}, PackedStringArray())

func _request(method: String, path: String, body: Dictionary, extra_headers: PackedStringArray) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = REQUEST_TIMEOUT
	add_child(http)

	var headers := extra_headers
	if method == "POST" and not headers.has("Content-Type: application/json"):
		headers.append("Content-Type: application/json")

	var body_str := JSON.stringify(body) if method == "POST" else ""
	var http_method := HTTPClient.METHOD_POST if method == "POST" else HTTPClient.METHOD_GET
	var err := http.request(BASE_URL + path, headers, http_method, body_str)
	if err != OK:
		http.queue_free()
		return {"ok": false, "data": {}, "error": "HTTPRequest failed to start: %d" % err, "_status_code": 0}

	var response: Array = await http.request_completed
	http.queue_free()

	var result: int = response[0]
	var status_code: int = response[1]
	var resp_body: PackedByteArray = response[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "data": {}, "error": "Network error result=%d" % result, "_status_code": 0}

	var json := JSON.new()
	if json.parse(resp_body.get_string_from_utf8()) != OK:
		return {"ok": false, "data": {}, "error": "JSON parse error: %s" % json.get_error_message(), "_status_code": status_code}

	var parsed = json.get_data()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "data": {}, "error": "Unexpected response type", "_status_code": status_code}

	if status_code < 200 or status_code >= 300:
		return {"ok": false, "data": parsed, "error": parsed.get("error", "HTTP %d" % status_code), "_status_code": status_code}

	return {"ok": true, "data": parsed, "error": "", "_status_code": status_code}
