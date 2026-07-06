class_name GuildHideout
extends Node3D
## A claimable guild hideout — one per city. Walk in as a guild leader,
## press E, pay the claim stake, and the building takes your guild's name
## and colors. Claims MIRROR the Extraliminal: taking a city hideout also
## registers the matching Extraliminal landmark as your guild hall
## ("hideout_<hub_id>"), so rival guilds can contest it there by opening a
## liminal door (the existing guild-war flow in ExtraliminalManager).

const CLAIM_COST_TOKENS := 500

var hub_id := ""
var accent := Color(0.6, 0.6, 0.65)
var _player: Node3D
var _banner: MeshInstance3D
var _title: Label3D
var _in_ring := false

func _ready() -> void:
	# The hideout shell: a fortified low hall with a banner wall.
	var shell := AssetLibrary.instance("guild_hideout")
	if shell == null:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(18, 9, 14)
		mi.mesh = box
		mi.position.y = 4.5
		mi.material_override = AssetLibrary.material("facade_brick", Color(0.3, 0.28, 0.32), 0.25, 0.1, 0.75)
		shell = mi
	add_child(shell)

	var door := CityDoor.new()
	door.accent = accent
	door.position = Vector3(0, 0, 7.2)
	add_child(door)

	_banner = MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(4.0, 6.0, 0.2)
	_banner.mesh = bb
	_banner.position = Vector3(0, 6.0, 7.15)
	_banner.material_override = _banner_mat(Color(0.25, 0.25, 0.3))
	add_child(_banner)

	_title = Label3D.new()
	_title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title.font_size = 84
	_title.outline_size = 10
	_title.position.y = 10.5
	add_child(_title)
	_refresh()

	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 10.0
	cs.shape = sph
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(func(b: Node3D):
		if b == _player:
			_in_ring = true
			var owner := _owner()
			if owner == "":
				NotificationUI.notify_info("🏴 Unclaimed hideout — E to claim for your guild (%d ⚔️ tokens)." % CLAIM_COST_TOKENS)
			else:
				NotificationUI.notify_info("🏴 %s holds this hideout. Contest it in the Extraliminal." % owner))
	area.body_exited.connect(func(b: Node3D):
		if b == _player:
			_in_ring = false)

func setup(p_hub_id: String, p_accent: Color, player: Node3D) -> void:
	hub_id = p_hub_id
	accent = p_accent
	_player = player

func _landmark_id() -> String:
	return "hideout_%s" % hub_id

func _owner() -> String:
	return ExtraliminalManager.landmark_owner(_landmark_id())

func _unhandled_key_input(event: InputEvent) -> void:
	if not _in_ring:
		return
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E):
		return
	_try_claim()

func _try_claim() -> void:
	if _owner() != "":
		return
	if not GuildManager.in_guild():
		NotificationUI.notify_error("A hideout needs a guild. Charter one at the bank first.")
		return
	var guild_name := str(GuildManager.guild.get("name", ""))
	if not await EconomyManager.spend_currency("tokens", CLAIM_COST_TOKENS, "hideout_claim"):
		NotificationUI.notify_error("Claiming the hideout stakes %d ⚔️ tokens." % CLAIM_COST_TOKENS)
		return
	# The mirror: claiming the city hideout claims its Extraliminal shadow.
	ExtraliminalManager.claim_landmark(_landmark_id(), guild_name)
	_refresh()
	NotificationUI.notify_win("🏴 %s claims the %s hideout — its Extraliminal hall now flies your colors too." % [guild_name, hub_id])

func _refresh() -> void:
	var owner := _owner()
	if owner == "":
		_title.text = "🏴 UNCLAIMED HIDEOUT"
		_title.modulate = Color(0.7, 0.7, 0.75)
		_banner.material_override = _banner_mat(Color(0.25, 0.25, 0.3))
	else:
		_title.text = "🏴 %s" % owner.to_upper()
		# Guild banner color derives from the guild name — same hue every
		# client, no config needed.
		var hue := Color.from_hsv(float(hash(owner) % 360) / 360.0, 0.7, 0.9)
		_title.modulate = hue
		_banner.material_override = _banner_mat(hue)

func _banner_mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	return mat
