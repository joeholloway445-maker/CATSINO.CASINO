extends Node
## Autoloaded as "CrownManager". Crowns, leaderboards, Triple Crown, and the
## Champion→God ascension ladder — ported from the Periliminal.Space Apps
## Script source (docs/reference/periliminal_space_v0.0.1/,
## CrownsLeaderboards.gs + Champion_ascension.gs). Rules preserved:
##  - Every crown (CrownData) is bound to a leaderboard; the current #1
##    wears it. Hidden crowns additionally require a token to claim.
##  - Triple Crown: hold 3+ crowns at once.
##  - Champion ascension: opt in at level >= 50, then survive a 4-hour
##    provisional PvP window; champion levels run 50..1600.
##  - God tier: Triple Crown holders at champion level >= 160 who still
##    hold a crown. Titles: Champion / Ascendant / Former <title> / God.
##  - Guilds accumulate their members' crowns and points collectively.

signal crown_assigned(crown_id: int, player_id: String)
signal crown_lost(crown_id: int, player_id: String)
signal triple_crown(player_id: String)
signal ascended(player_id: String, title: String)

const CHAMPION_LEVEL_MIN := 50
const CHAMPION_LEVEL_MAX := 1600
const PROVISIONAL_PVP_HOURS := 4.0
const GOD_TIER_CHAMPION_LEVEL := 160

## leaderboard name (CrownData.leaderboard) -> Array[{player_id, score}]
var _leaderboards: Dictionary = {}
## crown id -> player_id currently wearing it
var _holders: Dictionary = {}
## player_id -> {title, champion_level, provisional, provisional_hours, tokens}
var _players: Dictionary = {}
## guild name -> {crowns: Array[int], points: Dictionary}
var _guilds: Dictionary = {}

func _player(pid: String) -> Dictionary:
	return _players.get_or_add(pid, {
		"title": "", "champion_level": 0,
		"provisional": false, "provisional_hours": 0.0,
		"tokens": 0, "guild": "",
	})

## Score into a crown's leaderboard; the #1 automatically wears the crown
## (hidden crowns only transfer if the top player has a claim token).
func add_score(leaderboard: String, player_id: String, score: int, guild: String = "") -> void:
	var crown := CrownData.by_leaderboard(leaderboard)
	var board: Array = _leaderboards.get_or_add(leaderboard, [])
	var found := false
	for e in board:
		if e.player_id == player_id:
			e.score += score
			found = true
			break
	if not found:
		board.append({"player_id": player_id, "score": score})
	board.sort_custom(func(a, b): return a.score > b.score)

	if guild != "":
		_player(player_id)["guild"] = guild
		var g: Dictionary = _guilds.get_or_add(guild, {"crowns": [], "points": {}})
		g.points[leaderboard] = g.points.get(leaderboard, 0) + score

	if crown.is_empty():
		return
	var top: String = board[0].player_id
	if _holders.get(crown.id, "") == top:
		return
	if crown.token_required and _player(top)["tokens"] <= 0:
		return # hidden crown: #1 without a token doesn't take it
	_transfer_crown(crown, top)

func _transfer_crown(crown: Dictionary, new_holder: String) -> void:
	var prev: String = _holders.get(crown.id, "")
	if prev != "":
		crown_lost.emit(crown.id, prev)
		var pg: String = _player(prev)["guild"]
		if pg != "" and _guilds.has(pg):
			_guilds[pg].crowns.erase(crown.id)
	if crown.token_required:
		_player(new_holder)["tokens"] -= 1
	_holders[crown.id] = new_holder
	crown_assigned.emit(crown.id, new_holder)
	var g: String = _player(new_holder)["guild"]
	if g != "" and _guilds.has(g) and crown.id not in _guilds[g].crowns:
		_guilds[g].crowns.append(crown.id)
	if crowns_of(new_holder).size() >= 3:
		triple_crown.emit(new_holder)
	NotificationUI.notify_info("👑 %s takes the %s!" % [new_holder, crown.name])
	if new_holder == "local_player":
		# Charges: quests, leaderboards, achievements — never the casino.
		EconomyManager.earn_currency("charges", 25, "crown_%s" % crown.id)

func crowns_of(player_id: String) -> Array[int]:
	var r: Array[int] = []
	for cid in _holders.keys():
		if _holders[cid] == player_id:
			r.append(cid)
	return r

func has_triple_crown(player_id: String) -> bool:
	return crowns_of(player_id).size() >= 3

## Sum of every 5% passive the player's crowns grant, as a multiplier.
func crown_bonus_mult(player_id: String) -> float:
	return 1.0 + 0.05 * crowns_of(player_id).size()

## Hidden-crown claim tokens (earned from hidden events; see token economy).
func grant_claim_token(player_id: String, count: int = 1) -> void:
	_player(player_id)["tokens"] += count

# ── Champion → God ascension ──────────────────────────────────────────────────
func start_champion_trial(player_id: String, level: int) -> bool:
	if level < CHAMPION_LEVEL_MIN:
		NotificationUI.notify_error("Champion trials open at level %d." % CHAMPION_LEVEL_MIN)
		return false
	var p := _player(player_id)
	p["provisional"] = true
	p["provisional_hours"] = 0.0
	NotificationUI.notify_info("⚔️ Champion trial begun — survive %d hours of provisional PvP." % int(PROVISIONAL_PVP_HOURS))
	return true

func log_provisional_pvp(player_id: String, hours: float) -> void:
	var p := _player(player_id)
	if not p["provisional"]:
		return
	p["provisional_hours"] += hours
	if p["provisional_hours"] >= PROVISIONAL_PVP_HOURS:
		p["provisional"] = false
		p["champion_level"] = 1
		p["title"] = "Champion"
		ascended.emit(player_id, "Champion")
		NotificationUI.notify_win("🏆 %s is now a Champion!" % player_id)
		NotificationUI.notify_info("A second frame awaits — your senses are about to double. (Character menu)")

func add_champion_levels(player_id: String, levels: int) -> void:
	var p := _player(player_id)
	if p["title"] == "":
		return
	p["champion_level"] = clampi(p["champion_level"] + levels, 0, CHAMPION_LEVEL_MAX)

func attempt_god_ascension(player_id: String) -> bool:
	var p := _player(player_id)
	if not has_triple_crown(player_id) or p["champion_level"] < GOD_TIER_CHAMPION_LEVEL:
		return false
	if crowns_of(player_id).is_empty():
		return false
	p["title"] = "God"
	ascended.emit(player_id, "God")
	NotificationUI.notify_win("⚡ %s has ascended to GOD tier." % player_id)
	return true

func demote(player_id: String) -> void:
	var p := _player(player_id)
	if p["title"] in ["Champion", "Ascendant"]:
		p["title"] = "Former " + p["title"]

func title_of(player_id: String) -> String:
	return _player(player_id)["title"]

func guild_crowns(guild: String) -> Array:
	return _guilds.get(guild, {}).get("crowns", [])
