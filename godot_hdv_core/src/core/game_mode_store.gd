extends Node
## Placeholder storefront for purchasing game modes. No real payment
## processor exists yet — purchase() simulates a successful transaction and
## grants the mode immediately. Swap _process_payment() for a real
## Stripe/IAP call once a storefront backend exists; everything else
## (ownership tracking, activation) is already real and stays unchanged.

signal purchase_completed(mode_id: String, success: bool)

const GameModeData = preload("res://src/data/game_mode_data.gd")

func price_usd(mode_id: String) -> float:
	var mode := GameModeData.by_id(mode_id)
	if mode.get("persistent", false):
		return 0.0 if mode_id == "persistent_aware" else 9.99
	return 14.99

func purchase(mode_id: String) -> bool:
	if GameModeData.by_id(mode_id).is_empty():
		purchase_completed.emit(mode_id, false)
		return false
	if GameModeManager.owns(mode_id):
		purchase_completed.emit(mode_id, true)
		return true
	var success := _process_payment(mode_id)
	if success:
		GameModeManager.grant(mode_id)
	purchase_completed.emit(mode_id, success)
	return success

func _process_payment(_mode_id: String) -> bool:
	return true
