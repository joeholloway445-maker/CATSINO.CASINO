extends Node
## Storefront for purchasing game modes, priced in gems (the existing
## premium soft currency from EconomyManager) — not real money. Catsino has
## no real-money trading; gems are earned or bought the same way as any
## other premium-currency game, same as cat_coins are earned through play.

signal purchase_completed(mode_id: String, success: bool)

const GameModeData = preload("res://src/data/game_mode_data.gd")

func price_gems(mode_id: String) -> int:
	var mode := GameModeData.by_id(mode_id)
	if mode.get("persistent", false):
		return 0 if mode_id == "persistent_aware" else 1500
	return 2200

func purchase(mode_id: String) -> bool:
	if GameModeData.by_id(mode_id).is_empty():
		purchase_completed.emit(mode_id, false)
		return false
	if GameModeManager.owns(mode_id):
		purchase_completed.emit(mode_id, true)
		return true
	var cost := price_gems(mode_id)
	var success := cost == 0 or EconomyManager.spend_gems(cost, "game_mode:" + mode_id)
	if success:
		GameModeManager.grant(mode_id)
	purchase_completed.emit(mode_id, success)
	return success
