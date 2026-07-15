class_name ViewScale
## "View scale" — the per-player opt-in style for HOW the identity-lens/RPS
## perception distortion (PerceptionSystem.perceive: apparent scale + aura)
## renders on a client: glitchy, holographic, shadowy, or off entirely.
## Opt-in by default, because the distortion is part of what makes no two
## players' worlds look the same (see IdentityLens' header) — but it's a
## real accessibility/preference toggle, not a mandatory effect.
##
## Applies uniformly to players, entities, and companions, because all of
## them are ultimately perceived through PerceptionSystem.perceive(). The
## one asymmetry: opt-out travels with the SUBJECT, not just the viewer.
## If a player has opted out, they (and anything tied to them — a
## companion, an owned entity) render undistorted for every viewer, not
## just their own client. A subject with no owner (wildlife, PVXC
## creatures) has nothing to opt out of, so it always just follows the
## local viewer's own style — pass `opted_out` in the target profile dict
## only when the subject actually has an owner and that owner said no.

const STYLES := ["glitchy", "holographic", "shadowy", "off"]
const DEFAULT_STYLE := "holographic"

static func is_valid(style: String) -> bool:
	return style in STYLES

## What actually renders for this (viewer, subject) pair. The subject's
## own opt-out always wins over the viewer's preference — that's the
## "opted out sticks to you" contract.
static func resolve(viewer_style: String, subject_opted_out: bool) -> String:
	if subject_opted_out:
		return "off"
	return viewer_style if is_valid(viewer_style) else DEFAULT_STYLE

## Applies the resolved style to an already-computed PerceptionSystem view
## dict (apparent_scale/aura_color/aura_intensity/outline/loadout_visible).
## Returns an adjusted copy; never mutates the input. loadout_visible is
## left untouched — that's an RPS balance signal, a different axis from
## this cosmetic preference.
static func apply(view: Dictionary, style: String) -> Dictionary:
	var out := view.duplicate()
	out["style"] = style
	match style:
		"off":
			out.apparent_scale = 1.0
			out.aura_intensity = 0.0
		"glitchy":
			out.aura_intensity = clampf(float(out.aura_intensity) + 0.15, 0.0, 1.0)
			out.aura_color = (out.aura_color as Color).lerp(Color(1.0, 0.1, 0.9), 0.35)
			out["flicker"] = true
		"holographic":
			out.aura_intensity = clampf(float(out.aura_intensity) + 0.1, 0.0, 1.0)
			out.aura_color = (out.aura_color as Color).lerp(Color(0.5, 0.95, 1.0), 0.4)
			out["translucent"] = true
		"shadowy":
			out.apparent_scale = float(out.apparent_scale) * 0.92
			out.aura_intensity = 0.0
			out["silhouette"] = true
	return out
