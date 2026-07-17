extends Node
## Autoloaded as "TradeManager". Player-to-player direct trades with an
## append-only audit ledger (local + Hope). Marketplace listings are
## separate (see Marketplace); this covers negotiated bilateral swaps.

signal offer_created(offer: Dictionary)
signal trade_completed(trade: Dictionary)
signal trade_cancelled(trade_id: String)

const SAVE_PATH := "user://trade_audit.json"
const MAX_AUDIT := 2000
## 2.5% house cut on the larger coin leg (basis points). House-favorable.
const TRADE_TAX_BPS := 250

## open offer_id -> offer dict (items/coins held in escrow locally)
var _offers: Dictionary = {}
## append-only audit rows
var _audit: Array = []

func _ready() -> void:
	_load()

func open_offers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o in _offers.values():
		out.append(o)
	return out

func audit_log(limit: int = 100) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var start := maxi(0, _audit.size() - limit)
	for i in range(start, _audit.size()):
		out.append(_audit[i])
	return out

## Propose a bilateral trade. Offered items/coins enter escrow immediately.
func propose_trade(
	to_player: String,
	offer_items: Array = [],
	offer_coins: int = 0,
	ask_items: Array = [],
	ask_coins: int = 0
) -> Dictionary:
	var counterparty := to_player.strip_edges()
	if counterparty == "" or counterparty == PlayerProfile.username:
		NotificationUI.notify_error("Pick another player to trade with.")
		return {}
	if offer_coins < 0 or ask_coins < 0:
		return {}
	if offer_items.is_empty() and offer_coins <= 0 and ask_items.is_empty() and ask_coins <= 0:
		NotificationUI.notify_error("Trade needs at least one side with value.")
		return {}
	if offer_coins > 0 and EconomyManager.get_coins() < offer_coins:
		NotificationUI.notify_error("Not enough coins to fund this offer.")
		return {}

	var escrowed: Array = []
	for item in offer_items:
		if not item is Dictionary:
			_refund_escrow(escrowed, 0)
			NotificationUI.notify_error("Offered items must be item dictionaries.")
			return {}
		var iid := str(item.get("id", ""))
		if iid == "" or not InventoryManager.remove_item(iid):
			_refund_escrow(escrowed, 0)
			NotificationUI.notify_error("Missing offered item: %s" % iid)
			return {}
		escrowed.append(item.duplicate(true))

	if offer_coins > 0 and not await EconomyManager.spend_coins(offer_coins, "trade_escrow"):
		_refund_escrow(escrowed, 0)
		return {}

	var offer := {
		"id": "trd_%d_%d" % [Time.get_ticks_msec(), randi() % 10000],
		"from": PlayerProfile.username,
		"to": counterparty,
		"offer_items": escrowed,
		"offer_coins": offer_coins,
		"ask_items": ask_items.duplicate(true),
		"ask_coins": ask_coins,
		"status": "open",
		"created_at": Time.get_datetime_string_from_system(),
		"tax_bps": TRADE_TAX_BPS,
	}
	_offers[offer.id] = offer
	_append_audit("propose", offer)
	_save()
	offer_created.emit(offer)
	Hope.record("trade_propose", {
		"id": offer.id, "to": counterparty,
		"offer_coins": offer_coins, "ask_coins": ask_coins,
		"offer_item_count": escrowed.size(),
	})
	NotificationUI.notify_info("Trade offer sent to %s." % counterparty)
	return offer

