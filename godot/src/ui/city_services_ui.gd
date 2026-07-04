extends Control
## City Services — the bank branch and guild hall, present in every major
## city (Arlington, Dallas, Fort Worth, Denton, and the casino cage).
## Personal vault (safe from open-PvP and PVXC seizure; NOT from the
## Periliminal), the guild bank (Officer+ withdraws), and the guild
## charter desk with customizable ranks.

var _status: Label

func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title := Label.new()
	title.text = "🏦 CITY SERVICES"
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	if not BankManager.at_branch():
		var warn := Label.new()
		warn.text = "No branch out here. Banks live in the major cities — and the wilds know you're carrying."
		warn.modulate = Color(1.0, 0.6, 0.4)
		root.add_child(warn)

	_status = Label.new()
	_status.modulate = Color(0.8, 0.8, 0.85)
	root.add_child(_status)

	root.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	# ── Personal vault ──
	var vh := Label.new()
	vh.text = "── PERSONAL VAULT ──"
	vh.add_theme_font_size_override("font_size", 17)
	list.add_child(vh)
	for cid in EconomyManager.CURRENCIES.keys():
		_currency_row(list, cid, false)

	# ── Guild ──
	var gh := Label.new()
	gh.text = "── GUILD ──"
	gh.add_theme_font_size_override("font_size", 17)
	list.add_child(gh)
	if GuildManager.in_guild():
		var g: Dictionary = GuildManager.guild
		var info := Label.new()
		info.text = "%s [%s] — you are %s. Ranks: %s" % [
			g.name, g.tag, GuildManager.rank_of("local_player"), " → ".join(g.ranks)]
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(info)
		var gbh := Label.new()
		gbh.text = "Guild bank (everyone deposits; Officer+ withdraws):"
		gbh.modulate = Color(0.7, 0.7, 0.75)
		list.add_child(gbh)
		for cid in ["cat_coins", "tokens", "fragments"]:
			_currency_row(list, cid, true)
		var rank_row := HBoxContainer.new()
		list.add_child(rank_row)
		var rank_edit := LineEdit.new()
		rank_edit.placeholder_text = "New rank name (Leader only)"
		rank_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rank_row.add_child(rank_edit)
		var add_rank := Button.new()
		add_rank.text = "Add rank"
		add_rank.pressed.connect(func():
			if GuildManager.add_rank(rank_edit.text):
				get_tree().reload_current_scene())
		rank_row.add_child(add_rank)
	else:
		var charter_row := HBoxContainer.new()
		list.add_child(charter_row)
		var name_edit := LineEdit.new()
		name_edit.placeholder_text = "Guild name"
		name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		charter_row.add_child(name_edit)
		var tag_edit := LineEdit.new()
		tag_edit.placeholder_text = "TAG"
		tag_edit.custom_minimum_size = Vector2(70, 0)
		charter_row.add_child(tag_edit)
		var charter := Button.new()
		charter.text = "Charter guild (%d 🪙)" % GuildManager.CREATE_COST_COINS
		charter.pressed.connect(func():
			if await GuildManager.create_guild(name_edit.text, tag_edit.text):
				get_tree().reload_current_scene())
		charter_row.add_child(charter)

	var back := Button.new()
	back.text = "⬅ Back"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	root.add_child(back)
	_refresh_status()

func _currency_row(list: VBoxContainer, cid: String, guild: bool) -> void:
	var c: Dictionary = EconomyManager.CURRENCIES.get(cid, {})
	var row := HBoxContainer.new()
	var lbl := Label.new()
	var banked: int = (BankManager.guild_vault if guild else BankManager.vault).get(cid, 0)
	lbl.text = "%s %s — carried %d / banked %d" % [
		c.get("icon", ""), c.get("name", cid), EconomyManager.get_balance(cid), banked]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var amount := SpinBox.new()
	amount.min_value = 1
	amount.max_value = 1000000
	amount.value = 100
	row.add_child(amount)
	var dep := Button.new()
	dep.text = "Deposit"
	dep.disabled = not BankManager.at_branch()
	dep.pressed.connect(func():
		var ok: bool = (await BankManager.guild_deposit(cid, int(amount.value))) if guild \
			else (await BankManager.deposit(cid, int(amount.value)))
		if ok: get_tree().reload_current_scene())
	row.add_child(dep)
	var wd := Button.new()
	wd.text = "Withdraw"
	wd.disabled = not BankManager.at_branch()
	wd.pressed.connect(func():
		var ok: bool = (await BankManager.guild_withdraw(cid, int(amount.value))) if guild \
			else (await BankManager.withdraw(cid, int(amount.value)))
		if ok: get_tree().reload_current_scene())
	row.add_child(wd)
	list.add_child(row)

func _refresh_status() -> void:
	_status.text = "Banked money survives open-PvP deaths and PVXC seizures. The Periliminal is another story."
