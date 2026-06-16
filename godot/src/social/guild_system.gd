class_name GuildSystem
extends Node

signal guild_joined(guild_id: String)
signal guild_left()

var current_guild_id: String = ""
var current_guild_name: String = ""

func join_guild(guild_id: String) -> void:
	NetworkManager.call_rpc("join_guild", {guild_id=guild_id},
		func(result: Dictionary):
			if result.get("success"):
				current_guild_id = guild_id
				current_guild_name = result.get("guild_name", "Guild")
				guild_joined.emit(guild_id)
				NotificationUI.notify_achievement("🏰 Joined guild: %s!" % current_guild_name)
			else:
				NotificationUI.notify_error("Could not join guild: %s" % result.get("error", ""))
	)

func leave_guild() -> void:
	NetworkManager.call_rpc("leave_guild", {},
		func(result: Dictionary):
			if result.get("success"):
				current_guild_id = ""
				current_guild_name = ""
				guild_left.emit()

	)

func get_guild_info(guild_id: String, callback: Callable) -> void:
	NetworkManager.call_rpc("get_guild", {guild_id=guild_id}, callback)

func list_guilds(callback: Callable) -> void:
	NetworkManager.call_rpc("list_guilds", {}, callback)
