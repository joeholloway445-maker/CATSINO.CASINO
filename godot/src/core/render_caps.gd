class_name RenderCaps
## One question, asked everywhere: are we on the mobile-friendly
## Compatibility renderer (GL) or a full Forward+/Mobile Vulkan pipeline?
## Forward+-only environment features (SSAO/SSIL/SSR/volumetric fog) gate
## on this so the same scenes run clean on phones and web exports.

static var _cached := ""

static func is_compatibility() -> bool:
	if _cached == "":
		var method := str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "forward_plus"))
		# Runtime override: web/mobile, or software GL (llvmpipe on CI Xvfb),
		# cannot run Terrain3D clipmap shaders / Forward+-only effects.
		if OS.has_feature("web") or OS.has_feature("mobile"):
			_cached = "compatibility"
		else:
			var adapter := str(RenderingServer.get_video_adapter_name()).to_lower()
			if adapter.contains("llvmpipe") or adapter.contains("swiftshader"):
				_cached = "compatibility"
			else:
				_cached = method
	return _cached.contains("compatibility")
