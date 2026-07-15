class_name OmniDexUI
extends CanvasLayer
## Browsable Master OmniDex — races, frames (exactly 20), mods, entities,
## and companions, all named via OmniDexRegistry.

var _kind_tabs: TabBar
var _faction_tabs: TabBar
var _list: ItemList
var _detail: RichTextLabel
var _count_label: Label

const KINDS := ["Races", "Frames", "Mods", "Entities", "Companions"]
const FACTIONS := ["SovereignCrown", "WildlandsAscendant", "VeiledCurrent", "Factionless"]

func _ready() -> void:
	OmniDexRegistry.assert_invariants()
	layer = 25
	var root := PanelContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.self_modulate = Color(0.08, 0.07, 0.12, 0.97)
	add_child(root)

	var vbox := VBoxContainer.new()
	root.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "OMNI DEX"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_count_label = Label.new()
	_count_label.modulate = Color(0.7, 0.75, 0.9)
	header.add_child(_count_label)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(queue_free)
	header.add_child(close)

	_kind_tabs = TabBar.new()
	for k in KINDS:
		_kind_tabs.add_tab(k)
	_kind_tabs.tab_changed.connect(func(_i): _on_kind_changed())
	vbox.add_child(_kind_tabs)

	_faction_tabs = TabBar.new()
	for f in FACTIONS:
		_faction_tabs.add_tab(f)
	_faction_tabs.tab_changed.connect(func(_i): _refresh_list())
	vbox.add_child(_faction_tabs)

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(cols)

	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(320, 0)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_select)
	cols.add_child(_list)

	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_child(_detail)

	_on_kind_changed()

func _on_kind_changed() -> void:
	var kind: String = str(KINDS[_kind_tabs.current_tab])
	_faction_tabs.visible = kind in ["Entities", "Companions"]
	_refresh_list()

func _refresh_list() -> void:
	_list.clear()
	_detail.text = ""
	var kind: String = str(KINDS[_kind_tabs.current_tab])
	match kind:
		"Races":
			_count_label.text = "  %d races" % OmniDexRegistry.RACE_COUNT
			for i in RaceDataCharacter.RACES.size():
				var r: Dictionary = RaceDataCharacter.RACES[i]
				var canon := OmniDexRegistry.race_display_name(str(r.id))
				_list.add_item("%s  [%s]" % [canon, r.name])
				_list.set_item_metadata(_list.item_count - 1, {"kind": "race", "data": r, "canon": canon})
		"Frames":
			_count_label.text = "  %d frames (identity)" % OmniDexRegistry.FRAME_COUNT
			for f in OmniDexRegistry.FRAMES:
				_list.add_item("%s  [%s · %s]" % [f.name, f.type, f.role])
				_list.set_item_metadata(_list.item_count - 1, {"kind": "frame", "data": f})
		"Mods":
			_count_label.text = "  %d mods" % OmniDexRegistry.MOD_COUNT
			for m in MorphRigData.RIGS:
				_list.add_item("%s  [%s / %s]" % [m.name, m.bonus, m.drawback])
				_list.set_item_metadata(_list.item_count - 1, {"kind": "mod", "data": m})
		"Entities":
			var faction: String = str(FACTIONS[_faction_tabs.current_tab])
			var lines: Array = EntityDexData.by_faction(faction)
			_count_label.text = "  %d entity lines · %s" % [lines.size(), faction]
			for line in lines:
				var apex: Dictionary = EntityDexData.stage_for(line, 3)
				if apex.is_empty():
					apex = EntityDexData.stage_for(line, 1)
				var shown := str(apex.get("name", line.get("id", "?")))
				_list.add_item("%s  [%s]" % [shown, line.get("category", "?")])
				_list.set_item_metadata(_list.item_count - 1, {"kind": "entity", "data": line})
		"Companions":
			var faction2: String = str(FACTIONS[_faction_tabs.current_tab])
			var roster := CompanionRegistry.get_by_faction(faction2)
			_count_label.text = "  %d companions · %s" % [roster.size(), faction2]
			for c in roster:
				_list.add_item("%s  [%s]" % [c.get("name", c.get("id", "?")), c.get("id", "")])
				_list.set_item_metadata(_list.item_count - 1, {"kind": "companion", "data": c})

func _on_select(idx: int) -> void:
	var meta: Dictionary = _list.get_item_metadata(idx)
	var kind: String = str(meta.get("kind", ""))
	var data: Dictionary = meta.get("data", {})
	match kind:
		"race":
			_detail.text = "[b]%s[/b]\nCasino skin: %s\n\n%s" % [
				meta.get("canon", data.get("name", "?")),
				data.get("name", "?"),
				data.get("lore", ""),
			]
		"frame":
			_detail.text = "[b]%s[/b]  —  %s %s\nRole: %s\n\nCanonical OmniDex identity frame (%d total)." % [
				data.get("name", "?"), data.get("type", "?"), "frame",
				data.get("role", "?"), OmniDexRegistry.FRAME_COUNT,
			]
		"mod":
			_detail.text = "[b]%s[/b]\n%s / %s\n\n%s" % [
				data.get("name", "?"), data.get("bonus", ""), data.get("drawback", ""),
				data.get("desc", ""),
			]
		"entity":
			var lines: Array = []
			lines.append("[b]%s[/b]  —  %s / %s" % [data.get("id", "?"), data.get("faction", "?"), data.get("category", "?")])
			lines.append("")
			for i in 3:
				var stage: Dictionary = EntityDexData.stage_for(data, i + 1)
				if stage.is_empty():
					continue
				lines.append("[color=#ffd88a]Stage %d — %s[/color]" % [i + 1, stage.get("name", "?")])
				lines.append(str(stage.get("desc", "")))
				lines.append("")
			_detail.text = "\n".join(lines)
		"companion":
			_detail.text = "[b]%s[/b]\nId: %s\nFaction: %s\nRarity: %s\n\n%s" % [
				data.get("name", "?"),
				data.get("id", "?"),
				CompanionRegistry.normalize_faction(str(data.get("faction", ""))),
				str(data.get("rarity", "?")),
				str(data.get("lore", data.get("desc", ""))),
			]
