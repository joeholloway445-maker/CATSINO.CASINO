class_name LayerExitDoor
extends Node3D
## The opposite of a HiddenDoor: an UNMISSABLE exit. Every space off the
## Liminal keeps clear, obvious doors back — glowing frame, floating label,
## no ambiguity. The Liminal itself spawns these toward the Subliminal,
## Hyperliminal (weighted most common — it should be easy to find),
## Supraliminal, and Extraliminal (guild-war grounds). NEVER toward the
## Periliminal: that layer is only ever entered by being taken.
##
## `blessing = true` is the one exception to obviousness rules: the
## Periliminal's way out. It doesn't exist until PeriliminalRuns says the
## run has earned it, and it reads as exactly what it is — a god-sent
## door after the hell, radiant in a place with no light.

const TARGET_STYLE := {
	"subliminal":   {"label": "HOME", "color": Color(1.0, 0.75, 0.4)},
	"hyperliminal": {"label": "THE CATSINO", "color": Color(0.3, 0.95, 0.9)},
	"supraliminal": {"label": "THE METROPLEX", "color": Color(0.5, 0.7, 1.0)},
	"extraliminal": {"label": "GUILD WAR GROUNDS", "color": Color(0.75, 0.35, 0.95)},
	"liminal":      {"label": "THE BETWEEN", "color": Color(0.85, 0.85, 0.9)},
}

var target_layer := "hyperliminal"
var blessing := false

var _fired := false

func _ready() -> void:
	var style: Dictionary = TARGET_STYLE.get(target_layer, TARGET_STYLE["liminal"])
	var color: Color = Color(1.0, 0.95, 0.7) if blessing else style.color

	# Frame posts + lintel — an archway that reads from across the chunk.
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(0.4, 4.2, 0.4)
		post.mesh = pb
		post.position = Vector3(side * 1.6, 2.1, 0)
		post.material_override = _glow_mat(color, 1.2)
		add_child(post)
	var lintel := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(3.6, 0.4, 0.4)
	lintel.mesh = lb
	lintel.position = Vector3(0, 4.3, 0)
	lintel.material_override = _glow_mat(color, 1.2)
	add_child(lintel)

	# The threshold itself — a softly luminous plane you walk into.
	var panel := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.8, 4.0)
	panel.mesh = pm
	panel.rotation.x = PI / 2.0
	panel.position = Vector3(0, 2.0, 0)
	var panel_mat := _glow_mat(color, 3.0 if blessing else 1.8)
	panel_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	panel_mat.albedo_color.a = 0.55
	panel_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	panel.material_override = panel_mat
	add_child(panel)

	var title := Label3D.new()
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.font_size = 72
	title.outline_size = 10
	title.position.y = 5.2
	title.modulate = color
	title.text = "✦ A DOOR THAT SHOULD NOT BE HERE ✦" if blessing else "⇢ %s" % str(style.label)
	add_child(title)

	var beacon := OmniLight3D.new()
	beacon.light_color = color
	beacon.omni_range = 18.0
	beacon.light_energy = 2.5 if blessing else 1.2
	beacon.position.y = 3.0
	add_child(beacon)

	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 4.0, 1.2)
	cs.shape = box
	area.add_child(cs)
	area.position.y = 2.0
	add_child(area)
	area.body_entered.connect(func(b: Node3D):
		if b is ThirdPersonController:
			_walk_through())

func _walk_through() -> void:
	if _fired:
		return
	_fired = true
	if blessing:
		# Banks the run's fragments and delivers you out — the only exit
		# the Periliminal has ever offered anyone.
		NotificationUI.notify_win("✦ The door was sent for you. You walk out of the Periliminal alive.")
		PeriliminalRuns.exit_alive()
		return
	if not LayerManager.transition_to(target_layer):
		_fired = false # entry refused (e.g. invite-only) — door stays live

static func _glow_mat(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat
