class_name OfflineCasino
## Client-side casino resolvers for offline / unauthenticated play.
## Mirrors Nakama RPC payout rules so blackjack, slots, and poker work
## without a live host. Wallet changes go through EconomyManager.

const SLOT_SYMBOLS := ["🐱", "🌟", "🎭", "🐾", "💎", "🎰", "⭐", "🔔"]
const SLOT_WEIGHTS := [30, 20, 20, 15, 8, 4, 2, 1]
const SLOT_PAYOUTS := {
	"🐱🐱🐱": 3, "🌟🌟🌟": 5, "🎭🎭🎭": 5, "🐾🐾🐾": 8,
	"💎💎💎": 15, "🎰🎰🎰": 25, "⭐⭐⭐": 50, "🔔🔔🔔": 100,
}

const POKER_PAYOUTS := {
	"High Card": 0, "One Pair": 1, "Two Pair": 2, "Three of a Kind": 3,
	"Straight": 4, "Flush": 6, "Full House": 9, "Four of a Kind": 25,
	"Straight Flush": 50, "Royal Flush": 250,
}

static var _bj: Dictionary = {}
static var _poker: Dictionary = {}

static func resolve(rpc_id: String, payload: Variant) -> Dictionary:
	var data := _as_dict(payload)
	match rpc_id:
		"spin_slots":
			return await _spin_slots(data)
		"play_blackjack":
			return await _blackjack(data)
		"play_poker":
			return await _poker_hand(data)
		"draw_fortune":
			return await _draw_fortune(data)
		"buy_scratch_card":
			return await _buy_scratch_card(data)
		"predict_match":
			return await _predict_match(data)
		"submit_puzzle_score":
			return await _submit_puzzle_score(data)
		"start_race":
			return await _start_race(data)
		_:
			return {"success": false, "error": "Offline: %s unavailable" % rpc_id}

static func supports(rpc_id: String) -> bool:
	return rpc_id in [
		"spin_slots", "play_blackjack", "play_poker",
		"draw_fortune", "buy_scratch_card", "predict_match",
		"submit_puzzle_score", "start_race",
	]

static func _as_dict(payload: Variant) -> Dictionary:
	if payload is Dictionary:
		return payload
	if payload is String:
		var parsed = JSON.parse_string(payload)
		return parsed if parsed is Dictionary else {}
	return {}

static func _spend(bet: int, reason: String) -> Dictionary:
	if bet <= 0:
		return {"success": false, "error": "Invalid bet"}
	if not EconomyManager or not await EconomyManager.spend_coins(bet, reason):
		return {"success": false, "error": "Insufficient coins"}
	return {"success": true}

static func _pay(amount: int, reason: String) -> void:
	if amount > 0 and EconomyManager:
		EconomyManager.add_coins(amount, reason)

# ── Slots ─────────────────────────────────────────────────────────────────────

static func _spin_slots(data: Dictionary) -> Dictionary:
	var bet := int(data.get("bet", 50))
	var spent := await _spend(bet, "slot_spin_offline")
	if not spent.get("success", false):
		return spent
	var event_mult := float(data.get("multiplier", 1.0))
	var s1 := _weighted_symbol()
	var s2 := _weighted_symbol()
	var s3 := _weighted_symbol()
	var combo := "%s%s%s" % [s1, s2, s3]
	var mult := float(SLOT_PAYOUTS.get(combo, 0))
	if mult <= 0.0 and (s1 == s2 or s2 == s3):
		mult = 1.0
	mult *= maxf(event_mult, 1.0)
	var payout := int(floor(bet * mult))
	_pay(payout, "slot_win_offline")
	return {
		"success": true,
		"symbols": [s1, s2, s3],
		"multiplier": mult,
		"payout": payout,
		"is_win": payout > 0,
	}

static func _weighted_symbol() -> String:
	var total := 0
	for w in SLOT_WEIGHTS:
		total += w
	var roll := randi() % total
	var acc := 0
	for i in SLOT_WEIGHTS.size():
		acc += SLOT_WEIGHTS[i]
		if roll < acc:
			return SLOT_SYMBOLS[i]
	return SLOT_SYMBOLS[-1]

