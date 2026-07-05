class_name NakamaStorageObjectId
extends RefCounted
## Identifies one object for the /v2/storage/get read endpoint.

var collection: String
var key: String
var user_id: String

func _init(p_collection: String, p_key: String, p_user_id: String = "") -> void:
	collection = p_collection
	key = p_key
	user_id = p_user_id

func to_dict() -> Dictionary:
	var d := {"collection": collection, "key": key}
	if user_id != "":
		d["user_id"] = user_id
	return d
