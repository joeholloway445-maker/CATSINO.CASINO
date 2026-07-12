extends Node

# ── Signals ────────────────────────────────────────────────────────────────────
signal authenticated(session: Dictionary)
signal session_expired()
signal profile_updated(profile: Dictionary)
signal auth_failed(error: String)
signal cloud_save_complete()
signal cloud_load_complete(data: Dictionary)

# ── Constants ──────────────────────────────────────────────────────────────────
const NAKAMA_HOST        := "127.0.0.1"
const NAKAMA_PORT        := 7350
const NAKAMA_SERVER_KEY  := "defaultkey"
const SESSION_CACHE_PATH := "user://session_cache.json"
const PROFILE_CACHE_PATH := "user://profile_cache.json"

# ── State ──────────────────────────────────────────────────────────────────────
var _client                          = null
var _session                         = null
var _socket                          = null
var player_profile: Dictionary = {
	"user_id":   "",
	"username":  "",
	"avatar_id": 0,
	"faction":   "Factionless",
	"level":     1,
	"xp":        0,
	"xp_to_next": 1000,
	"display_name": "",
	"created_at": "",
}
var is_authenticated: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_init_nakama_client()

func _init_nakama_client() -> void:
	# Dynamically load Nakama if available
	if ResourceLoader.exists("res://addons/nakama-godot-4/Nakama.gd"):
		var NakamaClient = load("res://addons/nakama-godot-4/Nakama.gd")
		_client = NakamaClient.create_client(
			NAKAMA_SERVER_KEY, NAKAMA_HOST, NAKAMA_PORT, "http"
		)
	else:
		push_warning("AccountManager: Nakama addon not found — running in offline mode")

func initialize() -> void:
	var cached := _load_session_cache()
	if cached:
		var restored := await _restore_session(cached)
		if restored:
			return
	# No valid session — caller should show login UI

# ── Auth Methods ───────────────────────────────────────────────────────────────
func auth_device(device_id: String = "") -> bool:
	if not _client:
		_mock_auth("device")
		return true
	if device_id.is_empty():
		device_id = OS.get_unique_id()
	var result = await _client.authenticate_device_async(device_id)
	return await _handle_auth_result(result)

func auth_email(email: String, password: String, create: bool = false) -> bool:
	if not _client:
		_mock_auth("email")
		return true
	var result = await _client.authenticate_email_async(email, password, create)
	var ok: bool = await _handle_auth_result(result)
	if not ok:
		# Local GOTY boot: if Nakama is unreachable, fall back offline so
		# email login still reaches the title screen during solo play.
		push_warning("AccountManager: email auth failed — offline fallback")
		_mock_auth("email_offline")
		return true
	return true

func auth_custom(token: String) -> bool:
	if not _client:
		_mock_auth("custom")
		return true
	var result = await _client.authenticate_custom_async(token)
	return await _handle_auth_result(result)

## Always-offline session for Play Offline / guest entry (no Nakama).
func auth_guest(display_name: String = "Wanderer") -> bool:
	_mock_auth("guest")
	if not display_name.is_empty():
		player_profile["username"] = display_name
		player_profile["display_name"] = display_name
	return true

func logout() -> void:
	is_authenticated = false
	_session = null
	_socket = null
	player_profile["user_id"] = ""
	if FileAccess.file_exists(SESSION_CACHE_PATH):
		DirAccess.remove_absolute(SESSION_CACHE_PATH)

# ── Session ────────────────────────────────────────────────────────────────────
func refresh_session() -> bool:
	if not _client or not _session:
		return false
	if _session.is_expired():
		var result = await _client.session_refresh_async(_session)
		if result.is_exception():
			emit_signal("session_expired")
			return false
		_session = result
		_save_session_cache()
	return true

func get_nakama_client():
	return _client

func get_nakama_session():
	return _session

# ── Profile ────────────────────────────────────────────────────────────────────
func fetch_profile() -> void:
	if not _client or not _session:
		return
	var result = await _client.get_account_async(_session)
	if result.is_exception():
		push_error("AccountManager: fetch_profile failed: %s" % result.get_exception().message)
		return
	var acct = result
	player_profile["user_id"]      = acct.user.id
	player_profile["username"]     = acct.user.username
	player_profile["display_name"] = acct.user.display_name
	player_profile["created_at"]   = acct.user.create_time
	# Custom fields from metadata
	if acct.user.metadata:
		var meta: Dictionary = JSON.parse_string(acct.user.metadata)
		player_profile["faction"]   = meta.get("faction", "Factionless")
		player_profile["level"]     = meta.get("level", 1)
		player_profile["xp"]        = meta.get("xp", 0)
		player_profile["avatar_id"] = meta.get("avatar_id", 0)
	_save_profile_cache()
	emit_signal("profile_updated", player_profile.duplicate())

