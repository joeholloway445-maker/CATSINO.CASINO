class_name NakamaSession
extends RefCounted
## Nakama sessions are JWTs. We decode the payload segment client-side
## (no signature verification needed/possible without the server secret —
## this mirrors how every official Nakama client SDK reads uid/usn/exp)
## to populate user_id/username/expire_time without a round trip.

var token: String = ""
var refresh_token: String = ""
var user_id: String = ""
var username: String = ""
var expire_time: int = 0
var refresh_expire_time: int = 0
var created: bool = false

static func from_token(token: String, refresh_token: String = "", created: bool = false) -> NakamaSession:
	var s := NakamaSession.new()
	s.token = token
	s.refresh_token = refresh_token
	s.created = created
	var payload := _decode_jwt_payload(token)
	s.user_id = str(payload.get("uid", ""))
	s.username = str(payload.get("usn", ""))
	s.expire_time = int(payload.get("exp", 0))
	if refresh_token != "":
		s.refresh_expire_time = int(_decode_jwt_payload(refresh_token).get("exp", 0))
	return s

static func _decode_jwt_payload(jwt: String) -> Dictionary:
	var parts := jwt.split(".")
	if parts.size() < 2:
		return {}
	var b64 := parts[1].replace("-", "+").replace("_", "/")
	while b64.length() % 4 != 0:
		b64 += "="
	var bytes := Marshalls.base64_to_raw(b64)
	if bytes.is_empty():
		return {}
	var parsed = JSON.parse_string(bytes.get_string_from_utf8())
	return parsed if parsed is Dictionary else {}

func is_expired(offset_sec: int = 0) -> bool:
	if token.is_empty():
		return true
	return Time.get_unix_time_from_system() + offset_sec >= expire_time

func is_refresh_expired(offset_sec: int = 0) -> bool:
	if refresh_token.is_empty():
		return true
	return Time.get_unix_time_from_system() + offset_sec >= refresh_expire_time

func is_exception() -> bool:
	return false
