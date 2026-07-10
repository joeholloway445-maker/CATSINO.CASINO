extends Node
## IAPManager — Google Play Billing integration for Android.
## On all other platforms (Web, Desktop) purchase_package() immediately
## calls EconomyManager.purchase_coins() so the economy works in testing
## without a real storefront connected.
##
## Android setup (one-time):
##   1. In Godot, go to AssetLib and install "GodotGooglePlayBilling" plugin.
##   2. Enable it under Project → Project Settings → Plugins.
##   3. In the Android export preset enable gradle_build/use_gradle_build = true.
##   4. Add your SKUs to COIN_PACKAGES below, matching the product IDs in the
##      Google Play Console.
##
## All server credit happens via EconomyManager.purchase_coins() which calls
## the Nakama add_coins RPC — so coins are always credited server-side after
## the platform confirms the purchase.

signal purchase_completed(package_id: String, coins: int)
signal purchase_failed(package_id: String, error: String)
signal products_loaded(products: Array)

## Coin package definitions.  product_id must match the Google Play Console
## in-app product ID exactly.  coins is the amount credited on purchase.
const COIN_PACKAGES: Array[Dictionary] = [
	{"product_id": "coins_500",   "coins": 500,    "display_name": "Starter Pack",   "price_hint": "$0.99"},
	{"product_id": "coins_1200",  "coins": 1200,   "display_name": "Small Stack",    "price_hint": "$1.99"},
	{"product_id": "coins_3000",  "coins": 3000,   "display_name": "Big Stack",      "price_hint": "$4.99"},
	{"product_id": "coins_7500",  "coins": 7500,   "display_name": "High Roller",    "price_hint": "$9.99"},
	{"product_id": "coins_17000", "coins": 17000,  "display_name": "Whale Pack",     "price_hint": "$19.99"},
]

var _billing_plugin = null          # GodotGooglePlayBilling singleton (Android only)
var _pending_sku: String = ""       # SKU currently in the purchase flow
var _store_products: Dictionary = {}# product_id → store product data

func _ready() -> void:
	if not OS.has_feature("android"):
		return
	if Engine.has_singleton("GodotGooglePlayBilling"):
		_billing_plugin = Engine.get_singleton("GodotGooglePlayBilling")
		_connect_billing_signals()
		_billing_plugin.startConnection()
	else:
		push_warning("IAPManager: GodotGooglePlayBilling plugin not found. "
			+ "Install it via AssetLib and enable it in Project Settings → Plugins.")

func _connect_billing_signals() -> void:
	if not _billing_plugin:
		return
	_billing_plugin.connected.connect(_on_billing_connected)
	_billing_plugin.disconnected.connect(_on_billing_disconnected)
	_billing_plugin.connect_error.connect(_on_billing_connect_error)
	_billing_plugin.purchases_updated.connect(_on_purchases_updated)
	_billing_plugin.purchase_error.connect(_on_purchase_error)
	_billing_plugin.sku_details_query_completed.connect(_on_sku_details_loaded)

# ── Public API ────────────────────────────────────────────────────────────────

## Returns the array of COIN_PACKAGES, optionally enriched with live store
## prices once the billing connection is ready.
func get_packages() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pkg in COIN_PACKAGES:
		var enriched: Dictionary = pkg.duplicate()
		if _store_products.has(pkg["product_id"]):
			enriched["price"] = _store_products[pkg["product_id"]].get("price", pkg["price_hint"])
		else:
			enriched["price"] = pkg["price_hint"]
		result.append(enriched)
	return result

## Begin a purchase flow for the given product_id.
## On non-Android platforms this skips the store and credits coins directly
## (useful for Web/Desktop testing).
func purchase_package(product_id: String) -> void:
	var pkg: Dictionary = _find_package(product_id)
	if pkg.is_empty():
		purchase_failed.emit(product_id, "Unknown product id: %s" % product_id)
		return

	if not OS.has_feature("android") or not _billing_plugin:
		# Non-Android: simulate purchase immediately (dev/web mode)
		_credit_coins(product_id, pkg["coins"])
		return

	_pending_sku = product_id
	_billing_plugin.purchase(product_id)

# ── Private — billing callbacks ───────────────────────────────────────────────

func _on_billing_connected() -> void:
	var skus: PackedStringArray = []
	for pkg in COIN_PACKAGES:
		skus.append(pkg["product_id"])
	_billing_plugin.querySkuDetails(skus, "inapp")

func _on_billing_disconnected() -> void:
	push_warning("IAPManager: billing disconnected — will reconnect on next launch.")

func _on_billing_connect_error(response_id: int, debug_message: String) -> void:
	push_error("IAPManager: billing connect error %d — %s" % [response_id, debug_message])

func _on_purchases_updated(purchases: Array) -> void:
	for purchase in purchases:
		var sku: String = purchase.get("sku", "")
		if sku.is_empty():
			continue
		var pkg: Dictionary = _find_package(sku)
		if pkg.is_empty():
			continue
		# Acknowledge the purchase before crediting to avoid refunds
		_billing_plugin.acknowledgePurchase(purchase.get("purchaseToken", ""))
		_credit_coins(sku, pkg["coins"])
	_pending_sku = ""

func _on_purchase_error(response_id: int, debug_message: String) -> void:
	var sku := _pending_sku
	_pending_sku = ""
	push_error("IAPManager: purchase error %d — %s" % [response_id, debug_message])
	purchase_failed.emit(sku, debug_message)

func _on_sku_details_loaded(sku_details: Array) -> void:
	for detail in sku_details:
		var sku: String = detail.get("sku", "")
		if not sku.is_empty():
			_store_products[sku] = detail
	products_loaded.emit(get_packages())

# ── Private — credit coins server-side after purchase confirmed ───────────────

func _credit_coins(product_id: String, coins: int) -> void:
	if EconomyManager:
		await EconomyManager.purchase_coins(coins)
		purchase_completed.emit(product_id, coins)
		if NotificationUI:
			NotificationUI.notify_win("+%d 🪙 Coins added!" % coins)
	else:
		push_error("IAPManager: EconomyManager not available, coins not credited.")
		purchase_failed.emit(product_id, "EconomyManager unavailable")

func _find_package(product_id: String) -> Dictionary:
	for pkg in COIN_PACKAGES:
		if pkg["product_id"] == product_id:
			return pkg
	return {}
