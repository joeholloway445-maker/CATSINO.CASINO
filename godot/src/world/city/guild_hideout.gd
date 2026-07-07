class_name GuildHideout
extends Node3D
## A claimable guild hideout SITE — several per city now, plus sites in the
## Extraliminal, all backed by HideoutRegistry (which owns the exclusion
## radii, banners, and defender garrisons). In the ring:
##   E — claim (unowned, costs tokens) / ATTACK the defenders (rival-owned)
##   F — fly or furl your banner (owner only; discreet guilds furl)
##   G — station your next active entity as a defender (it leaves your party)
##   H — recall every defender (they rejoin your party; site stands bare)

var site_id := ""
var realm := "supraliminal"
var hub_id := ""
var accent := Color(0.6, 0.6, 0.65)
var _player: Node3D
var _banner: MeshInstance3D
var _title: Label3D
var _in_ring := false

func setup(p_site_id: String, p_realm: String, p_hub_id: String,
		p_accent: Color, player: Node3D, world_pos: Vector3) -> void:
	site_id = p_site_id
	realm = p_realm
	hub_id = p_hub_id
	accent = p_accent
	_player = player
	HideoutRegistry.register_site(site_id, realm, hub_id, world_pos)

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
	HideoutRegistry.site_changed.connect(func(sid: String):
		if sid == site_id:
			_refresh())

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
			_ring_hint())
	area.body_exited.connect(func(b: Node3D):
		if b == _player:
			_in_ring = false)

func _owner() -> String:
	return HideoutRegistry.owner_of(site_id)

func _my_guild() -> String:
	return str(GuildManager.guild.get("name", "")) if GuildManager.in_guild() else ""

func _ring_hint() -> void:
	var owner := _owner()
	var garrison: int = HideoutRegistry.defenders(site_id).size()
	if owner == "":
		NotificationUI.notify_info("🏴 Unclaimed hideout site — E to claim for your guild (%d ⚔️ tokens). Exclusion radius applies." % HideoutRegistry.CLAIM_COST_TOKENS)
	elif owner == _my_guild():
		NotificationUI.notify_info("🏴 Your hideout — F banner on/off, G station a defender, H recall all (%d stationed)." % garrison)
	else:
		var shown := owner if HideoutRegistry.banner_visible(site_id) else "An unmarked guild"
		NotificationUI.notify_info("🏴 %s holds this ground (%d defender(s)). E to attack and take it." % [shown, garrison])

func _unhandled_key_input(event: InputEvent) -> void:
	if not _in_ring:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_E:
			_on_e()
		KEY_F:
			if _owner() != "" and _owner() == _my_guild():
				HideoutRegistry.set_banner(site_id, not HideoutRegistry.banner_visible(site_id))
				NotificationUI.notify_info("🏴 Banner %s." % ("raised — the district knows whose ground this is" if HideoutRegistry.banner_visible(site_id) else "furled — you hold this ground discreetly"))
		KEY_G:
			if _owner() != "" and _owner() == _my_guild():
				_station_next_defender()
		KEY_H:
			if _owner() != "" and _owner() == _my_guild():
				HideoutRegistry.recall_defenders(site_id)

func _on_e() -> void:
	var guild := _my_guild()
	if guild == "":
		NotificationUI.notify_error("A hideout needs a guild. Charter one at the bank first.")
		return
	var owner := _owner()
	if owner == "":
		await HideoutRegistry.claim(site_id, guild)
		if _owner() == guild:
			NotificationUI.notify_win("🏴 %s claims this hideout. Station defenders (G) before you leave — or lose it." % guild)
	elif owner != guild:
		HideoutRegistry.contest(site_id, guild)

func _station_next_defender() -> void:
	for cid in PlayerProfile.active_companion_ids.duplicate():
		if HideoutRegistry.assign_defender(site_id, str(cid)):
			return
	NotificationUI.notify_error("No active entities to station — your party is empty.")

func _refresh() -> void:
	var owner := _owner()
	var flying := HideoutRegistry.banner_visible(site_id)
	if owner == "":
		_title.text = "🏴 UNCLAIMED HIDEOUT"
		_title.modulate = Color(0.7, 0.7, 0.75)
		_banner.visible = true
		_banner.material_override = _banner_mat(Color(0.25, 0.25, 0.3))
	elif not flying:
		# Discreet: no colors, no name — just a hall someone clearly keeps.
		_title.text = ""
		_banner.visible = false
	else:
		var garrison: int = HideoutRegistry.defenders(site_id).size()
		_title.text = "🏴 %s%s" % [owner.to_upper(), "  🛡️%d" % garrison if garrison > 0 else ""]
		# Guild banner color derives from the guild name — same hue every
		# client, no config needed.
		var hue := Color.from_hsv(float(hash(owner) % 360) / 360.0, 0.7, 0.9)
		_title.modulate = hue
		_banner.visible = true
		_banner.material_override = _banner_mat(hue)

func _banner_mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	return mat
