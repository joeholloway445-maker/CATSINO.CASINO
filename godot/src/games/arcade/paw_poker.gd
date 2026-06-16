extends Node
class_name PawPoker
# Arcade poker variant — simplified 3-card hand evaluation, server-validated

signal hand_dealt(cards: Array[Dictionary])
signal result_received(hand_name: String, payout: int)
signal error_occurred(message: String)

const SUITS = ["🐾", "🐱", "🌟", "🎭"]
const VALUES = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

var _bet: int = 0
var _phase: String = "idle"
var _current_hand: Array[Dictionary] = []
var _held_indices: Array[int] = []

func deal(bet: int) -> void:
	if _phase not in ["idle", "result"]:
		error_occurred.emit("Already in a hand")
		return
	_bet = bet
	_held_indices = []
	_phase = "dealt"
	_call_rpc("deal", [])

func hold_toggle(index: int) -> void:
	if _phase != "dealt": return
	if index in _held_indices:
		_held_indices.erase(index)
	else:
		_held_indices.append(index)

func draw() -> void:
	if _phase != "dealt": return
	_phase = "drawing"
	_call_rpc("draw", _held_indices)

func _call_rpc(action: String, held: Array) -> void:
	var payload = JSON.stringify({"action": action, "bet": _bet, "held_indices": held})
	NetworkManager.call_rpc("play_poker", payload, _on_rpc_result)

func _on_rpc_result(result: Dictionary) -> void:
	if not result.get("success", false):
		error_occurred.emit(result.get("error", "Unknown error"))
		_phase = "idle"
		return

	var cards_raw = result.get("cards", [])
	_current_hand = []
	for c in cards_raw:
		_current_hand.append({
			"suit": SUITS[c.get("suit", 0) % 4],
			"value": VALUES[c.get("value", 0) % 13],
			"index": c.get("index", 0),
		})

	if result.has("hand_name"):
		_phase = "result"
		result_received.emit(result.get("hand_name", ""), result.get("payout", 0))
	else:
		_phase = "dealt"
		hand_dealt.emit(_current_hand)

func get_held_indices() -> Array[int]:
	return _held_indices.duplicate()

func get_current_hand() -> Array[Dictionary]:
	return _current_hand.duplicate()
