extends Node
class_name EconomyManager

# ── Signals ────────────────────────────────────────────────────────────────────
signal balance_changed(currency: String, old_balance: int, new_balance: int)
signal transaction_recorded(tx: Dictionary)
signal daily_bonus_claimed(amount: int)
signal insufficient_funds(currency: String, required: int, available: int)

# ── Constants ──────────────────────────────────────────────────────────────────
const CURRENCY_COINS   := "cat_coins"
const CURRENCY_GEMS    := "gems"
const DAILY_BONUS_BASE := 500
const DAILY_BONUS_MAX  := 5000
const DAILY_STREAK_CAP := 7

## The six currencies — one anchored to each reality layer. `earned_by` and
## `spent_on` document the acquisition/sink loops the managers implement.
const CURRENCIES: Dictionary = {
	"cat_coins": {
		name="Cat Coins", icon="🪙", layer="hyperliminal",
		earned_by="casino games, races, quests, daily bonus",
		spent_on="bets, race entries, shop items, tournament fees",
	},
	"gems": {
		name="Gems", icon="💎", layer="hyperliminal",
		earned_by="battlepass, achievements, big quest chains, IAP",
		spent_on="game-mode activations, gacha, premium cosmetics",
	},
	"essence": {
		name="Essence", icon="🌫️", layer="liminal",
		earned_by="surviving liminal excursions; harvested from never-static chunks before they dissolve",
		spent_on="stabilizing a liminal exit, opening liminal doors (guild wars), shortcut travel between layers",
	},
	"influence": {
		name="Influence", icon="🏴", layer="supraliminal",
		earned_by="claiming/holding territory, winning alliance fights, keystone chunks",
		spent_on="alliance upgrades, siege gear, hub-adjacent claim rights",
	},
	"sigil": {
		name="Sigils", icon="🔮", layer="extraliminal",
		earned_by="catching roaming entities, holding landmark guild halls, guild-war victories",
		spent_on="guild hall perks, landmark fortification, entity lures",
	},
	"whisper": {
		name="Whispers", icon="👁️", layer="periliminal",
		earned_by="ONLY by surviving Periliminal runs — the deeper the run, the more you carry out",
		spent_on="the rarest blueprints, resurrecting one lost entity, permanent account-wide perks",
	},
}

# ── State ──────────────────────────────────────────────────────────────────────
var _balances: Dictionary = {
	"cat_coins": 0,
	"gems":      0,
	"essence":   0,
	"influence": 0,
	"sigil":     0,
	"whisper":   0,
}
var transaction_log: Array[Dictionary] = []
var _daily_bonus_last_claimed: String = ""
var _daily_bonus_streak: int          = 0
var _nakama_client                    = null  # set by AccountManager after auth

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_load_local_cache()

func initialize(nakama_client) -> void:
	_nakama_client = nakama_client
	await _sync_balances_from_server()

# ── Public API — Cat Coins ────────────────────────────────────────────────────
func get_coins() -> int:
	return _balances[CURRENCY_COINS]

func get_gems() -> int:
	return _balances[CURRENCY_GEMS]

func earn_coins(amount: int, source: String = "unknown") -> void:
	if amount <= 0:
		push_warning("EconomyManager: earn_coins called with non-positive amount %d" % amount)
		return
	_adjust_balance(CURRENCY_COINS, amount)
	_record_transaction(CURRENCY_COINS, amount, source, "earn")
	await _push_transaction_to_server(CURRENCY_COINS, amount, source, "earn")

## Alias for earn_coins — quest/arena/liveops rewards call add_coins.
func add_coins(amount: int, source: String = "unknown") -> void:
	earn_coins(amount, source)

# ── Generic currency API (all six layer currencies) ───────────────────────────
func get_balance(currency: String) -> int:
	return _balances.get(currency, 0)

func earn_currency(currency: String, amount: int, source: String = "unknown") -> void:
	if amount <= 0 or not CURRENCIES.has(currency):
		return
	_adjust_balance(currency, amount)
	_record_transaction(currency, amount, source, "earn")
	await _push_transaction_to_server(currency, amount, source, "earn")

func spend_currency(currency: String, amount: int, destination: String = "unknown") -> bool:
	if amount <= 0 or not CURRENCIES.has(currency):
		return false
	if _balances.get(currency, 0) < amount:
		emit_signal("insufficient_funds", currency, amount, _balances.get(currency, 0))
		return false
	_adjust_balance(currency, -amount)
	_record_transaction(currency, -amount, destination, "spend")
	await _push_transaction_to_server(currency, -amount, destination, "spend")
	return true

func spend_coins(amount: int, destination: String = "unknown") -> bool:
	if amount <= 0:
		push_warning("EconomyManager: spend_coins called with non-positive amount %d" % amount)
		return false
	if _balances[CURRENCY_COINS] < amount:
		emit_signal("insufficient_funds", CURRENCY_COINS, amount, _balances[CURRENCY_COINS])
		return false
	_adjust_balance(CURRENCY_COINS, -amount)
	_record_transaction(CURRENCY_COINS, -amount, destination, "spend")
	await _push_transaction_to_server(CURRENCY_COINS, -amount, destination, "spend")
	return true

func earn_gems(amount: int, source: String = "iap") -> void:
	if amount <= 0:
		return
	_adjust_balance(CURRENCY_GEMS, amount)
	_record_transaction(CURRENCY_GEMS, amount, source, "earn")
	await _push_transaction_to_server(CURRENCY_GEMS, amount, source, "earn")

