class_name MobaHud
extends CanvasLayer
## Match HUD: HP/XP bars, gold, KDA/CS, inventory strip, minimap, kill feed,
## recall/respawn banners.

var shop: MobaShop
var _hp: ProgressBar
var _xp: ProgressBar
var _stats: Label
var _feed: VBoxContainer
var _inv: Label
var _banner: Label
var _minimap: Control
var _dots: Array = [] # {node, rect}
var _match: Node

func setup(p_shop: MobaShop, p_match: Node) -> void:
	shop = p_shop
	_match = p_match
	layer = 18
	_build()
	shop.gold_changed.connect(func(_g): _refresh())
	shop.level_changed.connect(func(_l, _x, _n): _refresh())
	shop.inventory_changed.connect(_refresh_inv)

func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# Bottom-left vitals
	var vitals := VBoxContainer.new()
	vitals.position = Vector2(24, 520)
	vitals.custom_minimum_size = Vector2(280, 0)
	root.add_child(vitals)
	_hp = ProgressBar.new()
	_hp.custom_minimum_size = Vector2(280, 18)
	_hp.max_value = 160
	_hp.show_percentage = false
	vitals.add_child(_hp)
	_xp = ProgressBar.new()
	_xp.custom_minimum_size = Vector2(280, 10)
	_xp.max_value = 100
	_xp.show_percentage = false
	vitals.add_child(_xp)
	_stats = Label.new()
	_stats.add_theme_font_size_override("font_size", 15)
	vitals.add_child(_stats)
	_inv = Label.new()
	_inv.modulate = Color(0.8, 0.85, 0.95)
	vitals.add_child(_inv)
	# Top kill feed
	_feed = VBoxContainer.new()
	_feed.position = Vector2(700, 24)
	_feed.custom_minimum_size = Vector2(360, 0)
	root.add_child(_feed)
	# Center banner
	_banner = Label.new()
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 28)
	_banner.position = Vector2(400, 200)
	_banner.custom_minimum_size = Vector2(480, 40)
	_banner.visible = false
	root.add_child(_banner)
	# Minimap
	_minimap = ColorRect.new()
	_minimap.color = Color(0.08, 0.1, 0.14, 0.85)
	_minimap.custom_minimum_size = Vector2(160, 120)
	_minimap.position = Vector2(24, 360)
	root.add_child(_minimap)
	var map_lbl := Label.new()
	map_lbl.text = "MAP"
	map_lbl.position = Vector2(4, 2)
	map_lbl.add_theme_font_size_override("font_size", 12)
	_minimap.add_child(map_lbl)

func _refresh() -> void:
	if shop == null:
		return
	_hp.max_value = int(shop.hero.max_hp)
	_hp.value = int(shop.hero.hp)
	_xp.max_value = int(shop.hero.xp_next)
	_xp.value = int(shop.hero.xp)
	_stats.text = "Lv%d  %dg  %d/%d/%d  CS %d  DMG %d  ARM %d" % [
		int(shop.hero.level), shop.gold,
		int(shop.hero.kills), int(shop.hero.deaths), int(shop.hero.assists),
		int(shop.hero.cs), int(shop.hero.damage), int(shop.hero.armor),
	]
	_refresh_inv()

func _refresh_inv() -> void:
	if _inv == null or shop == null:
		return
	if shop.inventory.is_empty():
		_inv.text = "Items: —"
		return
	var names: PackedStringArray = []
	for e in shop.inventory:
		names.append(str(e.get("name", "?")))
	_inv.text = "Items: " + ", ".join(names)

func push_feed(text: String, color: Color = Color(1, 1, 1)) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.modulate = color
	_feed.add_child(lbl)
	if _feed.get_child_count() > 6:
		_feed.get_child(0).queue_free()
	var tw := lbl.create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.6)
	tw.tween_callback(lbl.queue_free)

func show_banner(text: String, seconds: float = 2.0) -> void:
	_banner.text = text
	_banner.visible = true
	_banner.modulate.a = 1.0
	var tw := _banner.create_tween()
	tw.tween_interval(seconds)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): _banner.visible = false)

func set_respawn(seconds: float) -> void:
	if seconds <= 0.0:
		_banner.visible = false
		return
	_banner.visible = true
	_banner.modulate.a = 1.0
	_banner.text = "Respawning in %.0fs" % ceil(seconds)

func set_recall(progress: float) -> void:
	if progress <= 0.0:
		if _banner.text.begins_with("Recalling"):
			_banner.visible = false
		return
	_banner.visible = true
	_banner.modulate.a = 1.0
	_banner.text = "Recalling… %.0f%%" % (progress * 100.0)

func _process(_delta: float) -> void:
	_refresh()
	_update_minimap()

func _update_minimap() -> void:
	if _match == null or not is_instance_valid(_match):
		return
	# Clear old dots except label
	for c in _minimap.get_children():
		if c is ColorRect:
			c.queue_free()
	var w: float = 160.0
	var h: float = 120.0
	# World roughly X -32..32, Z -16..16
	for n in _match.get_tree().get_nodes_in_group("moba_unit"):
		if not is_instance_valid(n):
			continue
		var p: Vector3 = (n as Node3D).global_position
		var nx: float = clampf((p.x + 32.0) / 64.0, 0.0, 1.0)
		var nz: float = clampf((p.z + 16.0) / 32.0, 0.0, 1.0)
		var dot := ColorRect.new()
		dot.size = Vector2(4, 4)
		dot.position = Vector2(nx * (w - 4.0), nz * (h - 4.0))
		if n.is_in_group("moba_tower"):
			dot.size = Vector2(6, 6)
		var team := str(n.get("team"))
		dot.color = Color(0.4, 0.75, 1.0) if team == "ally" else Color(1.0, 0.4, 0.4)
		_minimap.add_child(dot)
	if _match.get("player") and _match.hero_is_alive():
		var pp: Vector3 = _match.player.global_position
		var nx2: float = clampf((pp.x + 32.0) / 64.0, 0.0, 1.0)
		var nz2: float = clampf((pp.z + 16.0) / 32.0, 0.0, 1.0)
		var me := ColorRect.new()
		me.size = Vector2(6, 6)
		me.position = Vector2(nx2 * (w - 6.0), nz2 * (h - 6.0))
		me.color = Color(0.3, 1.0, 0.45)
		_minimap.add_child(me)
