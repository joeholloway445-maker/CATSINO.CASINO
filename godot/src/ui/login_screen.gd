extends Control
## Login / guest entry after splash. Email auth hits Nakama when available;
## Play Offline always mocks a session so the GOTY boot path works without
## a local server.

var _email_field: LineEdit
var _password_field: LineEdit
var _login_btn: Button
var _register_btn: Button
var _guest_btn: Button
var _status_label: Label

func _ready() -> void:
	_email_field = $CenterContainer/VBox/EmailField
	_password_field = $CenterContainer/VBox/PasswordField
	_login_btn = $CenterContainer/VBox/LoginButton
	_register_btn = $CenterContainer/VBox/RegisterButton
	_status_label = $CenterContainer/VBox/StatusLabel
	_ensure_guest_button()
	_apply_phone_scale()
	_login_btn.pressed.connect(_on_login_pressed)
	_register_btn.pressed.connect(_on_register_pressed)
	_guest_btn.pressed.connect(_on_guest_pressed)
	AccountManager.authenticated.connect(_on_authenticated)
	AccountManager.auth_failed.connect(_on_auth_failed)
	# Ensure GameManager is in LOGIN so auth handoff reaches the title screen.
	if GameManager.game_state == GameManager.GameState.LOADING:
		await GameManager.initialize()

## 1920×1080 canvas_items stretch crushes 48px buttons on phones — inflate.
func _apply_phone_scale() -> void:
	var b := PhoneUI.boost()
	if b <= 1.05:
		return
	var vbox: VBoxContainer = $CenterContainer/VBox
	vbox.custom_minimum_size = Vector2(320.0 * b, 0)
	vbox.add_theme_constant_override("separation", int(10.0 * b))
	var title: Label = vbox.get_node_or_null("Title")
	if title:
		title.add_theme_font_size_override("font_size", PhoneUI.font(36))
	var subtitle: Label = vbox.get_node_or_null("Subtitle")
	if subtitle:
		subtitle.add_theme_font_size_override("font_size", PhoneUI.font(16))
		subtitle.modulate = Color(0.7, 0.6, 0.9)
	for child in vbox.get_children():
		if child is LineEdit or child is Button:
			child.custom_minimum_size = Vector2(0, 48.0 * b)
			if child is Button:
				child.add_theme_font_size_override("font_size", PhoneUI.font(18))
			elif child is LineEdit:
				child.add_theme_font_size_override("font_size", PhoneUI.font(16))
	if _status_label:
		_status_label.add_theme_font_size_override("font_size", PhoneUI.font(14))
	# Make PLAY OFFLINE the obvious thumb target.
	if _guest_btn:
		_guest_btn.custom_minimum_size = Vector2(0, 56.0 * b)
		_guest_btn.add_theme_font_size_override("font_size", PhoneUI.font(22))


func _ensure_guest_button() -> void:
	var vbox := $CenterContainer/VBox
	_guest_btn = vbox.get_node_or_null("GuestButton") as Button
	if _guest_btn == null:
		_guest_btn = Button.new()
		_guest_btn.name = "GuestButton"
		_guest_btn.text = "PLAY OFFLINE"
		_guest_btn.custom_minimum_size = Vector2(0, 48)
		var status_idx := _status_label.get_index()
		vbox.add_child(_guest_btn)
		vbox.move_child(_guest_btn, status_idx)

func _on_login_pressed() -> void:
	var email := _email_field.text.strip_edges()
	var password := _password_field.text
	if email.is_empty() or password.is_empty():
		_set_status("Email and password required", true)
		return
	_set_busy(true)
	_set_status("Logging in…")
	var ok: bool = await AccountManager.auth_email(email, password, false)
	if not ok:
		_set_busy(false)

func _on_register_pressed() -> void:
	var email := _email_field.text.strip_edges()
	var password := _password_field.text
	if email.is_empty() or password.is_empty():
		_set_status("Email and password required", true)
		return
	if password.length() < 8:
		_set_status("Password must be at least 8 characters", true)
		return
	_set_busy(true)
	_set_status("Registering…")
	var ok: bool = await AccountManager.auth_email(email, password, true)
	if not ok:
		_set_busy(false)

func _on_guest_pressed() -> void:
	_set_busy(true)
	_set_status("Entering offline…")
	await AccountManager.auth_guest()

func _on_authenticated(_session: Dictionary) -> void:
	_set_status("Authenticated — opening title…")
	# GameManager._on_authenticated owns the scene change to title_screen.

func _on_auth_failed(reason: String) -> void:
	_set_status("Error: " + reason, true)
	_set_busy(false)

func _set_busy(busy: bool) -> void:
	_login_btn.disabled = busy
	_register_btn.disabled = busy
	_guest_btn.disabled = busy

func _set_status(msg: String, error: bool = false) -> void:
	if _status_label:
		_status_label.text = msg
		_status_label.modulate = Color.RED if error else Color.WHITE
