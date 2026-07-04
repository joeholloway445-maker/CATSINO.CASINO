extends Node
## Autoloaded as "BankManager". Banking in every major city — Arlington,
## Dallas, Fort Worth, Denton, and the casino cage (the hyperliminal is a
## city too). One personal vault reachable from any branch (it's the same
## vault; the branches are doors), plus the GUILD BANK: everyone deposits,
## Officer-and-above withdraw (GuildManager.can_use_guild_bank).
##
## Banked currency is SAFE: open-PvP deaths and PVXC seizures only touch
## what you carry. The Periliminal is the one thing that empties vaults —
## it keeps what it kills, banked or not (prestige excepted).

signal vault_changed()

const SAVE_PATH := "user://bank.json"
const BRANCH_CITIES := ["arlington", "dallas", "fort_worth", "denton", "hyperliminal"]

var vault: Dictionary = {}       # currency -> amount
var guild_vault: Dictionary = {} # currency -> amount

func _ready() -> void:
	_load()

## Where banking is allowed: any hub city chunk, or the casino layer.
func at_branch() -> bool:
	if LayerManager.current_layer_id == "hyperliminal":
		return true
	if LayerManager.current_layer_id == "supraliminal":
		return not TerritoryControl.is_pvp_at(Vector3.ZERO) # inside hub bounds
	return false

func deposit(currency: String, amount: int) -> bool:
	if amount <= 0 or not await EconomyManager.spend_currency(currency, amount, "bank_deposit"):
		return false
	vault[currency] = vault.get(currency, 0) + amount
	_save()
	vault_changed.emit()
	return true

func withdraw(currency: String, amount: int) -> bool:
	if amount <= 0 or vault.get(currency, 0) < amount:
		return false
	vault[currency] -= amount
	await EconomyManager.earn_currency(currency, amount, "bank_withdraw")
	_save()
	vault_changed.emit()
	return true

func guild_deposit(currency: String, amount: int) -> bool:
	if not GuildManager.in_guild():
		NotificationUI.notify_error("No guild, no guild bank.")
		return false
	if amount <= 0 or not await EconomyManager.spend_currency(currency, amount, "guild_bank_deposit"):
		return false
	guild_vault[currency] = guild_vault.get(currency, 0) + amount
	_save()
	vault_changed.emit()
	return true

func guild_withdraw(currency: String, amount: int) -> bool:
	if not GuildManager.can_use_guild_bank("local_player"):
		NotificationUI.notify_error("Withdrawals need Officer rank or above.")
		return false
	if amount <= 0 or guild_vault.get(currency, 0) < amount:
		return false
	guild_vault[currency] -= amount
	await EconomyManager.earn_currency(currency, amount, "guild_bank_withdraw")
	_save()
	vault_changed.emit()
	return true

## The Periliminal's reach (called by its wipe): vaults too. It's the point.
func periliminal_seize() -> void:
	vault.clear()
	_save()
	vault_changed.emit()

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify({"vault": vault, "guild": guild_vault}))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f: return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		vault = d.get("vault", {})
		guild_vault = d.get("guild", {})
