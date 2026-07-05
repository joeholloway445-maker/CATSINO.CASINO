class_name NakamaException
extends RefCounted
## Uniform failure result for every async call in this client. Matches the
## `result.is_exception()` / `result.get_exception().message` pattern the
## managers already code against.

var status_code: int
var message: String

func _init(p_status_code: int = 0, p_message: String = "") -> void:
	status_code = p_status_code
	message = p_message

func is_exception() -> bool:
	return true

func get_exception() -> NakamaException:
	return self

func _to_string() -> String:
	return "NakamaException(%d): %s" % [status_code, message]
