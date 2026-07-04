class_name NakamaSession
extends RefCounted

var token: String = ""
var user_id: String = ""
var username: String = ""
var expired: bool = false
var _expiry_time: int = 0

func _init(p_token: String, p_user_id: String, p_username: String, expiry_sec: int = 86400) -> void:
	token = p_token
	user_id = p_user_id
	username = p_username
	_expiry_time = Time.get_unix_time_from_system() + expiry_sec

func is_expired() -> bool:
	return Time.get_unix_time_from_system() > _expiry_time