# ── Blackjack ─────────────────────────────────────────────────────────────────

static func _blackjack(data: Dictionary) -> Dictionary:
	var action := str(data.get("action", ""))
	var bet := int(data.get("bet", 0))
	match action:
		"deal":
			return await _bj_deal(bet)
		"hit":
			return _bj_hit()
		"stand", "double":
			return await _bj_finish(action == "double")
		_:
			return {"success": false, "error": "Unknown action"}

static func _bj_deal(bet: int) -> Dictionary:
	if bet < 10 or bet > 100000:
		return {"success": false, "error": "Invalid bet"}
	var spent := await _spend(bet, "blackjack_deal")
	if not spent.get("success", false):
		return spent
	var deck := _shuffle_deck()
	var player := [deck[0], deck[2]]
	var dealer := [deck[1], deck[3]]
	_bj = {deck = deck, player = player, dealer = dealer, idx = 4, bet = bet}
	var pv := _hand_value(player)
	if pv == 21:
		var payout := int(floor(bet * 2.5))
		_pay(payout, "blackjack_win")
		_bj.clear()
		return {
			"success": true,
			"player_cards": player,
			"dealer_cards": [dealer[0], -1],
			"player_value": 21,
			"dealer_value": _card_bj_value(dealer[0]),
			"outcome": "blackjack",
			"payout": payout,
		}
	return {
		"success": true,
		"player_cards": player,
		"dealer_cards": [dealer[0], -1],
		"player_value": pv,
		"dealer_value": _card_bj_value(dealer[0]),
	}

static func _bj_hit() -> Dictionary:
	if _bj.is_empty():
		return {"success": false, "error": "No active hand"}
	var deck: Array = _bj.deck
	var player: Array = _bj.player
	var dealer: Array = _bj.dealer
	var idx: int = _bj.idx
	player.append(deck[idx])
	idx += 1
	_bj.player = player
	_bj.idx = idx
	var pv := _hand_value(player)
	if pv > 21:
		_bj.clear()
		return {
			"success": true,
			"player_cards": player,
			"dealer_cards": dealer,
			"player_value": pv,
			"dealer_value": _hand_value(dealer),
			"outcome": "bust",
			"payout": 0,
		}
	return {
		"success": true,
		"player_cards": player,
		"dealer_cards": [dealer[0], -1],
		"player_value": pv,
		"dealer_value": _card_bj_value(dealer[0]),
	}

static func _bj_finish(is_double: bool) -> Dictionary:
	if _bj.is_empty():
		return {"success": false, "error": "No active hand"}
	var deck: Array = _bj.deck
	var player: Array = _bj.player
	var dealer: Array = _bj.dealer
	var idx: int = _bj.idx
	var bet: int = _bj.bet
	if is_double:
		if not await EconomyManager.spend_coins(bet, "blackjack_double"):
			return {"success": false, "error": "Insufficient coins"}
		bet *= 2
		player.append(deck[idx])
		idx += 1
	while _hand_value(dealer) < 17:
		dealer.append(deck[idx])
		idx += 1
	var pv := _hand_value(player)
	var dv := _hand_value(dealer)
	var outcome := "lose"
	var payout := 0
	if pv > 21:
		outcome = "bust"
	elif dv > 21:
		outcome = "dealer_bust"
		payout = bet * 2
	elif pv > dv:
		outcome = "win"
		payout = bet * 2
	elif pv == dv:
		outcome = "push"
		payout = bet
	_pay(payout, "blackjack_%s" % outcome)
	_bj.clear()
	return {
		"success": true,
		"player_cards": player,
		"dealer_cards": dealer,
		"player_value": pv,
		"dealer_value": dv,
		"outcome": outcome,
		"payout": payout,
	}

static func _card_bj_value(index: int) -> int:
	var v := index % 13
	if v == 0:
		return 11
	if v >= 10:
		return 10
	return v + 1

static func _hand_value(cards: Array) -> int:
	var total := 0
	var aces := 0
	for c in cards:
		var v := _card_bj_value(int(c))
		if v == 11:
			aces += 1
		total += v
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total

