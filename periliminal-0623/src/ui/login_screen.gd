extends Control

var _email_field: LineEdit
var _password_field: LineEdit
var _login_btn: Button
var _register_btn: Button
var _status_label: Label

func _ready() -> void:
	_email_field = $CenterContainer/VBox/EmailField
	_password_field = $CenterContainer/VBox/PasswordField
	_login_btn = $CenterContainer/VBox/LoginButton
	_register_btn = $CenterContainer/VBox/RegisterButton
	_status_label = $CenterContainer/VBox/StatusLabel
	_login_btn.pressed.connect(_on_login_pressed)
	_register_btn.pressed.connect(_on_register_pressed)
	AccountManager.authenticated.connect(_on_authenticated)
	AccountManager.auth_failed.connect(_on_auth_failed)

func _on_login_pressed() -> void:
	var email := _email_field.text.strip_edges()
	var password := _password_field.text
	if email.is_empty() or password.is_empty():
		_set_status("Email and password required", true)
		return
	_set_status("Logging in…")
	_login_btn.disabled = true
	_register_btn.disabled = true
	await AccountManager.authenticate_email(email, password)

func _on_register_pressed() -> void:
	var email := _email_field.text.strip_edges()
	var password := _password_field.text
	if email.is_empty() or password.is_empty():
		_set_status("Email and password required", true)
		return
	if password.length() < 8:
		_set_status("Password must be at least 8 characters", true)
		return
	_set_status("Registering…")
	_login_btn.disabled = true
	_register_btn.disabled = true
	await AccountManager.register_email(email, password)

func _on_authenticated() -> void:
	_set_status("Authenticated! Loading world…")
	GameManager.transition_to(GameManager.GameState.WORLD)

func _on_auth_failed(reason: String) -> void:
	_set_status("Error: " + reason, true)
	_login_btn.disabled = false
	_register_btn.disabled = false

func _set_status(msg: String, error: bool = false) -> void:
	if _status_label:
		_status_label.text = msg
		_status_label.modulate = Color.RED if error else Color.WHITE
