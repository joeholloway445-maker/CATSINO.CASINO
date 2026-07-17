extends Node

# ── Signals ────────────────────────────────────────────────────────────────────
signal balance_changed(currency: String, old_balance: int, new_balance: int)
signal transaction_recorded(tx: Dictionary)
signal daily_bonus_claimed(amount: int)
signal insufficient_funds(currency: String, required: int, available: int)

# ── Constants ──────────────────────────────────────────────────────────────────
const CURRENCY_COINS    := "cat_coins"
const CURRENCY_EX_COINS := "ex_coins"
const CURRENCY_GEMS     := "gems"
const DAILY_BONUS_BASE := 500
const DAILY_BONUS_MAX  := 5000
const DAILY_STREAK_CAP := 7

## Canonical currencies. `earned_by`/`spent_on` document the loops the
## managers implement. NOTE: "cat_coins" is the internal id for Coins
## (kept to avoid rewriting every existing call site); "gems" survives only
## as a legacy balance so old spend_gems paths don't crash — migrate those
## price points to coins over time.
##
## Compliance twin: Ex-Coins (`ex_coins`) are spendable anywhere Coins are,
## but are NEVER purchasable and NEVER convertible back into Coins. The only
## earn path is cashing casino chips out at the cage (house-favorable rate).
const CURRENCIES: Dictionary = {
	"cat_coins": {
		name="Coins", icon="🪙",
		earned_by="the main currency — purchasable with real-world money; also from races, quests, daily bonus",
		spent_on="anything: chips, shop, entries, subscriptions — the universal spend",
	},
	"ex_coins": {
		name="Ex-Coins", icon="✴️",
		earned_by="ONLY by cashing chips out at the cage (chip_cashout) — never IAP, never quests, never convertible from Coins",
		spent_on="same as Coins (shop, entries, subs, chip buy) — spend_coins drains Ex-Coins first",
	},
	"chips": {
		name="Chips", icon="🎰",
		earned_by="purchasable with Coins/Ex-Coins (buy_chips) — casino winnings pay back in chips",
		spent_on="casino games only: slots, poker, blackjack, wheel bets — cash out ONLY to Ex-Coins",
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
	"ex_coins":  0, # compliance twin — chip cash-out only
	"gems":      0, # legacy only — not a primary currency
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
	return int(_balances.get(CURRENCY_COINS, 0))

func get_ex_coins() -> int:
	return int(_balances.get(CURRENCY_EX_COINS, 0))

## Coins + Ex-Coins — what shop/subs/chip-buy actually check.
func get_spendable_coins() -> int:
	return get_coins() + get_ex_coins()

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

## Ex-Coins may ONLY be granted from chip cash-out. Any other source is rejected.
func earn_ex_coins(amount: int, source: String = "chip_cashout") -> void:
	if amount <= 0:
		return
	if not str(source).begins_with("chip_cashout"):
		push_error("EconomyManager: refused ex_coins earn from '%s' (chip_cashout only)" % source)
		return
	_adjust_balance(CURRENCY_EX_COINS, amount)
	_record_transaction(CURRENCY_EX_COINS, amount, source, "earn")
	await _push_transaction_to_server(CURRENCY_EX_COINS, amount, source, "earn")

func earn_ex_coins_local(amount: int, source: String = "chip_cashout_local") -> void:
	if amount <= 0:
		return
	if not str(source).begins_with("chip_cashout"):
		push_error("EconomyManager: refused ex_coins earn from '%s' (chip_cashout only)" % source)
		return
	_adjust_balance(CURRENCY_EX_COINS, amount)
	_record_transaction(CURRENCY_EX_COINS, amount, source, "earn")
	_save_local_cache()

# ── Generic currency API ──────────────────────────────────────────────────────
func get_balance(currency: String) -> int:
	return _balances.get(currency, 0)

func earn_currency(currency: String, amount: int, source: String = "unknown") -> void:
	if amount <= 0 or not CURRENCIES.has(currency):
		return
	# Hard lock: Ex-Coins never enter through the generic earn path.
	if currency == CURRENCY_EX_COINS:
		await earn_ex_coins(amount, source)
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

## Synchronous local debit — used by OfflineCasino so table spins never hang
## waiting on a Nakama push that isn't there.
func spend_currency_local(currency: String, amount: int, destination: String = "unknown") -> bool:
	if amount <= 0 or not _balances.has(currency):
		return false
	if int(_balances.get(currency, 0)) < amount:
		emit_signal("insufficient_funds", currency, amount, _balances.get(currency, 0))
		return false
	_adjust_balance(currency, -amount)
	_record_transaction(currency, -amount, destination, "spend")
	return true

func earn_currency_local(currency: String, amount: int, source: String = "unknown") -> void:
	if amount <= 0 or not _balances.has(currency):
		return
	if currency == CURRENCY_EX_COINS:
		earn_ex_coins_local(amount, source)
		return
	_adjust_balance(currency, amount)
	_record_transaction(currency, amount, source, "earn")

# ── Coin purchases, chips, and equivalent exchange ────────────────────────────
## House-favorable cage spreads. Buying chips costs MORE spendable coins
## than face value; cashing chips out pays FEWER Ex-Coins (never Coins).
## Rates are quoted per 100 units so integer math stays exact.
const CHIP_BUY_COINS_PER_100 := 115   # pay 115 Coins/Ex-Coins → 100 chips
const CHIP_TO_EX_PER_100 := 85        # pay 100 chips → 85 Ex-Coins (never Coins)
const FX_BUY_COINS_PER_100 := 120     # cross-currency buy (fragments/tokens)
const FX_SELL_COINS_PER_100 := 80     # cross-currency sell back to Coins
## Legacy alias — smoke/docs that still say "sell" mean chip→Ex-Coins payout.
const CHIP_SELL_COINS_PER_100 := CHIP_TO_EX_PER_100

## Real-money coin purchase entry point (store hooks call this after the
## platform transaction clears). First three purchases — and any purchase
## during a match event — are matched 1:1 in fragments AND tokens.
## Ex-Coins are intentionally NOT grantable here.
func purchase_coins(amount: int) -> void:
	if amount <= 0: return
	await earn_currency("cat_coins", amount, "iap_purchase")
	_coin_purchases_made += 1
	if _coin_purchases_made <= PURCHASE_MATCH_LIMIT or match_event_active:
		await earn_currency("fragments", amount, "purchase_match")
		await earn_currency("tokens", amount, "purchase_match")
		NotificationUI.notify_win("Purchase matched! +%d 🧩 and +%d ⚔️" % [amount, amount])

## Spendable (Coins+Ex-Coins) required to buy `chip_amount` chips.
func chip_buy_coin_cost(chip_amount: int) -> int:
	if chip_amount <= 0:
		return 0
	return int(ceil(chip_amount * CHIP_BUY_COINS_PER_100 / 100.0))

## Ex-Coins received when cashing out `chip_amount` chips (never Coins).
func chip_cashout_ex_payout(chip_amount: int) -> int:
	if chip_amount <= 0:
		return 0
	return int(floor(chip_amount * CHIP_TO_EX_PER_100 / 100.0))

## Legacy name — returns Ex-Coin payout, not Coins.
func chip_sell_coin_payout(chip_amount: int) -> int:
	return chip_cashout_ex_payout(chip_amount)

## Buy chips with spendable Coins/Ex-Coins at the house buy rate.
func buy_chips(chip_amount: int) -> bool:
	var cost := chip_buy_coin_cost(chip_amount)
	if cost <= 0:
		return false
	if not await spend_coins(cost, "chip_buy"):
		return false
	await earn_currency("chips", chip_amount, "chip_buy")
	_record_fx_audit("buy_chips", "spendable", cost, "chips", chip_amount)
	return true

## Cash chips out to Ex-Coins only (compliance: never back into purchasable Coins).
func sell_chips(chip_amount: int) -> bool:
	return await cashout_chips_to_ex(chip_amount)

func cashout_chips_to_ex(chip_amount: int) -> bool:
	var payout := chip_cashout_ex_payout(chip_amount)
	if chip_amount <= 0 or payout <= 0:
		return false
	if not await spend_currency("chips", chip_amount, "chip_cashout"):
		return false
	await earn_ex_coins(payout, "chip_cashout")
	var sides := _grant_cashout_side_drops(chip_amount)
	_record_fx_audit("chip_cashout", "chips", chip_amount, CURRENCY_EX_COINS, payout)
	Hope.record("chip_cashout_sides", sides)
	return true

## Local (offline) cage buy — same house spread, no Nakama round-trip.
func buy_chips_local(chip_amount: int) -> bool:
	var cost := chip_buy_coin_cost(chip_amount)
	if cost <= 0:
		return false
	if not spend_coins_local(cost, "chip_buy"):
		return false
	earn_currency_local("chips", chip_amount, "chip_buy")
	_record_fx_audit("buy_chips_local", "spendable", cost, "chips", chip_amount)
	return true

func sell_chips_local(chip_amount: int) -> bool:
	return not cashout_chips_to_ex_local(chip_amount).is_empty()

func cashout_chips_to_ex_local(chip_amount: int) -> Dictionary:
	var payout := chip_cashout_ex_payout(chip_amount)
	if chip_amount <= 0 or payout <= 0:
		return {}
	if not spend_currency_local("chips", chip_amount, "chip_cashout"):
		return {}
	earn_ex_coins_local(payout, "chip_cashout_local")
	var sides := _grant_cashout_side_drops(chip_amount)
	_record_fx_audit("chip_cashout_local", "chips", chip_amount, CURRENCY_EX_COINS, payout)
	Hope.record("chip_cashout_sides", sides)
	return {"ex_coins": payout, "sides": sides}

## Small randomized extras on every chip cash-out. Caps stay tiny so this
## is flavor + drip progression, not a farm. Never grants Coins or Ex-Coins.
## Wagering Arts passive "Cage Regular" (wag_p1) adds +1 to each drip that lands.
func _grant_cashout_side_drops(chip_amount: int) -> Dictionary:
	var scale := mini(2, int(chip_amount / 250)) # 0..2 from size
	var cage_regular := false
	if typeof(SkillManager) != TYPE_NIL and SkillManager.has_method("has_prestige_passive"):
		cage_regular = bool(SkillManager.has_prestige_passive("wag_p1"))
	var sides := {"fragments": 0, "tokens": 0, "charges": 0}
	for cur in sides.keys():
		# ~70% chance each currency drips something; amount 1..(2+scale)
		if randf() > 0.70:
			continue
		var amt := randi_range(1, 2 + scale)
		if cage_regular:
			amt += 1
		sides[cur] = amt
		earn_currency_local(cur, amt, "chip_cashout_side")
	return sides

## Cross-currency exchange via Coins (house-favorable both legs).
## Compliance locks:
##  - Ex-Coins cannot be bought or sold through FX
##  - Chips cannot convert into Coins (use cashout_chips_to_ex instead)
func exchange_currency(from_currency: String, to_currency: String, amount: int) -> bool:
	if amount <= 0 or from_currency == to_currency:
		return false
	if from_currency == CURRENCY_EX_COINS or to_currency == CURRENCY_EX_COINS:
		push_warning("EconomyManager: Ex-Coins are not FX-tradable — cash chips out or spend them.")
		return false
	if from_currency == "chips" and to_currency == CURRENCY_COINS:
		push_warning("EconomyManager: chips cash out to Ex-Coins only, never Coins.")
		return false
	if from_currency == CURRENCY_COINS:
		var cost := int(ceil(amount * FX_BUY_COINS_PER_100 / 100.0))
		if not CURRENCIES.has(to_currency) or to_currency == "chips":
			# Chips have their own cage rate via buy_chips.
			if to_currency == "chips":
				return await buy_chips(amount)
			return false
		if not await spend_coins(cost, "fx_buy_%s" % to_currency):
			return false
		await earn_currency(to_currency, amount, "fx_buy_%s" % to_currency)
		_record_fx_audit("fx_buy", "cat_coins", cost, to_currency, amount)
		return true
	if to_currency == CURRENCY_COINS:
		if from_currency == "chips":
			return false
		var payout := int(floor(amount * FX_SELL_COINS_PER_100 / 100.0))
		if payout <= 0:
			return false
		if not await spend_currency(from_currency, amount, "fx_sell_%s" % from_currency):
			return false
		await earn_coins(payout, "fx_sell_%s" % from_currency)
		_record_fx_audit("fx_sell", from_currency, amount, "cat_coins", payout)
		return true
	# Non-coin ↔ non-coin: sell mid then buy (never touches Ex-Coins).
	var mid := int(floor(amount * FX_SELL_COINS_PER_100 / 100.0))
	if mid <= 0:
		return false
	var target_amt := int(floor(mid * 100.0 / FX_BUY_COINS_PER_100))
	if target_amt <= 0:
		return false
	if not await spend_currency(from_currency, amount, "fx_cross_out"):
		return false
	await earn_currency(to_currency, target_amt, "fx_cross_in")
	_record_fx_audit("fx_cross", from_currency, amount, to_currency, target_amt)
	return true

func _record_fx_audit(kind: String, from_c: String, from_amt: int, to_c: String, to_amt: int) -> void:
	Hope.record("currency_exchange", {
		"kind": kind, "from": from_c, "from_amount": from_amt,
		"to": to_c, "to_amount": to_amt,
		"buy_rate_per_100": CHIP_BUY_COINS_PER_100 if to_c == "chips" else FX_BUY_COINS_PER_100,
		"cashout_ex_per_100": CHIP_TO_EX_PER_100 if from_c == "chips" else 0,
		"sell_rate_per_100": FX_SELL_COINS_PER_100,
	})

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

## Local prestige grant — boss/quest kills must not hang offline on Nakama push.
func earn_prestige_local(amount: int, source: String = "gameplay") -> void:
	if amount <= 0:
		return
	_lifetime_prestige += amount
	earn_currency_local("prestige", amount, source)

func can_spend_coins(amount: int) -> bool:
	return amount > 0 and get_spendable_coins() >= amount

## Debit Ex-Coins first, then Coins. Keeps promotional winnings circulating
## without ever converting them back into purchasable Coins.
func _debit_spendable(amount: int, destination: String) -> Dictionary:
	var from_ex := mini(amount, get_ex_coins())
	var from_coins := amount - from_ex
	if from_ex > 0:
		_adjust_balance(CURRENCY_EX_COINS, -from_ex)
		_record_transaction(CURRENCY_EX_COINS, -from_ex, destination, "spend")
	if from_coins > 0:
		_adjust_balance(CURRENCY_COINS, -from_coins)
		_record_transaction(CURRENCY_COINS, -from_coins, destination, "spend")
	return {"ex_coins": from_ex, "cat_coins": from_coins}

## Synchronous local debit (no server round-trip). Prefer await spend_coins.
func spend_coins_local(amount: int, destination: String = "unknown") -> bool:
	if amount <= 0 or not can_spend_coins(amount):
		if amount > 0:
			emit_signal("insufficient_funds", CURRENCY_COINS, amount, get_spendable_coins())
		return false
	_debit_spendable(amount, destination)
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
	if not can_spend_coins(amount):
		emit_signal("insufficient_funds", CURRENCY_COINS, amount, get_spendable_coins())
		return false
	var parts := _debit_spendable(amount, destination)
	if int(parts.ex_coins) > 0:
		await _push_transaction_to_server(CURRENCY_EX_COINS, -int(parts.ex_coins), destination, "spend")
	if int(parts.cat_coins) > 0:
		await _push_transaction_to_server(CURRENCY_COINS, -int(parts.cat_coins), destination, "spend")
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
	if not _balances.has(currency):
		_balances[currency] = 0
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
		_balances[CURRENCY_EX_COINS] = 0
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
		if not _balances.has(CURRENCY_EX_COINS):
			_balances[CURRENCY_EX_COINS] = 0
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