# ── Poker ─────────────────────────────────────────────────────────────────────

static func _poker_hand(data: Dictionary) -> Dictionary:
	var action := str(data.get("action", ""))
	var bet := int(data.get("bet", 0))
	match action:
		"deal":
			return await _poker_deal(bet)
		"draw":
			return _poker_draw(data)
		_:
			return {"success": false, "error": "Unknown action"}

static func _poker_deal(bet: int) -> Dictionary:
	if bet < 10 or bet > 50000:
		return {"success": false, "error": "Invalid bet"}
	var spent := await _spend(bet, "poker_deal")
	if not spent.get("success", false):
		return spent
	var deck := _shuffle_deck()
	var cards := deck.slice(0, 5)
	_poker = {deck = deck, cards = cards, bet = bet}
	return {"success": true, "cards": _card_dicts(cards)}

static func _poker_draw(data: Dictionary) -> Dictionary:
	if _poker.is_empty():
		return {"success": false, "error": "No active hand"}
	var held := _normalize_held(data)
	var deck: Array = _poker.deck
	var cards: Array = _poker.cards.duplicate()
	var deck_idx := 5
	for i in cards.size():
		if i >= held.size() or not held[i]:
			cards[i] = deck[deck_idx]
			deck_idx += 1
	var hand_name := _evaluate_poker(cards)
	var mult := int(POKER_PAYOUTS.get(hand_name, 0))
	var payout: int = int(_poker.bet) * mult
	_pay(payout, "poker_win")
	_poker.clear()
	return {
		"success": true,
		"cards": _card_dicts(cards),
		"hand_name": hand_name,
		"payout": payout,
		"multiplier": mult,
	}

static func _normalize_held(data: Dictionary) -> Array:
	# poker.gd sends bool array; paw_poker sends held_indices int array.
	if data.has("held") and data.held is Array:
		var out: Array = []
		for v in data.held:
			out.append(bool(v))
		while out.size() < 5:
			out.append(false)
		return out
	var held_indices: Array = data.get("held_indices", [])
	var flags := [false, false, false, false, false]
	for idx in held_indices:
		var i := int(idx)
		if i >= 0 and i < 5:
			flags[i] = true
	return flags

static func _card_dicts(cards: Array) -> Array:
	var out: Array = []
	for c in cards:
		var idx := int(c)
		out.append({"index": idx, "value": idx % 13, "suit": int(idx / 13)})
	return out

static func _evaluate_poker(cards: Array) -> String:
	var values: Array = []
	var suits: Array = []
	for c in cards:
		var idx := int(c)
		values.append(idx % 13)
		suits.append(int(idx / 13))
	values.sort()
	var value_counts := {}
	for v in values:
		value_counts[v] = int(value_counts.get(v, 0)) + 1
	var counts: Array = value_counts.values()
	counts.sort()
	counts.reverse()
	var is_flush: bool = suits[0] == suits[1] and suits[1] == suits[2] and suits[2] == suits[3] and suits[3] == suits[4]
	var unique := {}
	for v in values:
		unique[v] = true
	var is_straight: bool = values[4] - values[0] == 4 and unique.size() == 5
	var is_royal := values == [0, 9, 10, 11, 12]
	if is_flush and is_royal:
		return "Royal Flush"
	if is_flush and is_straight:
		return "Straight Flush"
	if counts.size() > 0 and counts[0] == 4:
		return "Four of a Kind"
	if counts.size() > 1 and counts[0] == 3 and counts[1] == 2:
		return "Full House"
	if is_flush:
		return "Flush"
	if is_straight or is_royal:
		return "Straight"
	if counts.size() > 0 and counts[0] == 3:
		return "Three of a Kind"
	if counts.size() > 1 and counts[0] == 2 and counts[1] == 2:
		return "Two Pair"
	if counts.size() > 0 and counts[0] == 2:
		return "One Pair"
	return "High Card"

static func _shuffle_deck() -> Array:
	var deck: Array = []
	for i in 52:
		deck.append(i)
	for i in range(51, 0, -1):
		var j := randi() % (i + 1)
		var tmp = deck[i]
		deck[i] = deck[j]
		deck[j] = tmp
	return deck

