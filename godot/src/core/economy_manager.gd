extends Node

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

## The six canonical currencies. `earned_by`/`spent_on` document the loops
## the managers implement. NOTE: "cat_coins" is the internal id for Coins
## (kept to avoid rewriting every existing call site); "gems" survives only
## as a legacy balance so old spend_gems paths don't crash — it is NOT one
## of the six and should be migrated to coins pricing over time.
const CURRENCIES: Dictionary = {
	"cat_coins": {
		name="Coins", icon="🪙",
		earned_by="the main currency — purchasable with real-world money; also from races, quests, daily bonus",
		spent_on="anything: chips, shop, entries, subscriptions — the universal spend",
	},
	"chips": {
		name="Chips", icon="🎰",
		earned_by="ONLY purchasable with coins (buy_chips) — and casino winnings pay back in chips",
		spent_on="casino games only: slots, poker, blackjack, wheel bets",
	},
	"fragments": {
		name="Fragments", icon="🧩",
		earned_by="PvE play; casino jackpot rewards; matched 1:1 on your first three coin purchases; events",
		spent_on="PvE: dungeon/run entries, PvE gear, periliminal recovery",
	},
	"tokens": {
		name="Tokens", icon="⚔️",
		earned_by="PvP play; casino jackpot rewards; matched 1:1 on your first three coin purchases; events",
		spent_on="PvP: territory claims, siege gear, liminal doors, guild-war stakes",
	},
	"charges": {
		name="Charges", icon="⚡",
		earned_by="quests, leaderboard placements (Crown takeovers), and achievements — never the casino",
		spent_on="leveling up companions and entities",
	},
	"prestige": {
		name="Prestige", icon="🌟",
		earned_by="general gameplay everywhere — our version of experience (influence level is the level system)",
		spent_on="equivalent exchange: buying past race/faction/morality/influence gates — nothing is truly out of reach if you put in the time",
	},
}

## First-3-coin-purchase match: each purchase is matched 1:1 in fragments
## AND tokens (also flipped on during match events).
const PURCHASE_MATCH_LIMIT := 3
var match_event_active := false

# ── State ──────────────────────────────────────────────────────────────────────
var _balances: Dictionary = {
	"cat_coins": 0,
	"gems":      0, # legacy only — not one of the six
	"chips":     0,
	"fragments": 0,
	"tokens":    0,
	"charges":   0,
	"prestige":  0,
}
var _coin_purchases_made: int = 0
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

# ── Coin purchases, chips, and equivalent exchange ────────────────────────────
## Real-money coin purchase entry point (store hooks call this after the
## platform transaction clears). First three purchases — and any purchase
## during a match event — are matched 1:1 in fragments AND tokens.
func purchase_coins(amount: int) -> void:
	if amount <= 0: return
	await earn_currency("cat_coins", amount, "iap_purchase")
	_coin_purchases_made += 1
	if _coin_purchases_made <= PURCHASE_MATCH_LIMIT or match_event_active:
		await earn_currency("fragments", amount, "purchase_match")
		await earn_currency("tokens", amount, "purchase_match")
		NotificationUI.notify_win("Purchase matched! +%d 🧩 and +%d ⚔️" % [amount, amount])

## Chips can ONLY be bought with coins — the casino's dedicated currency.
func buy_chips(chip_amount: int) -> bool:
	if not await spend_coins(chip_amount, "chip_exchange"):
		return false
	await earn_currency("chips", chip_amount, "chip_exchange")
	return true

## Casino jackpots pay their bonus out in fragments and tokens.
func award_jackpot_bonus(amount: int) -> void:
	await earn_currency("fragments", amount, "jackpot")
	await earn_currency("tokens", amount, "jackpot")

## Equivalent exchange: spend prestige to buy past a gate that would
## otherwise block you (race, faction, morality, influence level, ...).
## Gate cost scales with how "hard" the gate is; callers pass the tier.
func equivalent_exchange(gate: String, tier: int = 1) -> bool:
	var cost := 100 * tier * tier
	if not await spend_currency("prestige", cost, "exchange_%s" % gate):
		NotificationUI.notify_error("Equivalent exchange needs %d 🌟 prestige for this gate." % cost)
		return false
	NotificationUI.notify_win("Exchange accepted — the %s gate opens. 🌟" % gate)
	return true

## Influence level — our level system, derived from lifetime prestige earned
## (spending prestige on exchanges never lowers it).
var _lifetime_prestige: int = 0

func influence_level() -> int:
	return 1 + int(sqrt(_lifetime_prestige / 100.0))

func earn_prestige(amount: int, source: String = "gameplay") -> void:
	_lifetime_prestige += maxi(amount, 0)
	await earn_currency("prestige", amount, source)

func can_spend_coins(amount: int) -> bool:
	return amount > 0 and int(_balances.get(CURRENCY_COINS, 0)) >= amount

## Synchronous local debit (no server round-trip). Prefer await spend_coins.
func spend_coins_local(amount: int, destination: String = "unknown") -> bool:
	if amount <= 0 or not can_spend_coins(amount):
		if amount > 0:
			emit_signal("insufficient_funds", CURRENCY_COINS, amount, _balances[CURRENCY_COINS])
		return false
	_adjust_balance(CURRENCY_COINS, -amount)
	_record_transaction(CURRENCY_COINS, -amount, destination, "spend")
	_save_local_cache()
	return true

func add_coins_local(amount: int, source: String = "unknown") -> void:
	if amount <= 0:
		return
	_adjust_balance(CURRENCY_COINS, amount)
	_record_transaction(CURRENCY_COINS, amount, source, "earn")
	_save_local_cache()

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
	var old: int = int(_balances[currency])
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

const OFFLINE_STARTER_COINS := 5000

func _load_local_cache() -> void:
	if not FileAccess.file_exists("user://economy_cache.json"):
		# First boot / offline guest — seed enough coins to play every mode.
		_balances[CURRENCY_COINS] = OFFLINE_STARTER_COINS
		_balances["chips"] = 500
		_balances["fragments"] = 100
		_balances["tokens"] = 100
		_balances["charges"] = 50
		_balances["prestige"] = 0
		_save_local_cache()
		return
	var f := FileAccess.open("user://economy_cache.json", FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		if "balances" in parsed:
			_balances.merge(parsed["balances"], true)
		_daily_bonus_last_claimed = parsed.get("daily_bonus_last_claimed", "")
		_daily_bonus_streak       = parsed.get("daily_bonus_streak", 0)
	# Legacy empty caches still get a playable stake once.
	if int(_balances.get(CURRENCY_COINS, 0)) <= 0 and _daily_bonus_last_claimed == "":
		_balances[CURRENCY_COINS] = OFFLINE_STARTER_COINS
		_save_local_cache()

func _sync_balances_from_server() -> void:
	if not _nakama_client:
		return
	var result = await _rpc("economy/get_balances", {})
	if result and "balances" in result:
		for currency in result["balances"]:
			if currency in _balances:
				var server_val: int = result["balances"][currency]
				if server_val != _balances[currency]:
					var old: int = int(_balances[currency])
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
	# Routed through NetworkManager.call_rpc so the session (owned by
	# AccountManager) is always the one actually authenticating the call —
	# calling _nakama_client.rpc_async directly here would need a session
	# arg this scope doesn't have.
	var response: Dictionary = {}
	var done := false
	NetworkManager.call_rpc(fn, payload, func(r):
		response = r
		done = true)
	while not done:
		await get_tree().process_frame
	if not response.get("success", true) and response.has("error"):
		push_error("EconomyManager RPC %s failed: %s" % [fn, response.error])
		return null
	return response
