class_name PhoneUI
extends RefCounted
## Phone / Web UI scale helpers.
##
## Project window is 1920×1080 with stretch mode `canvas_items`. That means
## Control sizes stay in 1080p-space and get *shrunk* onto the phone CSS
## canvas — a 56px button becomes ~11–14 CSS pixels. Detecting "mobile"
## via `get_visible_rect()` is wrong (always ~1080 short side).
##
## Use DisplayServer window size + touchscreen, then boost sizes so that
## after stretch they land near thumb-friendly on-device pixels.

const BASE_SHORT := 1080.0
const TARGET_SHORT_PX := 64.0 # desired on-device height for a primary button

## True when this is a touch device or a narrow window (phone browser).
static func is_phone() -> bool:
	if DisplayServer.is_touchscreen_available():
		return true
	var win := DisplayServer.window_get_size()
	var short := mini(win.x, win.y)
	return short > 0 and short < 700

## Multiplier for Control sizes in viewport space. ≥1 always; ~2.5–4 on phones.
static func boost() -> float:
	if not is_phone():
		return 1.0
	var win := DisplayServer.window_get_size()
	var short := float(mini(win.x, win.y))
	if short <= 1.0:
		return 2.8
	# After stretch, viewport short (≈1080) maps to `short` CSS px.
	# Want primary controls ≈ TARGET_SHORT_PX on device → boost = 1080/short * (target/base_btn).
	# Using 56 as the "desktop" primary button height in viewport space.
	var scale_down := short / BASE_SHORT
	if scale_down <= 0.01:
		return 3.0
	var needed := TARGET_SHORT_PX / (56.0 * scale_down)
	return clampf(needed, 2.2, 4.2)

static func px(base: float) -> float:
	return base * boost()

static func font(base: int) -> int:
	return int(round(float(base) * boost()))
