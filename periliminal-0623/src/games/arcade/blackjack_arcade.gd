extends Node
class_name BlackjackArcade
# Godot-side blackjack controller — sends actions to Supabase RPC

signal cards_updated(player_cards: Array, dealer_cards: Array, player_total: int)
signal game_ended(result: String, payout: int)
signal error_occurred(message: String)

var _bet: int = 0
var _game_state: Dictionary = {}
var _phase: String = "idle"

func deal(bet: int) -> void:
	if _phase != "idle":
		error_occurred.emit("Game already in progress")
		return
	_bet = bet
	_phase = "active"
	_send_action("deal", bet, {})

func hit() -> void:
	if _phase != "active": return
	_send_action("hit", 0, _game_state)

func stand() -> void:
	if _phase != "active": return
	_send_action("stand", 0, _game_state)

func double_down() -> void:
	if _phase != "active": return
	_send_action("double", _bet, _game_state)

func _send_action(action: String, bet: int, state: Dictionary) -> void:
	var payload = JSON.stringify({
		"action": action,
		"bet": bet,
		"game_state": state,
	})
	NetworkManager.call_rpc("play_blackjack", payload, _on_result)

func _on_result(result: Dictionary) -> void:
	if not result.get("success", false):
		error_occurred.emit(result.get("error", "Server error"))
		_phase = "idle"
		return

	_game_state = result.get("game_state", {})
	var player_cards = _game_state.get("player_cards", [])
	var dealer_cards = _game_state.get("dealer_cards", [])
	var player_total = _game_state.get("player_total", 0)

	var status = result.get("status", "")
	if status in ["player_bust", "dealer_bust", "player_win", "dealer_win", "push", "blackjack"]:
		_phase = "idle"
		_game_state = {}
		game_ended.emit(status, result.get("payout", 0))
	else:
		cards_updated.emit(player_cards, dealer_cards, player_total)

func reset() -> void:
	_phase = "idle"
	_game_state = {}
	_bet = 0