func spend_gems(amount: int, destination: String = "unknown") -> bool:
	if amount <= 0:
		return false
	if _balances[CURRENCY_GEMS] < amount:
		emit_signal("insufficient_funds", CURRENCY_GEMS, amount, _balances[CURRENCY_GEMS])
		return false
	_adjust_balance(CURRENCY_GEMS, -amount)
	_record_transaction(CURRENCY_GEMS, -amount, destination, "spend")
	await _push_transaction_to_server(CURRENCY_GEMS, -amount, destination, "spend")
	return true

func transfer_coins(amount: int, to_player_id: String) -> bool:
	if not await spend_coins(amount, "transfer_to:%s" % to_player_id):
		return false
	# Server-side handles crediting recipient via Nakama RPC
	if _nakama_client:
		await _rpc("economy/transfer", {
			"amount": amount,
			"currency": CURRENCY_COINS,
			"recipient_id": to_player_id
		})
	return true

# ── Daily Bonus ────────────────────────────────────────────────────────────────
func claim_daily_bonus() -> int:
	var today := Time.get_date_string_from_system()
	if _daily_bonus_last_claimed == today:
		push_warning("EconomyManager: daily bonus already claimed today")
		return 0
	var yesterday := _get_yesterday_string()
	if _daily_bonus_last_claimed == yesterday:
		_daily_bonus_streak = mini(_daily_bonus_streak + 1, DAILY_STREAK_CAP)
	else:
		_daily_bonus_streak = 1
	_daily_bonus_last_claimed = today
	var bonus := _calculate_daily_bonus()
	_adjust_balance(CURRENCY_COINS, bonus)
	_record_transaction(CURRENCY_COINS, bonus, "daily_bonus", "earn")
	emit_signal("daily_bonus_claimed", bonus)
	_save_local_cache()
	if _nakama_client:
		await _rpc("economy/claim_daily_bonus", {"streak": _daily_bonus_streak})
	return bonus

func get_daily_bonus_streak() -> int:
	return _daily_bonus_streak

func can_claim_daily_bonus() -> bool:
	return _daily_bonus_last_claimed != Time.get_date_string_from_system()

# ── Private ────────────────────────────────────────────────────────────────────
func _adjust_balance(currency: String, delta: int) -> void:
	var old := _balances[currency]
	_balances[currency] = maxi(0, old + delta)
	emit_signal("balance_changed", currency, old, _balances[currency])
	_save_local_cache()

func _record_transaction(currency: String, amount: int, party: String, kind: String) -> void:
	var tx := {
		"id":        "%s_%d" % [kind, Time.get_ticks_msec()],
		"currency":  currency,
		"amount":    amount,
		"party":     party,
		"kind":      kind,
		"timestamp": Time.get_datetime_string_from_system(),
	}
	transaction_log.append(tx)
	if transaction_log.size() > 500:
		transaction_log.pop_front()
	emit_signal("transaction_recorded", tx)

func _calculate_daily_bonus() -> int:
	var base := DAILY_BONUS_BASE
	var streak_mult := 1.0 + (_daily_bonus_streak - 1) * 0.25
	return mini(int(base * streak_mult), DAILY_BONUS_MAX)

func _get_yesterday_string() -> String:
	var unix := Time.get_unix_time_from_system() - 86400
	return Time.get_date_string_from_unix_time(unix)

func _save_local_cache() -> void:
	var data := {
		"balances":                  _balances,
		"daily_bonus_last_claimed":  _daily_bonus_last_claimed,
		"daily_bonus_streak":        _daily_bonus_streak,
	}
	var f := FileAccess.open("user://economy_cache.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func _load_local_cache() -> void:
	if not FileAccess.file_exists("user://economy_cache.json"):
		return
	var f := FileAccess.open("user://economy_cache.json", FileAccess.READ)
	if not f:
		return
	var parsed := JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		if "balances" in parsed:
			_balances.merge(parsed["balances"], true)
		_daily_bonus_last_claimed = parsed.get("daily_bonus_last_claimed", "")
		_daily_bonus_streak       = parsed.get("daily_bonus_streak", 0)

func _sync_balances_from_server() -> void:
	if not _nakama_client:
		return
	var result := await _rpc("economy/get_balances", {})
	if result and "balances" in result:
		for currency in result["balances"]:
			if currency in _balances:
				var server_val: int = result["balances"][currency]
				if server_val != _balances[currency]:
					var old := _balances[currency]
					_balances[currency] = server_val
					emit_signal("balance_changed", currency, old, server_val)
		_save_local_cache()

func _push_transaction_to_server(currency: String, amount: int, party: String, kind: String) -> void:
	if not _nakama_client:
		return
	await _rpc("economy/record_transaction", {
		"currency": currency,
		"amount":   amount,
		"party":    party,
		"kind":     kind,
	})

func _rpc(fn: String, payload: Dictionary):
	if not _nakama_client:
		return null
	# Nakama Godot 4 client pattern
	var result = await _nakama_client.rpc_async(fn, JSON.stringify(payload))
	if result.is_exception():
		push_error("EconomyManager RPC %s failed: %s" % [fn, result.get_exception().message])
		return null
	if result.payload:
		return JSON.parse_string(result.payload)
	return null
