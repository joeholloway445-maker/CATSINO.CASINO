extends Node
class_name GameManager

# ── Signals ────────────────────────────────────────────────────────────────────
signal state_changed(old_state: GameState, new_state: GameState)
signal initialization_complete()
signal critical_error(message: String)

# ── Enums ──────────────────────────────────────────────────────────────────────
enum GameState {
	LOADING,
	LOGIN,
	WORLD,
	GAME,
	SOCIAL,
	SETTINGS,
}

# ── State ──────────────────────────────────────────────────────────────────────
var game_state: GameState   = GameState.LOADING
var _init_complete: bool    = false
var _init_errors: Array[String] = []

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Connect manager signals
	if AccountManager:
		AccountManager.authenticated.connect(_on_authenticated)
		AccountManager.session_expired.connect(_on_session_expired)
	if DistrictManager:
		DistrictManager.district_loaded.connect(_on_district_loaded)

func _process(_delta: float) -> void:
	pass

# ── Initialization ─────────────────────────────────────────────────────────────
func initialize() -> void:
	_set_state(GameState.LOADING)
	var steps := [
		_init_account_manager,
		_init_economy_manager,
		_init_companion_system,
		_init_game_factory,
		_init_district_manager,
		_init_liveops_manager,
		_init_social_manager,
	]
	for step in steps:
		await step.call()
		await get_tree().process_frame

	if _init_errors.is_empty():
		_init_complete = true
		emit_signal("initialization_complete")
		_set_state(GameState.LOGIN)
	else:
		push_error("GameManager: initialization errors: %s" % str(_init_errors))
		emit_signal("critical_error", "\n".join(_init_errors))

# ── State Machine ──────────────────────────────────────────────────────────────
func set_state(new_state: GameState) -> void:
	_set_state(new_state)

func is_in_state(state: GameState) -> bool:
	return game_state == state

func enter_game(game_type: int, variant_id: int) -> void:
	_set_state(GameState.GAME)
	if GameFactory:
		var game_node := GameFactory.create_game(game_type, variant_id)
		if game_node:
			get_tree().current_scene.add_child(game_node)

func exit_game() -> void:
	_set_state(GameState.WORLD)

func open_social() -> void:
	_set_state(GameState.SOCIAL)

func close_social() -> void:
	_set_state(GameState.WORLD)

# ── Init Steps ─────────────────────────────────────────────────────────────────
func _init_account_manager() -> void:
	if not AccountManager:
		_init_errors.append("AccountManager not found")
		return
	await AccountManager.initialize()

func _init_economy_manager() -> void:
	# EconomyManager initializes after AccountManager completes auth
	pass

func _init_companion_system() -> void:
	if not CompanionSystem:
		return
	await CompanionSystem.initialize()

func _init_game_factory() -> void:
	if not GameFactory:
		return
	await GameFactory.initialize()

func _init_district_manager() -> void:
	if not DistrictManager:
		return
	await DistrictManager.initialize()

func _init_liveops_manager() -> void:
	if not LiveOpsManager:
		return
	await LiveOpsManager.initialize()

func _init_social_manager() -> void:
	if not SocialManager:
		return
	await SocialManager.initialize()

# ── Handlers ──────────────────────────────────────────────────────────────────
func _on_authenticated(_session: Dictionary) -> void:
	if game_state == GameState.LOGIN:
		_set_state(GameState.WORLD)
		if DistrictManager:
			await DistrictManager.transition_to_district(DistrictManager.District.PAW_VEGAS)

func _on_session_expired() -> void:
	_set_state(GameState.LOGIN)

func _on_district_loaded(_district: int) -> void:
	if game_state == GameState.LOADING:
		_set_state(GameState.WORLD)

# ── Private ────────────────────────────────────────────────────────────────────
func _set_state(new_state: GameState) -> void:
	if new_state == game_state:
		return
	var old := game_state
	game_state = new_state
	emit_signal("state_changed", old, new_state)