func update_profile(changes: Dictionary) -> void:
	player_profile.merge(changes, true)
	if _client and _session:
		await _client.update_account_async(
			_session,
			changes.get("username", null),
			changes.get("display_name", null),
			null, null, null
		)
		# Push custom fields
		var meta_result = await _client.write_storage_objects_async(_session, [
			NakamaWriteStorageObject.new(
				"player_meta", "profile", 1, 2,
				JSON.stringify({
					"faction":   player_profile["faction"],
					"level":     player_profile["level"],
					"xp":        player_profile["xp"],
					"avatar_id": player_profile["avatar_id"],
				}), ""
			)
		])
	_save_profile_cache()
	emit_signal("profile_updated", player_profile.duplicate())

func add_xp(amount: int) -> void:
	player_profile["xp"] += amount
	while player_profile["xp"] >= player_profile["xp_to_next"]:
		player_profile["xp"]     -= player_profile["xp_to_next"]
		player_profile["level"]  += 1
		player_profile["xp_to_next"] = _xp_curve(player_profile["level"])
	await update_profile({})

# ── Cloud Save / Load ─────────────────────────────────────────────────────────
func cloud_save(collection: String, key: String, data: Dictionary) -> void:
	if not _client or not _session:
		return
	await _client.write_storage_objects_async(_session, [
		NakamaWriteStorageObject.new(collection, key, 1, 1, JSON.stringify(data), "")
	])
	emit_signal("cloud_save_complete")

func cloud_load(collection: String, key: String) -> Dictionary:
	if not _client or not _session:
		return {}
	var result = await _client.read_storage_objects_async(_session, [
		NakamaStorageObjectId.new(collection, key, _session.user_id)
	])
	if result.is_exception() or result.objects.is_empty():
		return {}
	var obj = result.objects[0]
	var parsed = JSON.parse_string(obj.value)
	emit_signal("cloud_load_complete", parsed if parsed is Dictionary else {})
	return parsed if parsed is Dictionary else {}

# ── Private ────────────────────────────────────────────────────────────────────
func _handle_auth_result(result) -> bool:
	if result.is_exception():
		var msg: String = result.get_exception().message
		push_error("AccountManager auth failed: %s" % msg)
		emit_signal("auth_failed", msg)
		return false
	_session = result
	is_authenticated = true
	_save_session_cache()
	var session_dict := {
		"user_id":    _session.user_id,
		"token":      _session.token,
		"expires_at": _session.expire_time,
	}
	emit_signal("authenticated", session_dict)
	await fetch_profile()
	if EconomyManager:
		EconomyManager.initialize(_client)
	return true

func _restore_session(cached: Dictionary) -> bool:
	if not _client:
		return false
	var token   : String = cached.get("token", "")
	var refresh : String = cached.get("refresh_token", "")
	if token.is_empty():
		return false
	_session = _client.restore_session(token, refresh)
	if _session.is_expired():
		var refreshed = await _client.session_refresh_async(_session)
		if refreshed.is_exception():
			emit_signal("session_expired")
			return false
		_session = refreshed
		_save_session_cache()
	is_authenticated = true
	var session_dict := {"user_id": _session.user_id, "token": _session.token}
	emit_signal("authenticated", session_dict)
	await fetch_profile()
	return true

func _mock_auth(method: String) -> void:
	is_authenticated = true
	player_profile["user_id"]  = "offline_player"
	player_profile["username"] = "CatPlayer"
	player_profile["faction"]  = "Factionless"
	emit_signal("authenticated", {"user_id": "offline_player", "method": method})

func _save_session_cache() -> void:
	if not _session:
		return
	var f := FileAccess.open(SESSION_CACHE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"token":         _session.token,
			"refresh_token": _session.refresh_token if _session.has_method("get") else "",
		}))

func _load_session_cache() -> Dictionary:
	if not FileAccess.file_exists(SESSION_CACHE_PATH):
		return {}
	var f := FileAccess.open(SESSION_CACHE_PATH, FileAccess.READ)
	if not f:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}

func _save_profile_cache() -> void:
	var f := FileAccess.open(PROFILE_CACHE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(player_profile))

func _xp_curve(level: int) -> int:
	return int(1000 * pow(1.15, level - 1))
