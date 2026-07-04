extends Node
## Autoloaded as "Marketplace". Arlington's trading floor: NPC vendor
## stalls plus the player-driven canon-UGC exchange.
##
## UGC rules enforced here (docs/UGC_POLICY.md):
##  - Only CANON blueprints can list. Unapproved UGC never leaves the
##    creator's Subliminal, so it can never reach a stall.
##  - Every sold copy pays the Holdings' cut (BlueprintManager.HOLDINGS_CUT)
##    to Holloway's Own Providential Enterprise Apex Holdings Inc.; the
##    rest goes to the creator.
##  - Copies carry the creator's name forever. Only the creator can craft
##    new copies (BlueprintManager.can_craft) — buying a copy is buying
##    the ITEM, never the blueprint.
##  - Selling the BLUEPRINT itself (transfer_blueprint) hands over
##    authorship: name, crafting rights, future listing rights — all of it.

signal listing_added(listing: Dictionary)
signal copy_sold(listing_id: String, buyer: String)

## Arlington marketplace vendor roster. Each stall anchors a shop UI and
## an NPC; wares list which item types / blueprint kinds it trades.
const VENDORS: Array[Dictionary] = [
	{id="guild_trader", name="Guild Trader", icon="🏳️",
		wares=["guild_listings"], desc="Sells on behalf of entire guilds — browse a guild's canon catalogue."},
	{id="armorer", name="Armorer", icon="🛡️",
		wares=["armor"], desc="Canon armor blueprints crafted to order by their creators."},
	{id="blacksmith", name="Blacksmith", icon="⚒️",
		wares=["weapon"], desc="Canon weapon designs — every blade signed by its maker."},
	{id="merchant", name="Merchant", icon="🧺",
		wares=["consumable", "equipment"], desc="General goods, potions, boosts."},
	{id="black_market", name="Black Market Merchant", icon="🕳️",
		wares=["weapon", "armor", "entity"], desc="No questions. Rotating stock, prices that lie, provenance that doesn't exist."},
	{id="stables", name="Stables", icon="🐎",
		wares=["entity"], desc="Canon mounts and companions — forged forms with their creators' names."},
	{id="jeweler", name="Jeweler", icon="💎",
		wares=["equipment"], desc="Rings, amulets, and the shinier end of canon craft."},
	{id="alchemist", name="Alchemist", icon="⚗️",
		wares=["consumable"], desc="Brews, serums, and things best not asked about."},
	{id="outfitter", name="Outfitter", icon="🧵",
		wares=["armor", "skill"], desc="Style-first gear and canon skill-effect designs."},
	{id="curio_dealer", name="Curio Dealer", icon="🗝️",
		wares=["skill", "entity"], desc="Oddities from all six layers. Every piece has a story; some are true."},
	{id="banker", name="Bank Branch", icon="🏦",
		wares=["banking"], desc="Personal vault and guild-bank access (BankManager)."},
]

## listing_id -> {bp_id, seller, price, kind, name, author, sold}
var _listings: Dictionary = {}

const SAVE_PATH := "user://marketplace.json"

func _ready() -> void:
	_load()

static func vendor_by_id(vid: String) -> Dictionary:
	for v in VENDORS:
		if v.id == vid: return v
	return {}

## List a canon design for sale. Price in coins; the cut comes out on sale.
func list_copy(bp_id: String, price: int) -> Dictionary:
	var bp := BlueprintManager.get_blueprint(bp_id)
	if bp.is_empty():
		return {}
	if not BlueprintManager.is_canon(bp_id):
		NotificationUI.notify_error("Only canon designs reach the marketplace — unapproved UGC stays in your Subliminal.")
		return {}
	if not BlueprintManager.can_craft(bp_id):
		NotificationUI.notify_error("Only %s can craft and list this design." % bp.author)
		return {}
	var listing := {
		"id": "lst_%d" % Time.get_ticks_msec(),
		"bp_id": bp_id,
		"seller": PlayerProfile.username,
		"price": maxi(price, 1),
		"kind": bp.kind,
		"name": bp.name,
		"author": bp.author,
		"sold": 0,
	}
	_listings[listing.id] = listing
	_save()
	listing_added.emit(listing)
	NotificationUI.notify_info("'%s' listed for %d coins (Holdings' cut %d%% per copy)." % [bp.name, listing.price, int(BlueprintManager.HOLDINGS_CUT * 100)])
	return listing

func listings_for(wares: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for l in _listings.values():
		if l.kind in wares:
			out.append(l)
	return out

## Buy one crafted copy. The creator's name stays on it; the blueprint
## does NOT transfer.
func buy_copy(listing_id: String) -> bool:
	var l: Dictionary = _listings.get(listing_id, {})
	if l.is_empty():
		return false
	if not await EconomyManager.spend_coins(int(l.price), "ugc_copy_%s" % l.name):
		return false
	var cut := int(ceil(l.price * BlueprintManager.HOLDINGS_CUT))
	var creator_share: int = l.price - cut
	# Offline/local: credit the seller directly if it's us; otherwise the
	# backend settles creator payouts. The Holdings' cut is always logged.
	if l.seller == PlayerProfile.username:
		EconomyManager.earn_coins(creator_share, "ugc_royalty_%s" % l.name)
	Hope.record("ugc_sale", {"name": l.name, "price": l.price, "holdings_cut": cut})
	l["sold"] = int(l.sold) + 1
	_listings[listing_id] = l
	var bp := BlueprintManager.get_blueprint(str(l.bp_id))
	if not bp.is_empty():
		bp["copies_sold"] = int(bp.get("copies_sold", 0)) + 1
		BlueprintManager.update(bp)
	_save()
	copy_sold.emit(listing_id, PlayerProfile.username)
	NotificationUI.notify_win("Bought '%s' by %s — %d coins (%d to the Holdings)." % [l.name, l.author, l.price, cut])
	return true

## Sell the blueprint ITSELF: authorship, name, crafting rights and all.
## Irreversible by design — this is the one way a creator's name comes off.
func transfer_blueprint(bp_id: String, new_owner: String) -> bool:
	var bp := BlueprintManager.get_blueprint(bp_id)
	if bp.is_empty() or str(bp.get("author", "")) != PlayerProfile.username:
		return false
	bp["author"] = new_owner
	BlueprintManager.update(bp)
	NotificationUI.notify_info("Blueprint '%s' sold outright — %s now holds the name and the crafting rights." % [bp.name, new_owner])
	return true

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"listings": _listings}))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary and d.get("listings") is Dictionary:
		_listings = d.listings
