class_name CityVenues
## The civic layer every city carries: market(s), bank(s), armorer(s),
## blacksmith(s), a Stockyards (combat training — melee, ranged, unarmed,
## guns), and a Wager Hall (the storyline/DLC referendum floor, one vote
## per ballot per server day). Soulless Sanctuary (Arlington) ALONE adds
## the Arena, the College, and the Space Station — those are placed as
## landmarks (LandmarkBuilder); this class covers the walk-up venues.
##
## Each venue is a signed building with an interaction ring: step inside
## and press E (or click the sign) to open the real system behind it —
## Marketplace vendors, BankManager via city_services, StoryVote, or the
## Stockyards' live training dummies. Model slot "venue_<kind>" lets real
## storefront assets replace the procedural shells.

## The civic set every hub places (cell = local city cell coordinates).
const VENUES := [
	{"kind": "market", "label": "MARKET", "icon": "🧺", "cell": Vector2(2.5, 0.5)},
	{"kind": "bank", "label": "BANK", "icon": "🏦", "cell": Vector2(3.5, 0.5)},
	{"kind": "armorer", "label": "ARMORER", "icon": "🛡️", "cell": Vector2(2.5, 2.5)},
	{"kind": "blacksmith", "label": "BLACKSMITH", "icon": "⚒️", "cell": Vector2(3.5, 2.5)},
	{"kind": "stockyards", "label": "STOCKYARDS", "icon": "🐎", "cell": Vector2(0.5, 3.5)},
	{"kind": "wager_hall", "label": "WAGER HALL", "icon": "🗳️", "cell": Vector2(5.5, 3.5)},
]

const VENUE_COLORS := {
	"market": Color(0.85, 0.6, 0.25), "bank": Color(0.75, 0.75, 0.85),
	"armorer": Color(0.5, 0.55, 0.7), "blacksmith": Color(0.7, 0.35, 0.2),
	"stockyards": Color(0.55, 0.4, 0.25), "wager_hall": Color(0.7, 0.4, 0.9),
}

static func place_all(city_root: Node3D, accent: Color, base_y: float, player: Node3D) -> void:
	for v in VENUES:
		var pos := Vector3(float(v.cell.x) * CityData.CELL, base_y, float(v.cell.y) * CityData.CELL)
		city_root.add_child(_venue(str(v.kind), str(v.label), str(v.icon), pos, accent, player))

static func _venue(kind: String, label: String, icon: String, pos: Vector3,
		accent: Color, player: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Venue_%s" % kind
	root.position = pos
	var tint: Color = VENUE_COLORS.get(kind, Color.GRAY)

	# Storefront shell (real asset if installed).
	var shell := AssetLibrary.instance("venue_%s" % kind)
	if shell == null:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(14, 7, 12)
		mi.mesh = box
		mi.position.y = 3.5
		mi.material_override = AssetLibrary.material("facade_concrete", tint.darkened(0.45), 0.3, 0.1, 0.65)
		shell = mi
	root.add_child(shell)

	# A real opening door on the storefront face.
	var door := CityDoor.new()
	door.accent = tint
	door.position = Vector3(0, 0, 6.2)
	root.add_child(door)

	# Signage — emissive, on the night curve like every neon.
	var sign_label := Label3D.new()
	sign_label.text = "%s  %s" % [icon, label]
	sign_label.font_size = 96
	sign_label.outline_size = 12
	sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_label.modulate = tint.lightened(0.3)
	sign_label.position.y = 8.2
	root.add_child(sign_label)

	# Interaction ring: enter → prompt; interact → open the system.
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 9.0
	cs.shape = sph
	area.add_child(cs)
	root.add_child(area)
	area.body_entered.connect(func(b: Node3D):
		if b == player:
			NotificationUI.notify_info("%s %s — press E." % [icon, label.capitalize()])
			_arm_interact(root, kind, player))

	if kind == "stockyards":
		_spawn_training_dummies(root, accent)
	return root

## E-to-interact while inside the ring; disarmed when the player leaves.
static func _arm_interact(root: Node3D, kind: String, player: Node3D) -> void:
	var watcher := VenueInteract.new()
	watcher.kind = kind
	watcher.player = player
	watcher.venue_root = root
	root.add_child(watcher)

## The Stockyards floor: four dummies, one per combat discipline. Hitting
## a dummy trains the matching line (SkillManager XP) — melee and ranged
## feed your frame line; UNARMED and GUNS feed the new disciplines.
static func _spawn_training_dummies(root: Node3D, accent: Color) -> void:
	var kinds := [
		{"tag": "MELEE", "skill": "", "off": Vector3(-8, 0, 14)},
		{"tag": "RANGED", "skill": "", "off": Vector3(-3, 0, 16)},
		{"tag": "UNARMED", "skill": "una_a0", "off": Vector3(3, 0, 16)},
		{"tag": "GUNS", "skill": "gun_a0", "off": Vector3(8, 0, 14)},
	]
	for k in kinds:
		var dummy := TrainingDummy.new()
		dummy.discipline_tag = str(k.tag)
		dummy.trains_skill = str(k.skill)
		dummy.position = k.off
		dummy.accent = accent
		root.add_child(dummy)
