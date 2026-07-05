class_name NakamaModels
extends RefCounted
## Lightweight read-only wrappers around Nakama's JSON response shapes.
## Nested classes (Account, Rpc, ...) rather than one file per type since
## nothing outside this addon names these types directly — managers only
## duck-type against their fields (result.user.id, result.friends, etc.).

class Ack:
	extends RefCounted
	func is_exception() -> bool: return false

class ApiUser:
	extends RefCounted
	var id: String
	var username: String
	var display_name: String
	var avatar_url: String
	var create_time: String
	var metadata: String # raw JSON string, matches real API shape
	func _init(d: Dictionary) -> void:
		id = str(d.get("id", ""))
		username = str(d.get("username", ""))
		display_name = str(d.get("display_name", ""))
		avatar_url = str(d.get("avatar_url", ""))
		create_time = str(d.get("create_time", ""))
		metadata = str(d.get("metadata", "{}"))

class Account:
	extends RefCounted
	var user: ApiUser
	var wallet: String
	func _init(d: Dictionary) -> void:
		user = ApiUser.new(d.get("user", {}))
		wallet = str(d.get("wallet", "{}"))
	func is_exception() -> bool: return false

class Rpc:
	extends RefCounted
	var id: String
	var payload: String
	func _init(d: Dictionary, fallback_id: String = "") -> void:
		id = str(d.get("id", fallback_id))
		payload = str(d.get("payload", "{}"))
	func is_exception() -> bool: return false

class Friend:
	extends RefCounted
	var user: ApiUser
	var state: int
	func _init(d: Dictionary) -> void:
		user = ApiUser.new(d.get("user", {}))
		state = int(d.get("state", 0))

class FriendList:
	extends RefCounted
	var friends: Array[Friend] = []
	var cursor: String = ""
	func _init(d: Dictionary) -> void:
		for f in d.get("friends", []):
			friends.append(Friend.new(f))
		cursor = str(d.get("cursor", ""))
	func is_exception() -> bool: return false

class Group:
	extends RefCounted
	var id: String
	var name: String
	var description: String
	var max_count: int
	var edge_count: int
	var open: bool
	func _init(d: Dictionary) -> void:
		id = str(d.get("id", ""))
		name = str(d.get("name", ""))
		description = str(d.get("description", ""))
		max_count = int(d.get("max_count", 0))
		edge_count = int(d.get("edge_count", 0))
		open = bool(d.get("open", true))
	func is_exception() -> bool: return false

class GroupList:
	extends RefCounted
	var groups: Array[Group] = []
	var cursor: String = ""
	func _init(d: Dictionary) -> void:
		for g in d.get("groups", []):
			groups.append(Group.new(g.get("group", g)))
		cursor = str(d.get("cursor", ""))
	func is_exception() -> bool: return false

class StorageObject:
	extends RefCounted
	var collection: String
	var key: String
	var user_id: String
	var value: String
	var version: String
	func _init(d: Dictionary) -> void:
		collection = str(d.get("collection", ""))
		key = str(d.get("key", ""))
		user_id = str(d.get("user_id", ""))
		value = str(d.get("value", "{}"))
		version = str(d.get("version", ""))

class StorageObjectList:
	extends RefCounted
	var objects: Array[StorageObject] = []
	func _init(d: Dictionary) -> void:
		for o in d.get("objects", []):
			objects.append(StorageObject.new(o))
	func is_exception() -> bool: return false

class ChannelMessage:
	extends RefCounted
	var channel_id: String
	var message_id: String
	var code: int
	var sender_id: String
	var username: String
	var content: String
	var create_time: String
	func _init(d: Dictionary) -> void:
		channel_id = str(d.get("channel_id", ""))
		message_id = str(d.get("message_id", ""))
		code = int(d.get("code", 0))
		sender_id = str(d.get("sender_id", ""))
		username = str(d.get("username", ""))
		content = str(d.get("content", "{}"))
		create_time = str(d.get("create_time", ""))

class Presence:
	extends RefCounted
	var user_id: String
	var username: String
	var session_id: String
	func _init(d: Dictionary) -> void:
		user_id = str(d.get("user_id", ""))
		username = str(d.get("username", ""))
		session_id = str(d.get("session_id", ""))

class StatusPresenceEvent:
	extends RefCounted
	var joins: Array[Presence] = []
	var leaves: Array[Presence] = []
	func _init(d: Dictionary) -> void:
		for p in d.get("joins", []):
			joins.append(Presence.new(p))
		for p in d.get("leaves", []):
			leaves.append(Presence.new(p))

class Notification:
	extends RefCounted
	var id: String
	var subject: String
	var content: String
	var code: int
	var sender_id: String
	var create_time: String
	func _init(d: Dictionary) -> void:
		id = str(d.get("id", ""))
		subject = str(d.get("subject", ""))
		content = str(d.get("content", "{}"))
		code = int(d.get("code", 0))
		sender_id = str(d.get("sender_id", ""))
		create_time = str(d.get("create_time", ""))
