class_name UINav
## Shared navigation helpers for overlay UIs opened from the main menu.

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"

static func add_back_button(host: Node, target_scene: String = MAIN_MENU, label: String = "⬅ Menu") -> Button:
	if host == null:
		return null
	if host.has_node("UINavBack"):
		return host.get_node("UINavBack") as Button
	var back := Button.new()
	back.name = "UINavBack"
	back.text = label
	back.z_index = 100
	back.position = Vector2(12, 12)
	back.pressed.connect(func() -> void:
		if host.get_tree() and ResourceLoader.exists(target_scene):
			host.get_tree().change_scene_to_file(target_scene)
	)
	host.add_child(back)
	return back
