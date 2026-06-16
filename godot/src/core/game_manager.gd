extends Node

class_name GameManager

# ── State ─────────────────────────────────────────────────────────────────────
enum GameState { LOADING, LOGIN, CHARACTER_SELECT, WORLD, GAME, SOCIAL, CUTSCENE }

var game_state: GameState = GameState.LOADING
var session_start_time: int = 0

# ── Signals ───────────────────────────────────────────────────────────────────
signal state_changed(from: GameState, to: GameState)
signal initialization_complete()
signal critical_error(message: String)

# ── Init ──────────────────────────────────────────────────────────────────────
func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	_initialize()

func _initialize() -> void:
	print("[GameManager] Initializing CATSINO.CASINO...")
	session_start_time = Time.get_unix_time_from_system()

	# Boot order: account auth first, then economy, then world systems
	await EconomyManager.initialize()
	await AccountManager.initialize()
	await SocialManager.initialize()
	await LiveOpsManager.initialize()
	await CompanionSystem.initialize()
	await DistrictManager.initialize()

	print("[GameManager] All systems online — %.1fs" % _uptime())
	initialization_complete.emit()
	_transition_to(GameState.LOGIN)

# ── State machine ─────────────────────────────────────────────────────────────
func _transition_to(new_state: GameState) -> void:
	if new_state == game_state:
		return
	var prev := game_state
	game_state = new_state
	print("[GameManager] State: %s → %s" % [GameState.keys()[prev], GameState.keys()[new_state]])
	state_changed.emit(prev, new_state)

func enter_world() -> void:
	if AccountManager.is_authenticated():
		_transition_to(GameState.WORLD)
	else:
		push_error("[GameManager] enter_world() called without auth")

func enter_game(game_node: Node) -> void:
	_transition_to(GameState.GAME)
	get_tree().current_scene.add_child(game_node)

func return_to_world() -> void:
	_transition_to(GameState.WORLD)

func enter_social() -> void:
	_transition_to(GameState.SOCIAL)

# ── Quit handling ─────────────────────────────────────────────────────────────
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_shutdown()

func _shutdown() -> void:
	print("[GameManager] Shutdown — session %.0fs" % _uptime())
	SocialManager.disconnect_realtime()
	await AccountManager.save_session()
	get_tree().quit()

func _uptime() -> float:
	return Time.get_unix_time_from_system() - session_start_time
