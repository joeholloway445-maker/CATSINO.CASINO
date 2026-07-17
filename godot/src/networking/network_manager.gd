extends Node
# Nakama RPC dispatcher — delegates to AccountManager's authenticated client
# and session. Offline / unauthenticated casino RPCs resolve via OfflineCasino.

signal connected()
signal disconnected()
signal rpc_error(code: int, message: String)

## Map legacy / mismatched client RPC ids onto the registered Nakama names.
const RPC_ALIASES := {
	"economy/get_balances": "get_wallet",
	"economy/claim_daily_bonus": "daily_bonus",
	"get_tournaments": "get_active_tournaments",
	"claim_daily_bonus": "daily_bonus",
}

## Client-only bookkeeping RPCs that have no Nakama equivalent — soft-succeed.
const SOFT_SUCCESS_RPCS := [
	"economy/record_transaction",
	"economy/transfer",
]

func _get_client():
	return AccountManager.get_nakama_client() if AccountManager else null

func _get_session():
	return AccountManager.get_nakama_session() if AccountManager else null

func _resolve_rpc_id(rpc_id: String) -> String:
	return str(RPC_ALIASES.get(rpc_id, rpc_id))

## Gate 8: clients send `board_id`; Nakama historically expected `leaderboard`.
## Mirror both keys on outbound payloads so either side can read either name.
func _normalize_payload(rpc_id: String, payload: Variant) -> Variant:
	if not payload is Dictionary:
		return payload
	var p: Dictionary = (payload as Dictionary).duplicate(true)
	if rpc_id in ["get_leaderboard", "submit_score"]:
		if p.has("board_id") and not p.has("leaderboard"):
			p["leaderboard"] = p["board_id"]
		elif p.has("leaderboard") and not p.has("board_id"):
			p["board_id"] = p["leaderboard"]
		if not p.has("leaderboard") and not p.has("board_id"):
			p["leaderboard"] = "global_wins"
			p["board_id"] = "global_wins"
	return p

func call_rpc(rpc_id: String, payload: Variant, callback: Callable) -> void:
	if rpc_id in SOFT_SUCCESS_RPCS:
		callback.call({"success": true, "ok": true})
		return
	var resolved_id := _resolve_rpc_id(rpc_id)
	var normalized: Variant = _normalize_payload(resolved_id, payload)
	var payload_str: String = JSON.stringify(normalized) if normalized is Dictionary or normalized is Array else str(normalized)
	var client = _get_client()
	var session = _get_session()
	if not client or not session or session.is_expired():
		if OfflineCasino.supports(resolved_id):
			var local: Dictionary = await OfflineCasino.resolve(resolved_id, normalized if normalized is Dictionary else {})
			if local.get("error") and not local.get("success", false):
				rpc_error.emit(401, str(local.get("error", "Not authenticated")))
			callback.call(_normalize_response(resolved_id, local))
			return
		rpc_error.emit(401, "Not authenticated")
		callback.call({"success": false, "error": "Not authenticated", "ok": false})
		return

	var result = await client.rpc_async(session, resolved_id, payload_str)
	if result.is_exception():
		var ex = result.get_exception()
		rpc_error.emit(ex.status_code, ex.message)
		callback.call({"success": false, "error": ex.message, "ok": false})
		return

	var parsed = JSON.parse_string(result.payload)
	if parsed == null:
		callback.call({"success": false, "error": "Invalid JSON response", "ok": false})
		return

	callback.call(_normalize_response(resolved_id, parsed if parsed is Dictionary else {"value": parsed}))

func _normalize_response(rpc_id: String, data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	if not out.has("success") and not out.has("error"):
		out["success"] = true
	if out.has("ok") and not out.has("success"):
		out["success"] = bool(out.ok)
	# Leaderboard field alias — echo both names for UI callers.
	if rpc_id in ["get_leaderboard", "submit_score"]:
		if out.has("leaderboard") and not out.has("board_id"):
			out["board_id"] = out["leaderboard"]
		elif out.has("board_id") and not out.has("leaderboard"):
			out["leaderboard"] = out["board_id"]
		if not out.has("records") and out.has("entries"):
			out["records"] = out["entries"]
	# Wallet / economy shape for EconomyManager + HUD
	if rpc_id in ["get_wallet", "daily_bonus", "earn_coins", "spend_coins"]:
		var coins := int(out.get("coins", out.get("cat_coins", 0)))
		var gems := int(out.get("gems", 0))
		out["coins"] = coins
		out["cat_coins"] = coins
		out["gems"] = gems
		if not out.has("balances"):
			out["balances"] = {"coins": coins, "gems": gems, "cat_coins": coins}
	# Fortune: accept either segment index or segment_index
	if rpc_id == "draw_fortune":
		if out.has("segment_index") and typeof(out.segment) == TYPE_STRING:
			out["segment"] = int(out.segment_index)
		elif out.has("segment") and typeof(out.segment) == TYPE_FLOAT:
			out["segment"] = int(out.segment)
	# Combat status → outcome alias
	if rpc_id == "combat_action":
		if not out.has("outcome") and out.has("status"):
			var st := str(out.status)
			if st == "player_win":
				out["outcome"] = "player_wins"
			elif st == "opponent_win":
				out["outcome"] = "opponent_wins"
		if out.has("state") and out.state is Dictionary:
			var st: Dictionary = out.state
			if not out.has("player_hp"):
				out["player_hp"] = st.get("player_hp", 0)
			if not out.has("opponent_hp"):
				out["opponent_hp"] = st.get("opponent_hp", 0)
	# Tournament list field alias
	if rpc_id in ["get_active_tournaments", "get_tournaments"]:
		var list: Array = out.get("tournaments", out.get("active", []))
		for t in list:
			if t is Dictionary and not t.has("entry_count") and t.has("participant_count"):
				t["entry_count"] = t["participant_count"]
		if not out.has("tournaments") and list.size() > 0:
			out["tournaments"] = list
	# Matchmaking — ensure success flag when only `ok` is set
	if rpc_id in ["find_match", "find_moba_match"]:
		if out.has("ok") and not out.has("success"):
			out["success"] = bool(out.ok)
		if out.has("matchId") and not out.has("match_id"):
			out["match_id"] = out["matchId"]
	return out

func is_connected_to_server() -> bool:
	return AccountManager.is_authenticated if AccountManager else false

func get_session():
	return _get_session()
