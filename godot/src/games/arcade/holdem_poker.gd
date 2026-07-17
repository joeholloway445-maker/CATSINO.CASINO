class_name HoldemPoker
extends Control
# Texas Hold'em variant — uses play_holdem Nakama RPC

@onready var hole_hand: HBoxContainer = $VBox/PlayerArea/HoleHand
@onready var community_hand: HBoxContainer = $VBox/Community/CommunityHand
@onready var bet_spin: SpinBox = $VBox/Controls/BetSpin
@onready var deal_btn: Button = $VBox/Controls/DealBtn
@onready var fold_btn: Button = $VBox/Controls/FoldBtn
@onready var call_btn: Button = $VBox/Controls/CallBtn
@onready var result_label: Label = $VBox/ResultLabel

const SUITS := ["🐾", "🐱", "🌟", "🎭"]
const VALUES := ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

var _in_hand := false

func _ready() -> void:
	deal_btn.pressed.connect(_deal)
	fold_btn.pressed.connect(func(): _action("fold"))
	call_btn.pressed.connect(func(): _action("call"))
	_set_action_buttons(false)
	var back := Button.new()
	back.text = "⬅ Back"
	back.position = Vector2(12, 12)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/world/paw_vegas_hub.tscn"))
	add_child(back)

func _deal() -> void:
	NetworkManager.call_rpc("play_holdem", {action="deal", bet=int(bet_spin.value)},
		func(result: Dictionary):
			if result.get("error"):
				NotificationUI.notify_error(result.error)
				return
			_render_hole(result.get("hole_cards", []))
			_render_community(result.get("community_cards", []))
			_in_hand = true
			_set_action_buttons(true)
			deal_btn.disabled = true
			result_label.text = "Bet placed. Fold or Call?"
	)

func _action(act: String) -> void:
	NetworkManager.call_rpc("play_holdem", {action=act, bet=int(bet_spin.value)},
		func(result: Dictionary):
			if result.get("error"):
				NotificationUI.notify_error(result.error)
				return
			_render_community(result.get("community_cards", []))
			if result.get("outcome"):
				var payout: int = result.get("payout", 0)
				result_label.text = "%s | Hand: %s | Payout: %d" % [result.outcome.capitalize(), result.get("hand_name", ""), payout]
				if payout > 0: NotificationUI.notify_win("Holdem: +%d chips!" % payout)
				AchievementManager.check("win", payout)
				XPManager.award_game("holdem", payout > 0)
				_set_action_buttons(false)
				deal_btn.disabled = false
				_in_hand = false
	)

func _render_hole(cards: Array) -> void:
	for child in hole_hand.get_children(): child.queue_free()
	for card in cards:
		var idx: int = card
		var lbl := Label.new()
		lbl.text = "%s%s" % [VALUES[idx % 13], SUITS[idx / 13]]
		hole_hand.add_child(lbl)

func _render_community(cards: Array) -> void:
	for child in community_hand.get_children(): child.queue_free()
	for card in cards:
		if card == -1:
			var hidden := Label.new()
			hidden.text = "🂠"
			community_hand.add_child(hidden)
		else:
			var idx: int = card
			var lbl := Label.new()
			lbl.text = "%s%s" % [VALUES[idx % 13], SUITS[idx / 13]]
			community_hand.add_child(lbl)

func _set_action_buttons(enabled: bool) -> void:
	fold_btn.disabled = not enabled
	call_btn.disabled = not enabled
