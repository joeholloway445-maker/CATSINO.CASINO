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
static var _holdem: Dictionary = {}
static var _combat: Dictionary = {}

static func resolve(rpc_id: String, payload: Variant) -> Dictionary:
	var data := _as_dict(payload)
	match rpc_id:
		"spin_slots":
			return await _spin_slots(data)
		"play_blackjack":
			return await _blackjack(data)
		"play_poker":
			return await _poker_hand(data)
		"play_holdem":
			return await _holdem_hand(data)
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
		"combat_action":
			return await _combat_action(data)
		"get_wallet":
			return _get_wallet()
		"find_match", "find_moba_match":
			return {"success": true, "ok": true, "match_id": "", "created": false, "practice": true}
		"get_active_tournaments", "get_tournaments":
			return {"success": true, "tournaments": [], "ok": true}
		"join_tournament":
			return {"success": true, "ok": true, "local": true, "message": "Use local cups offline"}
		"submit_score":
			return {"success": true, "ok": true, "score": int(data.get("score", 0))}
		"quest_action", "get_quests":
			return {"success": true, "ok": true, "quests": []}
		"summon_companion":
			return await _summon_companion_offline(data)
		"feed_companion", "evolve_companion", "get_my_companions":
			return {"success": true, "ok": true, "offline": true, "companions": []}
		"daily_bonus", "claim_daily_bonus":
			return await _daily_bonus_offline()
		_:
			return {"success": false, "error": "Offline: %s unavailable" % rpc_id}

static func supports(rpc_id: String) -> bool:
	return rpc_id in [
		"spin_slots", "play_blackjack", "play_poker", "play_holdem",
		"draw_fortune", "buy_scratch_card", "predict_match",
		"submit_puzzle_score", "start_race", "combat_action",
		"get_wallet", "find_match", "find_moba_match",
		"get_active_tournaments", "get_tournaments", "join_tournament",
		"submit_score", "quest_action", "get_quests",
		"summon_companion", "feed_companion", "evolve_companion", "get_my_companions",
		"daily_bonus", "claim_daily_bonus",
	]

static func _get_wallet() -> Dictionary:
	var coins := 0
	var gems := 0
	if EconomyManager:
		coins = EconomyManager.get_coins()
		gems = EconomyManager.get_gems()
	return {
		"success": true,
		"ok": true,
		"coins": coins,
		"cat_coins": coins,
		"gems": gems,
		"balances": {"coins": coins, "cat_coins": coins, "gems": gems},
	}

static func _daily_bonus_offline() -> Dictionary:
	if EconomyManager and EconomyManager.has_method("claim_daily_bonus"):
		var amount: int = await EconomyManager.claim_daily_bonus()
		return {"success": true, "ok": true, "reward": amount, "coins_granted": amount}
	_pay(500, "daily_bonus_offline")
	return {"success": true, "ok": true, "reward": 500, "coins_granted": 500}

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
		"segment_index": segment,
		"multiplier": mult,
		"payout": payout,
	}

# ── Scratch card ──────────────────────────────────────────────────────────────

const SCRATCH_SYMBOLS := ["🐱", "🌟", "🎭", "🐾", "💎", "🎰"]
const SCRATCH_PAYOUTS := {"🐱": 2, "🌟": 3, "🎭": 3, "🐾": 5, "💎": 10, "🎰": 20}

static func _buy_scratch_card(data: Dictionary) -> Dictionary:
	var bet := int(data.get("bet", 50))
	var spent := await _spend(bet, "scratch_buy_offline")
	if not spent.get("success", false):
		return spent
	var cells: Array = []
	for _i in 9:
		cells.append(SCRATCH_SYMBOLS[randi() % SCRATCH_SYMBOLS.size()])
	if randf() < 0.28:
		var sym: String = SCRATCH_SYMBOLS[randi() % SCRATCH_SYMBOLS.size()]
		var idxs := [0, 1, 2, 3, 4, 5, 6, 7, 8]
		idxs.shuffle()
		for k in 3:
			cells[idxs[k]] = sym
	var counts: Dictionary = {}
	for s in cells:
		counts[s] = int(counts.get(s, 0)) + 1
	var payout := 0
	for sym in counts:
		if int(counts[sym]) >= 3:
			payout = int(bet * int(SCRATCH_PAYOUTS.get(sym, 1)))
			break
	_pay(payout, "scratch_win_offline")
	return {"success": true, "cells": cells, "bet": bet, "payout": payout, "is_win": payout > 0, "server_wallet": true}

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
	if bet > 0:
		var spent := await _spend(bet, "race_entry_offline")
		if not spent.get("success", false):
			return spent
	elif bet < 0:
		return {"success": false, "error": "Invalid bet"}
	var racers: Array = [{"id": "YOU", "time": randf_range(8.0, 12.0)}]
	for i in 7:
		racers.append({"id": "npc_%d" % (i + 1), "time": randf_range(8.0, 14.0)})
	racers.sort_custom(func(a, b): return float(a.time) < float(b.time))
	var position := 1
	var results: Array = []
	for i in racers.size():
		var r: Dictionary = racers[i]
		r["position"] = i + 1
		r["time"] = "%.2f" % float(r.time)
		results.append(r)
		if str(r.id) == "YOU":
			position = i + 1
	var mult := {1: 3.0, 2: 1.5, 3: 1.0}.get(position, 0.0)
	var payout := int(floor(bet * float(mult)))
	_pay(payout, "race_win_offline")
	return {
		"success": true,
		"position": position,
		"payout": payout,
		"results": results,
		"frame_id": str(data.get("frame_id", "basic")),
		"server_wallet": true,
	}

