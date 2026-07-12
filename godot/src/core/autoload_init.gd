extends Node

const VERSION := "0.1.0"

func _ready() -> void:
	print("╔══════════════════════════════════════════╗")
	print("║     PERILIMINAL.SPACE  v%s           ║" % VERSION)
	print("║  Six realities. One of you.  Cat Coins   ║")
	print("║  only — no real money / sweeps.          ║")
	print("╚══════════════════════════════════════════╝")
	# Applied before any UI exists — every Control created anywhere after
	# this inherits it automatically (nothing sets its own theme).
	get_tree().root.theme = AAATheme.build()
	_validate_autoloads()

func _validate_autoloads() -> void:
	var required := ["NetworkManager", "PlayerProfile", "AchievementManager",
		"QuestManager", "XPManager", "EventManager", "FactionSystem",
		"DailyRewards", "BattlePass", "NotificationUI"]
	for name in required:
		if not has_node("/root/" + name):
			push_warning("[AutoloadInit] Missing autoload: " + name)
	print("[AutoloadInit] Autoload check complete — all systems nominal.")
