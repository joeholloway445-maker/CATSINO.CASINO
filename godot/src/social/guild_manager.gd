extends Node
## Autoloaded as "GuildManager". Player-made guilds with CUSTOMIZABLE ranks:
## the default ladder is Recruit → Officer → Lieutenant → Leader, but the
## leader can rename every rank and add up to four more. Guilds hook into
## everything already built: CrownManager accumulates member crowns/points
## per guild, ExtraliminalManager guild wars fight over landmark halls, and
## the guild bank (BankManager) is shared per-rank-permission.

signal guild_created(guild: Dictionary)
signal member_joined(guild_name: String, player_id: String)
signal rank_changed(player_id: String, rank: String)

const SAVE_PATH := "user://guild.json"
const CREATE_COST_COINS := 5000
const MAX_CUSTOM_RANKS := 8

## The player's guild (client-side authority for now; Nakama groups later).
var guild: Dictionary = {} # {name, tag, ranks: Array[String], members: {id: rank_index}, motd}

func in_guild() -> bool:
	return not guild.is_empty()

func _ready() -> void:
	_load()

func create_guild(gname: String, tag: String) -> bool:
	if in_guild():
		NotificationUI.notify_error("Leave your current guild first.")
		return false
	if gname.strip_edges().length() < 3:
		NotificationUI.notify_error("Guild names need at least 3 characters.")
		return false
	if not await EconomyManager.spend_coins(CREATE_COST_COINS, "guild_charter"):
		NotificationUI.notify_error("A guild charter costs %d 🪙." % CREATE_COST_COINS)
		return false
	guild = {
		"name": gname.strip_edges(), "tag": tag.strip_edges().to_upper().left(4),
		"ranks": ["Recruit", "Officer", "Lieutenant", "Leader"],
		"members": {"local_player": 3}, # founder is Leader
		"motd": "New charter. Make it mean something.",
	}
	_save()
	guild_created.emit(guild)
	NotificationUI.notify_win("🏰 Guild '%s' [%s] chartered!" % [guild.name, guild.tag])
	return true

## Rank customization — leaders rename the ladder or extend it (cap 8).
func rename_rank(index: int, new_name: String) -> bool:
	if not _is_leader() or index < 0 or index >= guild.ranks.size():
		return false
	guild.ranks[index] = new_name.strip_edges()
	_save()
	return true

func add_rank(rank_name: String) -> bool:
	if not _is_leader() or guild.ranks.size() >= MAX_CUSTOM_RANKS:
		return false
	# New ranks slot in below Leader (which stays top).
	guild.ranks.insert(guild.ranks.size() - 1, rank_name.strip_edges())
	_save()
	return true

func recruit(player_id: String) -> bool:
	if not in_guild() or guild.members.has(player_id):
		return false
	guild.members[player_id] = 0 # Recruit
	_save()
	member_joined.emit(guild.name, player_id)
	return true

func promote(player_id: String) -> bool:
	if not _is_leader() or not guild.members.has(player_id):
		return false
	var r: int = guild.members[player_id]
	if r >= guild.ranks.size() - 1:
		return false
	guild.members[player_id] = r + 1
	rank_changed.emit(player_id, guild.ranks[r + 1])
	_save()
	return true

func demote(player_id: String) -> bool:
	if not _is_leader() or not guild.members.has(player_id):
		return false
	var r: int = guild.members[player_id]
	if r <= 0:
		return false
	guild.members[player_id] = r - 1
	rank_changed.emit(player_id, guild.ranks[r - 1])
	_save()
	return true

func rank_of(player_id: String) -> String:
	if not in_guild() or not guild.members.has(player_id):
		return ""
	return guild.ranks[guild.members[player_id]]

## Officer+ (index >= 1) can withdraw from the guild bank; everyone deposits.
func can_use_guild_bank(player_id: String) -> bool:
	return in_guild() and guild.members.get(player_id, -1) >= 1

func _is_leader() -> bool:
	return in_guild() and guild.members.get("local_player", -1) == guild.ranks.size() - 1

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(guild))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f: return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary: guild = d
