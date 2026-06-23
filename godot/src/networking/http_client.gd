extends Node

# CasinoHTTPClient — autoload singleton
# Makes authenticated HTTP requests to the CATSINO.CASINO Next.js API.
# Add to Project > AutoLoad as "CasinoHTTPClient"

class_name CasinoHTTPClient

# ─── Configuration ────────────────────────────────────────────────────────────
const BASE_URL: String = "https://catsino-casino.vercel.app"
const REQUEST_TIMEOUT: float = 10.0
const RETRY_ON_5XX: bool = true

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	pass  # HTTPRequest nodes are created per-request and freed after use

# ─── Public API ───────────────────────────────────────────────────────────────
## Generic POST — awaitable, returns {ok, data, error}
func post_json(endpoint: String, body: Dictionary) -> Dictionary:
	return await _request_with_retry("POST", endpoint, body)

## GET request — awaitable, returns {ok, data, error}
func get_json(endpoint: String, params: Dictionary = {}) -> Dictionary:
	var url := BASE_URL + endpoint
	if not params.is_empty():
		url += "?" + _encode_query(params)
	return await _request_with_retry("GET", url, {}, true)

# ─── Domain-specific helpers ─────────────────────────────────────────────────
func spin_slots(bet: int) -> Dictionary:
	return await post_json("/api/games/slots/spin", {"bet": bet})

func spin_wheel(bet: int) -> Dictionary:
	return await post_json("/api/games/wheel/spin", {"bet": bet})

func claim_daily_bonus() -> Dictionary:
	return await post_json("/api/economy/daily-bonus", {})

func get_leaderboard(district: String = "paw_vegas", limit: int = 50) -> Dictionary:
	return await get_json("/api/leaderboard", {"district": district, "limit": limit})

func get_active_events() -> Dictionary:
	return await get_json("/api/liveops/events")

# ─── Internal request logic ───────────────────────────────────────────────────
func _request_with_retry(
	method: String,
	endpoint: String,
	body: Dictionary,
	is_full_url: bool = false
) -> Dictionary:
	var result := await _do_request(method, endpoint, body, is_full_url)

	# Retry once on 5xx
	if RETRY_ON_5XX and not result.get("ok", false):
		var code: int = result.get("_status_code", 0)
		if code >= 500 and code < 600:
			await get_tree().create_timer(1.5).timeout
			result = await _do_request(method, endpoint, body, is_full_url)

	return result

func _do_request(
	method: String,
	endpoint: String,
	body: Dictionary,
	is_full_url: bool = false
) -> Dictionary:
	var url: String = endpoint if is_full_url else (BASE_URL + endpoint)
	var headers: PackedStringArray = _build_headers(body.is_empty() and method == "GET")
	var body_bytes: PackedByteArray = PackedByteArray()
	if not body.is_empty():
		body_bytes = JSON.stringify(body).to_utf8_buffer()

	# Create a temporary HTTPRequest node
	var http := HTTPRequest.new()
	http.timeout = REQUEST_TIMEOUT
	add_child(http)

	var http_method: int = HTTPClient.METHOD_GET
	match method.to_upper():
		"POST":   http_method = HTTPClient.METHOD_POST
		"PUT":    http_method = HTTPClient.METHOD_PUT
		"DELETE": http_method = HTTPClient.METHOD_DELETE
		_:        http_method = HTTPClient.METHOD_GET

	var err: int = http.request_raw(url, headers, http_method, body_bytes)
	if err != OK:
		http.queue_free()
		return {ok = false, data = {}, error = "HTTPRequest failed to start: %d" % err, _status_code = 0}

	# Await signal
	var response: Array = await http.request_completed
	http.queue_free()

	# response = [result, response_code, headers, body]
	var _result: int       = response[0]
	var status_code: int   = response[1]
	var _resp_headers      = response[2]
	var resp_body: PackedByteArray = response[3]

	if _result != HTTPRequest.RESULT_SUCCESS:
		return {ok = false, data = {}, error = "Network error result=%d" % _result, _status_code = 0}

	# Parse JSON
	var json := JSON.new()
	var parse_err := json.parse(resp_body.get_string_from_utf8())
	if parse_err != OK:
		return {
			ok = false,
			data = {},
			error = "JSON parse error: %s" % json.get_error_message(),
			_status_code = status_code
		}

	var parsed = json.get_data()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {ok = false, data = {}, error = "Unexpected response type", _status_code = status_code}

	if status_code < 200 or status_code >= 300:
		return {
			ok = false,
			data = parsed,
			error = parsed.get("error", "HTTP %d" % status_code),
			_status_code = status_code
		}

	return {ok = true, data = parsed, error = "", _status_code = status_code}

# ─── Helpers ─────────────────────────────────────────────────────────────────
func _build_headers(is_get: bool = false) -> PackedStringArray:
	var headers: PackedStringArray = []
	if not is_get:
		headers.append("Content-Type: application/json")

	# Inject auth token from AccountManager if available
	var token := ""
	if AccountManager != null and AccountManager.has_method("get_session_token"):
		token = AccountManager.get_session_token()
	if not token.is_empty():
		headers.append("Authorization: Bearer %s" % token)

	headers.append("X-Client-Version: 1.0.0")
	headers.append("Accept: application/json")
	return headers

func _encode_query(params: Dictionary) -> String:
	var parts: Array[String] = []
	for key in params.keys():
		parts.append("%s=%s" % [key, str(params[key]).uri_encode()])
	return "&".join(parts)