## Accept an open offer. Settles both legs, applies house tax, audits.
## Offline: when the acceptor is also the local player and the offer was
## from them (self-test), coins/items round-trip through escrow rules.
func accept_trade(trade_id: String) -> bool:
	var offer: Dictionary = _offers.get(trade_id, {})
	if offer.is_empty() or str(offer.get("status", "")) != "open":
		return false

	var ask_coins: int = int(offer.ask_coins)
	var ask_items: Array = offer.get("ask_items", [])
	var acceptor := PlayerProfile.username

	# Pull ask-side from acceptor inventory/wallet.
	var ask_escrow: Array = []
	for item in ask_items:
		if not item is Dictionary:
			_refund_escrow(ask_escrow, 0)
			return false
		var iid := str(item.get("id", ""))
		if iid != "" and not InventoryManager.remove_item(iid):
			_refund_escrow(ask_escrow, 0)
			NotificationUI.notify_error("Missing asked item: %s" % iid)
			return false
		ask_escrow.append(item.duplicate(true))

	if ask_coins > 0 and not await EconomyManager.spend_coins(ask_coins, "trade_pay_%s" % trade_id):
		_refund_escrow(ask_escrow, 0)
		return false

	var coin_volume: int = maxi(int(offer.offer_coins), ask_coins)
	var tax: int = int(ceil(coin_volume * TRADE_TAX_BPS / 10000.0)) if coin_volume > 0 else 0

	# Acceptor receives offer (minus tax when offer had coins).
	var offer_net: int = maxi(0, int(offer.offer_coins) - (tax if int(offer.offer_coins) > 0 else 0))
	if offer_net > 0:
		await EconomyManager.earn_coins(offer_net, "trade_recv_%s" % trade_id)
	for item in offer.offer_items:
		if item is Dictionary:
			InventoryManager.add_item(item)

	# Proposer receives ask (minus tax when only ask had coins). Offline
	# settlement credits the local player when they are the proposer.
	var ask_net: int = ask_coins
	if tax > 0 and int(offer.offer_coins) <= 0:
		ask_net = maxi(0, ask_coins - tax)
	if str(offer.from) == PlayerProfile.username:
		if ask_net > 0:
			await EconomyManager.earn_coins(ask_net, "trade_recv_%s" % trade_id)
		for item in ask_escrow:
			InventoryManager.add_item(item)
	# Remote proposer payout is settled by the backend; still fully audited.

	offer["status"] = "completed"
	offer["completed_at"] = Time.get_datetime_string_from_system()
	offer["tax_coins"] = tax
	offer["accepted_by"] = acceptor
	_offers.erase(trade_id)
	_append_audit("complete", offer)
	_save()
	trade_completed.emit(offer)
	Hope.record("trade_complete", {
		"id": trade_id,
		"from": offer.from,
		"to": offer.to,
		"tax": tax,
		"offer_coins": offer.offer_coins,
		"ask_coins": ask_coins,
	})
	NotificationUI.notify_win("Trade settled (house tax %d 🪙)." % tax)
	return true

func cancel_trade(trade_id: String) -> bool:
	var offer: Dictionary = _offers.get(trade_id, {})
	if offer.is_empty() or str(offer.get("status", "")) != "open":
		return false
	if str(offer.from) != PlayerProfile.username:
		NotificationUI.notify_error("Only the proposer can cancel.")
		return false
	_refund_escrow(offer.offer_items, int(offer.offer_coins))
	offer["status"] = "cancelled"
	offer["cancelled_at"] = Time.get_datetime_string_from_system()
	_offers.erase(trade_id)
	_append_audit("cancel", offer)
	_save()
	trade_cancelled.emit(trade_id)
	Hope.record("trade_cancel", {"id": trade_id})
	return true

func _refund_escrow(items: Array, coins: int) -> void:
	for item in items:
		if item is Dictionary:
			InventoryManager.add_item(item)
	if coins > 0:
		EconomyManager.add_coins_local(coins, "trade_escrow_refund")

func _append_audit(action: String, offer: Dictionary) -> void:
	_audit.append({
		"action": action,
		"trade_id": offer.get("id", ""),
		"from": offer.get("from", ""),
		"to": offer.get("to", ""),
		"offer_coins": offer.get("offer_coins", 0),
		"ask_coins": offer.get("ask_coins", 0),
		"tax_coins": offer.get("tax_coins", 0),
		"offer_item_count": (offer.get("offer_items", []) as Array).size(),
		"ask_item_count": (offer.get("ask_items", []) as Array).size(),
		"status": offer.get("status", ""),
		"timestamp": Time.get_datetime_string_from_system(),
	})
	while _audit.size() > MAX_AUDIT:
		_audit.pop_front()

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"offers": _offers, "audit": _audit}))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		if d.get("offers") is Dictionary:
			_offers = d.offers
		if d.get("audit") is Array:
			_audit = d.audit
