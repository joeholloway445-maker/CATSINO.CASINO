extends SceneTree
## Headless smoke: Subliminal never auto-spawns; storage/creator gates;
## marketplace + trade audit; house-favorable chip FX.
## Run: godot --headless --path godot -s res://src/dev/subliminal_economy_smoke.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[subliminal_economy_smoke] start")
	var root := self.root
	var npc_mgr: Node = root.get_node_or_null("NPCManager")
	var sub: Node = root.get_node_or_null("SubliminalManager")
	var economy: Node = root.get_node_or_null("EconomyManager")
	var market: Node = root.get_node_or_null("Marketplace")
	var trade: Node = root.get_node_or_null("TradeManager")
	var profile: Node = root.get_node_or_null("PlayerProfile")

	var fail := func(msg: String) -> void:
		push_error("[subliminal_economy_smoke] FAIL: " + msg)
		print("[subliminal_economy_smoke] RESULT=FAIL")
		quit(1)

	if npc_mgr == null or sub == null or economy == null or market == null or trade == null:
		fail.call("missing autoload(s)")
		return

	# Wait one frame so NPCManager can finish world_loaded init if districts exist.
	await process_frame
	await process_frame

	# 1) Subliminal auto-spawn hard lock
	var sub_count: int = int(npc_mgr.call("_npc_count_for_layer", "subliminal"))
	print("[subliminal_economy_smoke] subliminal_npc_count=", sub_count)
	if sub_count != 0:
		fail.call("subliminal auto-spawn count must be 0, got %d" % sub_count)
		return
	npc_mgr.call("preload_layer", "subliminal")
	var loaded: Dictionary = npc_mgr.get("_loaded_npcs")
	var sub_loaded: Dictionary = loaded.get("subliminal", {})
	print("[subliminal_economy_smoke] subliminal_loaded=", sub_loaded.size())
	if sub_loaded.size() != 0:
		fail.call("preload_layer(subliminal) must leave empty roster")
		return

	# 2) Ambient place requires creator sub
	var denied: Dictionary = sub.call("place_ambient_npc", "barista")
	print("[subliminal_economy_smoke] ambient_without_sub_empty=", denied.is_empty())
	if not denied.is_empty():
		fail.call("ambient NPC must be denied without creator sub")
		return

	# Force creator sub window for the positive path
	sub.set("_creator_sub_until", int(Time.get_unix_time_from_system()) + 3600)
	var placed: Dictionary = sub.call("place_ambient_npc", "barista", "Test Barista")
	print("[subliminal_economy_smoke] ambient_with_sub=", placed.get("id", ""))
	if placed.is_empty() or bool(placed.get("auto_spawned", true)):
		fail.call("creator-gated ambient place failed")
		return
	sub.call("clear_all_ambient")

	# 3) Storage caps + expansion
	var free_cap: int = int(sub.call("storage_capacity"))
	print("[subliminal_economy_smoke] storage_cap_creator=", free_cap)
	# Drop creator to measure free cap
	sub.set("_creator_sub_until", 0)
	var base_cap: int = int(sub.call("storage_capacity"))
	print("[subliminal_economy_smoke] storage_cap_free=", base_cap)
	if base_cap != int(sub.get("FREE_STORAGE_SLOTS")):
		fail.call("free storage cap mismatch")
		return

	# Fill to capacity then refuse
	for i in range(base_cap):
		var ok_store: bool = sub.call("store_item", {"id": "smoke_item_%d" % i, "name": "Smoke %d" % i})
		if not ok_store:
			fail.call("failed to fill storage slot %d" % i)
			return
	var overflow: bool = sub.call("store_item", {"id": "overflow", "name": "Nope"})
	print("[subliminal_economy_smoke] overflow_rejected=", not overflow)
	if overflow:
		fail.call("storage should reject when full")
		return

	# Seed coins for expansion purchase
	economy.call("add_coins_local", 20000, "smoke_seed")
	var expanded: bool = await sub.call("buy_storage_expansion")
	print("[subliminal_economy_smoke] expansion=", expanded, " cap=", sub.call("storage_capacity"))
	if not expanded:
		fail.call("storage expansion purchase failed")
		return

	# 4) House-favorable chip FX
	var buy_cost: int = int(economy.call("chip_buy_coin_cost", 100))
	var sell_pay: int = int(economy.call("chip_sell_coin_payout", 100))
	print("[subliminal_economy_smoke] chip_buy_100=", buy_cost, " sell_100=", sell_pay)
	if buy_cost <= 100 or sell_pay >= 100 or buy_cost <= sell_pay:
		fail.call("chip FX must be house-favorable (buy>100>sell)")
		return
	var chips_before: int = int(economy.call("get_balance", "chips"))
	var coins_before: int = int(economy.call("get_coins"))
	if not economy.call("buy_chips_local", 100):
		fail.call("buy_chips_local failed")
		return
	if int(economy.call("get_balance", "chips")) != chips_before + 100:
		fail.call("chips not credited on buy")
		return
	if int(economy.call("get_coins")) != coins_before - buy_cost:
		fail.call("coins not debited at house buy rate")
		return
	if not economy.call("sell_chips_local", 100):
		fail.call("sell_chips_local failed")
		return
	if int(economy.call("get_coins")) != coins_before - buy_cost + sell_pay:
		fail.call("sell payout not at house sell rate")
		return

	# 5) Trade audit trail (propose + cancel)
	if profile:
		profile.set("username", "SmokeTrader")
	var offer: Dictionary = await trade.call("propose_trade", "OtherPlayer", [], 50, [], 0)
	print("[subliminal_economy_smoke] trade_offer=", offer.get("id", ""))
	if offer.is_empty():
		fail.call("propose_trade failed")
		return
	var cancelled: bool = await trade.call("cancel_trade", str(offer.id))
	var audit: Array = trade.call("audit_log", 10)
	print("[subliminal_economy_smoke] trade_cancel=", cancelled, " audit_rows=", audit.size())
	if not cancelled or audit.size() < 2:
		fail.call("trade audit incomplete")
		return

	# 6) Marketplace audit API present
	var m_audit: Array = market.call("audit_log", 5)
	print("[subliminal_economy_smoke] marketplace_audit_ok=", m_audit is Array)
	var vendors: Array = market.get("VENDORS")
	print("[subliminal_economy_smoke] vendors=", vendors.size())
	if vendors.size() < 5:
		fail.call("marketplace vendors missing")
		return

	print("[subliminal_economy_smoke] RESULT=PASS")
	quit(0)
