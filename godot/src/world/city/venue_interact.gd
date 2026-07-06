class_name VenueInteract
extends Node
## Armed while the player stands inside a venue's ring: E opens the venue's
## real system. Self-frees when the player walks away. Kept as its own node
## so venue interaction survives across whatever scene hosts the city.

var kind := ""
var player: Node3D
var venue_root: Node3D

const RING_RADIUS := 10.0

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E):
		return
	match kind:
		"market", "armorer", "blacksmith":
			_open_marketplace(kind)
		"bank":
			get_tree().change_scene_to_file("res://scenes/ui/city_services.tscn")
		"wager_hall":
			# The referendum floor lives in the arena hub UI's vote section.
			get_tree().change_scene_to_file("res://scenes/ui/arena_hub.tscn")
		"stockyards":
			NotificationUI.notify_info("🐎 The Stockyards: swing at the dummies — MELEE, RANGED, UNARMED, GUNS. Practice is the only teacher here.")
		_:
			pass

func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player) or venue_root == null or not is_instance_valid(venue_root):
		queue_free()
		return
	if player.global_position.distance_to(venue_root.global_position) > RING_RADIUS + 8.0:
		queue_free()

## The vendor stalls: market = merchants/consumables, armorer = armor
## listings, blacksmith = weapon listings — all Marketplace vendor wares.
func _open_marketplace(venue_kind: String) -> void:
	var vendor_id := {"market": "merchant", "armorer": "armorer", "blacksmith": "blacksmith"}.get(venue_kind, "merchant")
	var vendor := Marketplace.vendor_by_id(vendor_id)
	if vendor.is_empty():
		return
	var listings := Marketplace.listings_for(vendor.get("wares", []))
	if listings.is_empty():
		NotificationUI.notify_info("%s %s: \"%s\" — no canon stock listed yet. The Forge awaits creators." % [vendor.icon, vendor.name, vendor.desc])
		return
	var lines: Array[String] = []
	for l in listings.slice(0, 5):
		lines.append("%s by %s — %d 🪙" % [l.name, l.author, l.price])
	NotificationUI.notify_info("%s %s stock:\n%s" % [vendor.icon, vendor.name, "\n".join(lines)])
