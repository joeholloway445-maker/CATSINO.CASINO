class_name RealityLayers
## The six reality layers. CATSINO itself is the Hyperliminal layer — the
## casino IS one of the layers rather than sitting outside the cosmology.
## Each entry declares the layer's rules; managers enforce them.

const LAYERS: Array[Dictionary] = [
	{
		id="hyperliminal", name="Hyperliminal — Catsino",
		desc="The neon casino reality. Games of chance, districts, tournaments. Where everyone starts spending.",
		entry="always", pvp=false, persistence="static",
		scene="res://scenes/ui/main_menu.tscn",
		currency="chips",
	},
	{
		id="liminal", name="Liminal — The Between",
		desc="The connective tissue between realities. Multiplayer, procedurally generated, NEVER static — no chunk survives your departure. Wander too long and the Periliminal notices you.",
		entry="always", pvp=true, persistence="ephemeral",
		scene="res://scenes/layers/liminal.tscn",
		currency="tokens",
	},
	{
		id="subliminal", name="Subliminal — The Apartment",
		desc="Invite-only start screen and creator space, one small apartment per player. 3 outstanding invites max (creator subscription raises the cap). All UGC building happens here.",
		entry="invite", pvp=false, persistence="personal",
		scene="res://scenes/layers/subliminal.tscn",
		currency="charges",
	},
	{
		id="supraliminal", name="Supraliminal — DFW Metroplex",
		desc="The main MMORPG layer. Arlington is the neutral PvE center (Marketplace, Arena, Workshop, Space Station); Dallas, Fort Worth and Denton are the three faction hubs. Everything between and beyond is PvP, claimable, and scales infinitely off the chunk system.",
		entry="always", pvp="outside_hubs", persistence="chunked",
		scene="res://scenes/layers/supraliminal.tscn",
		currency="tokens",
	},
	{
		id="extraliminal", name="Extraliminal — The Overlay",
		desc="Pokemon-GO-style layer over the real world: roaming entities from the roster, guild halls at claimable landmarks, guild wars fought by opening a liminal door for your guild.",
		entry="always", pvp="guild_wars", persistence="landmark",
		scene="res://scenes/layers/extraliminal.tscn",
		currency="charges",
	},
	{
		id="periliminal", name="Periliminal Space",
		desc="The psychological layer. Reached only by wandering the Liminal too long. Procedurally generated, then static forever. Death loses EVERYTHING — entities, inventory, all of it. In a group, one death is everyone's death. High risk, highest rewards.",
		entry="liminal_wander", pvp=false, persistence="generated_then_static",
		scene="res://scenes/layers/periliminal.tscn",
		currency="fragments",
	},
]

static func by_id(layer_id: String) -> Dictionary:
	for l in LAYERS:
		if l.id == layer_id: return l
	return {}
