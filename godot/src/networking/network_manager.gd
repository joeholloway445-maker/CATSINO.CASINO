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

func call_rpc(rpc_id: String, payload: Variant, callback: Callable) -> void:
	if rpc_id in SOFT_SUCCESS_RPCS:
		callback.call({"success": true, "ok": true})
		return
	var resolved_id := _resolve_rpc_id(rpc_id)
	var payload_str: String = JSON.stringify(payload) if payload is Dictionary or payload is Array else str(payload)
	var client = _get_client()
	var session = _get_session()
	if not client or not session or session.is_expired():
		if OfflineCasino.supports(resolved_id):
			var local: Dictionary = await OfflineCasino.resolve(resolved_id, payload)
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
	return out

func is_connected_to_server() -> bool:
	return AccountManager.is_authenticated if AccountManager else false

func get_session():
	return _get_session()
