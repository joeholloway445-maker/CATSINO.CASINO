class_name AAATheme
## The project's one visual language: dark glass panels, neon-violet/cyan
## accents, sharp corner-cut edges over soft rounding — Ready Player One
## HUD chrome, not default-Godot grey boxes. Built at runtime (no .tres
## authored blind outside the editor) and applied once, at boot, to the
## root viewport — every Control instantiated anywhere after that inherits
## it automatically since nothing in this codebase sets its own theme.

const BG        := Color(0.055, 0.05, 0.09, 0.92)   # glass panel base
const BG_RAISED := Color(0.09, 0.08, 0.14, 0.95)     # buttons/inputs
const BORDER    := Color(0.55, 0.35, 0.95, 0.55)     # violet edge glow
const ACCENT    := Color(0.55, 0.85, 1.0)            # cyan — hover/selection
const ACCENT_2  := Color(0.75, 0.4, 1.0)             # violet — pressed/active
const TEXT      := Color(0.92, 0.93, 0.98)
const TEXT_DIM  := Color(0.6, 0.6, 0.72)
const DANGER    := Color(1.0, 0.35, 0.4)

static func build() -> Theme:
	var t := Theme.new()

	t.set_default_font_size(15)
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.6))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)

	_panel(t)
	_button(t)
	_input(t)
	_lists(t)
	_bars(t)
	_tabs(t)
	return t

static func _box(bg: Color, border: Color, border_w: int = 1, radius: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(10)
	sb.shadow_size = 6
	sb.shadow_color = Color(0, 0, 0, 0.35)
	return sb

static func _panel(t: Theme) -> void:
	for cls in ["Panel", "PanelContainer"]:
		t.set_stylebox("panel", cls, _box(BG, BORDER, 1, 8))

static func _button(t: Theme) -> void:
	var normal := _box(BG_RAISED, BORDER, 1, 5)
	var hover := _box(BG_RAISED.lightened(0.06), ACCENT, 2, 5)
	var pressed := _box(ACCENT_2.darkened(0.5), ACCENT_2, 2, 5)
	var disabled := _box(BG.darkened(0.2), Color(0.3, 0.3, 0.35, 0.4), 1, 5)
	for cls in ["Button", "CheckButton", "OptionButton", "MenuButton", "ColorPickerButton"]:
		t.set_stylebox("normal", cls, normal)
		t.set_stylebox("hover", cls, hover)
		t.set_stylebox("pressed", cls, pressed)
		t.set_stylebox("disabled", cls, disabled)
		t.set_stylebox("focus", cls, _box(Color(0, 0, 0, 0), ACCENT, 1, 5))
		t.set_color("font_color", cls, TEXT)
		t.set_color("font_hover_color", cls, ACCENT)
		t.set_color("font_pressed_color", cls, Color.WHITE)
		t.set_color("font_disabled_color", cls, TEXT_DIM)

static func _input(t: Theme) -> void:
	var box := _box(BG_RAISED, BORDER, 1, 5)
	var focus := _box(BG_RAISED, ACCENT, 2, 5)
	for cls in ["LineEdit", "TextEdit", "SpinBox"]:
		t.set_stylebox("normal", cls, box)
		t.set_stylebox("focus", cls, focus)
		t.set_color("font_color", cls, TEXT)
		t.set_color("font_placeholder_color", cls, TEXT_DIM)
		t.set_color("caret_color", cls, ACCENT)
		t.set_color("selection_color", cls, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.35))

static func _lists(t: Theme) -> void:
	t.set_stylebox("panel", "ItemList", _box(BG, BORDER, 1, 6))
	t.set_stylebox("selected", "ItemList", _box(ACCENT_2.darkened(0.3), ACCENT, 1, 4))
	t.set_stylebox("selected_focus", "ItemList", _box(ACCENT_2.darkened(0.2), ACCENT, 1, 4))
	t.set_stylebox("cursor", "ItemList", _box(Color(0, 0, 0, 0), ACCENT, 1, 4))
	t.set_color("font_color", "ItemList", TEXT)
	t.set_color("font_selected_color", "ItemList", Color.WHITE)

static func _bars(t: Theme) -> void:
	var groove := _box(BG_RAISED, Color(0, 0, 0, 0), 0, 3)
	var fill := _box(ACCENT, Color(0, 0, 0, 0), 0, 3)
	fill.bg_color = ACCENT
	for cls in ["HSlider", "VSlider"]:
		t.set_stylebox("slider", cls, groove)
		t.set_stylebox("grabber_area", cls, fill)
		t.set_stylebox("grabber_area_highlight", cls, fill)
	t.set_stylebox("background", "ProgressBar", groove)
	t.set_stylebox("fill", "ProgressBar", fill)
	t.set_color("font_color", "ProgressBar", TEXT)

static func _tabs(t: Theme) -> void:
	t.set_stylebox("tab_selected", "TabBar", _box(BG_RAISED, ACCENT, 2, 4))
	t.set_stylebox("tab_unselected", "TabBar", _box(BG, Color(BORDER.r, BORDER.g, BORDER.b, 0.25), 1, 4))
	t.set_stylebox("tab_hovered", "TabBar", _box(BG_RAISED.lightened(0.04), ACCENT, 1, 4))
	t.set_color("font_selected_color", "TabBar", Color.WHITE)
	t.set_color("font_unselected_color", "TabBar", TEXT_DIM)
	t.set_stylebox("panel", "TabContainer", _box(BG, BORDER, 1, 6))
	t.set_stylebox("tab_selected", "TabContainer", _box(BG_RAISED, ACCENT, 2, 4))
	t.set_stylebox("tab_unselected", "TabContainer", _box(BG, Color(BORDER.r, BORDER.g, BORDER.b, 0.25), 1, 4))
