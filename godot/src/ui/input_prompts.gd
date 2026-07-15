class_name InputPrompts
extends RefCounted
## Kenney Input Prompts (CC0) lookup for mobile / keyboard glyphs.
## Files live under res://assets/ui/input_prompts/{touch,keyboard}/.
## TouchControls and menus can call texture_for("touch", "touch_gesture_tap") etc.

const ROOT := "res://assets/ui/input_prompts"

static func texture_for(device: String, glyph: String) -> Texture2D:
	var folder := "touch" if device == "touch" else "keyboard"
	var path := "%s/%s/%s.png" % [ROOT, folder, glyph]
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

static func has(device: String, glyph: String) -> bool:
	return texture_for(device, glyph) != null
