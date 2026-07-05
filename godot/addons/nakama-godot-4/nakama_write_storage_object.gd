class_name NakamaWriteStorageObject
extends RefCounted
## Wire-shape for the /v2/storage write endpoint. `value` is expected to
## already be a JSON-encoded string (callers do JSON.stringify() before
## constructing this, matching Nakama's ApiWriteStorageObject.value field).

var collection: String
var key: String
var permission_read: int
var permission_write: int
var value: String
var version: String

func _init(p_collection: String, p_key: String, p_permission_read: int,
		p_permission_write: int, p_value: String, p_version: String = "") -> void:
	collection = p_collection
	key = p_key
	permission_read = p_permission_read
	permission_write = p_permission_write
	value = p_value
	version = p_version

func to_dict() -> Dictionary:
	var d := {
		"collection": collection, "key": key, "value": value,
		"permission_read": permission_read, "permission_write": permission_write,
	}
	if version != "":
		d["version"] = version
	return d