# ── Holdem ────────────────────────────────────────────────────────────────────

static func _holdem_hand(data: Dictionary) -> Dictionary:
	var action := str(data.get("action", ""))
	var bet := int(data.get("bet", 0))
	match action:
		"deal":
			if bet < 10:
				return {"success": false, "error": "Invalid bet"}
			var spent := await _spend(bet, "holdem_deal")
			if not spent.get("success", false):
				return spent
			var deck := _shuffle_deck()
			_holdem = {
				deck = deck,
				hole = [deck[0], deck[1]],
				community = [deck[2], deck[3], deck[4], deck[5], deck[6]],
				bet = bet,
			}
			return {
				"success": true,
				"hole_cards": _holdem.hole,
				"community_cards": [deck[2], deck[3], deck[4], -1, -1],
			}
		"fold":
			_holdem.clear()
			return {"success": true, "outcome": "fold", "payout": 0, "community_cards": []}
		"call":
			if _holdem.is_empty():
				return {"success": false, "error": "No active hand"}
			var all_cards: Array = _holdem.hole + _holdem.community
			var hand_name := _evaluate_poker(all_cards.slice(0, 5))
			# Use best-effort 5 from 7: take first 5 for offline simplicity + pair bonus
			var mult := int(POKER_PAYOUTS.get(hand_name, 0))
			var payout: int = int(_holdem.bet) * mult
			_pay(payout, "holdem_win")
			var community: Array = _holdem.community
			_holdem.clear()
			return {
				"success": true,
				"outcome": "win" if payout > 0 else "lose",
				"hand_name": hand_name,
				"payout": payout,
				"community_cards": community,
			}
		_:
			return {"success": false, "error": "Unknown action"}

# ── Combat ────────────────────────────────────────────────────────────────────

static func _combat_action(data: Dictionary) -> Dictionary:
	var action := str(data.get("action", ""))
	if action == "start" or (action == "" and not _combat.get("active", false)):
		var bet := int(data.get("bet", 0))
		if bet > 0:
			var spent := await _spend(bet, "combat_entry")
			if not spent.get("success", false):
				return spent
		_combat = {
			active = true,
			bet = bet,
			player_hp = 250,
			opponent_hp = 280,
			player_pow = 90,
			opponent_pow = 100,
			player_res = 80,
			opponent_res = 90,
		}
		return {
			"success": true,
			"status": "active",
			"state": _combat.duplicate(),
			"player_hp": 250,
			"opponent_hp": 280,
		}
	var move := str(data.get("move", "light"))
	if not _combat.get("active", false):
		return {"success": false, "error": "No active combat"}
	var ai_move := ["light", "heavy", "tech"][randi() % 3]
	var mult_table := {
		"light": {"light": 1.0, "heavy": 1.5, "tech": 0.5},
		"heavy": {"light": 0.5, "heavy": 1.0, "tech": 1.5},
		"tech": {"light": 1.5, "heavy": 0.5, "tech": 1.0},
	}
	var p_mult: float = float(mult_table.get(move, {}).get(ai_move, 1.0))
	var a_mult: float = float(mult_table.get(ai_move, {}).get(move, 1.0))
	var player_dmg := maxi(1, int(_combat.player_pow * p_mult - _combat.opponent_res * 0.5))
	var ai_dmg := maxi(1, int(_combat.opponent_pow * a_mult - _combat.player_res * 0.5))
	_combat.opponent_hp -= player_dmg
	_combat.player_hp -= ai_dmg
	if _combat.player_hp <= 0 or _combat.opponent_hp <= 0:
		var won: bool = _combat.opponent_hp <= 0 and _combat.player_hp > 0
		var payout := int(_combat.bet) * 2 if won else 0
		_pay(payout, "combat_win")
		_combat.clear()
		return {
			"success": true,
			"status": "player_win" if won else "opponent_win",
			"outcome": "player_wins" if won else "opponent_wins",
			"player_damage": ai_dmg,
			"opponent_damage": player_dmg,
			"opponent_move": ai_move,
			"payout": payout,
			"server_wallet": true,
		}
	return {
		"success": true,
		"status": "active",
		"state": _combat.duplicate(),
		"opponent_move": ai_move,
		"player_damage": ai_dmg,
		"opponent_damage": player_dmg,
		"player_hp": _combat.player_hp,
		"opponent_hp": _combat.opponent_hp,
	}