# ── Fortune wheel ─────────────────────────────────────────────────────────────

const FORTUNE_MULTS := [0.0, 1.0, 1.0, 1.5, 0.0, 1.5, 2.0, 0.0, 2.0, 3.0, 5.0, 10.0]

static func _draw_fortune(data: Dictionary) -> Dictionary:
	var bet := int(data.get("bet", 50))
	var spent := await _spend(bet, "fortune_spin_offline")
	if not spent.get("success", false):
		return spent
	var segment := randi() % FORTUNE_MULTS.size()
	var mult := float(FORTUNE_MULTS[segment])
	var payout := int(floor(bet * mult))
	_pay(payout, "fortune_win_offline")
	return {
		"success": true,
		"segment": segment,
		"multiplier": mult,
		"payout": payout,
	}

# ── Scratch card ──────────────────────────────────────────────────────────────

const SCRATCH_SYMBOLS := ["🐱", "🌟", "🎭", "🐾", "💎", "🎰"]

static func _buy_scratch_card(data: Dictionary) -> Dictionary:
	var bet := int(data.get("bet", 50))
	var spent := await _spend(bet, "scratch_buy_offline")
	if not spent.get("success", false):
		return spent
	var cells: Array = []
	for _i in 9:
		cells.append(SCRATCH_SYMBOLS[randi() % SCRATCH_SYMBOLS.size()])
	# Bias a mild 3-of-a-kind chance so offline play feels alive (~28%).
	if randf() < 0.28:
		var sym: String = SCRATCH_SYMBOLS[randi() % SCRATCH_SYMBOLS.size()]
		var idxs := [0, 1, 2, 3, 4, 5, 6, 7, 8]
		idxs.shuffle()
		for k in 3:
			cells[idxs[k]] = sym
	return {"success": true, "cells": cells, "bet": bet}

# ── Sports prediction ─────────────────────────────────────────────────────────

static func _predict_match(data: Dictionary) -> Dictionary:
	var bet := int(data.get("bet", 50))
	var pick := str(data.get("pick", "home"))
	var spent := await _spend(bet, "paw_ball_bet_offline")
	if not spent.get("success", false):
		return spent
	var home_score := randi_range(0, 5)
	var away_score := randi_range(0, 5)
	var winner := "draw"
	if home_score > away_score:
		winner = "home"
	elif away_score > home_score:
		winner = "away"
	var payout := 0
	if pick == winner:
		payout = bet * (3 if winner == "draw" else 2)
		_pay(payout, "paw_ball_win_offline")
	return {
		"success": true,
		"home_score": home_score,
		"away_score": away_score,
		"winner": winner,
		"payout": payout,
	}

# ── Puzzle score ──────────────────────────────────────────────────────────────

static func _submit_puzzle_score(data: Dictionary) -> Dictionary:
	var bet := int(data.get("bet", 15))
	var score := int(data.get("score", 0))
	var spent := await _spend(bet, "puzzle_entry_offline")
	if not spent.get("success", false):
		return spent
	var mult := 0.0
	if score >= 500:
		mult = 2.0
	elif score >= 300:
		mult = 1.5
	elif score >= 150:
		mult = 1.0
	elif score >= 50:
		mult = 0.5
	var payout := int(floor(bet * mult))
	_pay(payout, "puzzle_win_offline")
	return {"success": true, "score": score, "payout": payout, "multiplier": mult}

# ── Racing (quick-result) ─────────────────────────────────────────────────────

static func _start_race(data: Dictionary) -> Dictionary:
	var bet := int(data.get("bet", 50))
	var spent := await _spend(bet, "race_entry_offline")
	if not spent.get("success", false):
		return spent
	var position := randi_range(1, 8)
	var mult := {1: 3.0, 2: 1.5, 3: 1.0}.get(position, 0.0)
	var payout := int(floor(bet * float(mult)))
	_pay(payout, "race_win_offline")
	return {
		"success": true,
		"position": position,
		"payout": payout,
		"frame_id": str(data.get("frame_id", "basic")),
	}
