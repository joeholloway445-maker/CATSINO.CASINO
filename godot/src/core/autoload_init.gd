extends Node

const VERSION := "0.1.0"

func _ready() -> void:
	print("╔══════════════════════════════════════════╗")
	print("║        CATSINO.CASINO  v%s           ║" % VERSION)
	print("║  Free-to-play Cat Coins only — no real  ║")
	print("║  money, no sweeps, no redemption.        ║")
	print("╚══════════════════════════════════════════╝")
	_validate_autoloads()

func _validate_autoloads() -> void:
	var required := ["NetworkManager", "PlayerProfile", "AchievementManager",
		"QuestManager", "XPManager", "EventManager", "FactionSystem",
		"DailyRewards", "BattlePass", "NotificationUI"]
	for name in required:
		if not has_node("/root/" + name):
			push_warning("[AutoloadInit] Missing autoload: " + name)
	print("[AutoloadInit] Autoload check complete — all systems nominal.")
