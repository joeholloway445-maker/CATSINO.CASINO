class_name RenderCaps
## One question, asked everywhere: are we on the mobile-friendly
## Compatibility renderer (GL) or a full Forward+/Mobile Vulkan pipeline?
## Forward+-only environment features (SSAO/SSIL/SSR/volumetric fog) gate
## on this so the same scenes run clean on phones and web exports.

static var _cached := ""

static func is_compatibility() -> bool:
	if _cached == "":
		_cached = str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "forward_plus"))
	return _cached.contains("compatibility")
