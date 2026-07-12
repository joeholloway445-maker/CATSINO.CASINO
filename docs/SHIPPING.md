# Shipping checklist — plug, play, market

**v0.1 goal = AAA Game of the Year** for Periliminal.Space. Gate table and
definition: [`docs/V01_GOTY.md`](V01_GOTY.md). Older “MVP complete” language
in other docs is historical; do not ship a hollow slice under that excuse.

## 1. Open it

Open `godot/project.godot` in **Godot 4.3+** (Forward+). First open imports
the MP3s and icon; hit Play. Boot flow: splash → login (or Play Offline) →
title screen, theme song playing. Every feature is reachable from the main
menu / layer spine.

## 2. What's fully playable today

- **Casino floor**: slots, poker, blackjack, coin pusher, fortune wheel,
  scratch cards, puzzle — with quests, achievements, battlepass, gacha,
  daily rewards, shop, tournaments, leaderboards.
- **Racing**: 5 tracks with level unlocks, entry fees, offline simulation,
  local racing cups (bracket tournaments).
- **The PVXC**: staked survival runs, 6x/12x zones, fights, revenge
  ledger, house-recovery ledger, extraction.
- **The overworld + reality layers**: streamed procedural terrain,
  day/night sky, third-person cat, discovery/influence painting,
  territory war + Conqueror crown; liminal wander → periliminal pulls
  with full-wipe rules; subliminal apartment with UGC blueprint slots
  and invites; arena hub with all six modes queueable.
- **Identity**: 20 races x 20 frames x 20 mods, ascension second frame,
  the lens (visuals + audio per build), perception RPS, crowns (all 60),
  champion→god ladder, six currencies, ~600 entities faction-gated.
- **Soundtrack**: five original tracks context-mapped, live per-build
  ambience.

## 3. AAA graphics — the asset drop (no code changes needed)

Full shopping list (addons, shaders, audio, web-vs-native rules):
`docs/ASSET_SHOPPING_LIST.md`. Install web-safe Godot addons with
`bash scripts/install_addons.sh` (see `docs/ADDONS.md`).

The engine-side pipeline is done: `AssetLibrary` checks
`assets/models/<slot>.glb` for every visual slot and upgrades the whole
game automatically, keeping the identity-lens shading. The environment
already runs ACES tonemapping, SSAO, SSIL, volumetric fog, and glow.

Because this sandbox's proxy can't fetch external repos, download these
yourself (all free/CC0, no attribution required) and drop the models in:

| Get this | From | Rename into `godot/assets/models/` as |
|---|---|---|
| A rigged cat/creature character | **Quaternius "Animated Animals"** (quaternius.com) or Kenney "Animal Pack" | `player_cat.glb`, `npc_cat.glb` |
| Monsters/creatures | **Quaternius "Ultimate Monsters"** | `creature.glb` |
| Trees, rocks | **Kenney "Nature Kit"** (kenney.nl) or Quaternius "Ultimate Nature" | `tree.glb`, `rock.glb` |
| Crystals | Quaternius "Cave Kit" / KayKit Dungeon | `crystal.glb` |
| Ruins/pillars | **KayKit "Dungeon Remastered"** (kaylousberg.itch.io) | `ruin_pillar.glb` |
| Sci-fi gate/portal | Quaternius "Ultimate Space Kit" | `extraction_gate.glb` |
| Loot containers | KayKit Dungeon (chests) | `harvest_node.glb` |
| Furniture (apartment) | Kenney "Furniture Kit" | `apartment_prop.glb` |

### Mega-city assets (DFW Metroplex hubs)

The mega-city is **fully functional procedurally today** — every hub
(Dallas, Fort Worth, Denton, Arlington) builds a real city on entry:
road grid, per-block buildings, streetlights + neon wired to the
day/night rig, and a per-district sound bed. Drop these in to replace the
procedural shells with real art — zero code changes (`MegaCityBuilder`
asks `AssetLibrary` for each slot first):

| Get this | From | Rename into `godot/assets/models/` as |
|---|---|---|
| Skyscrapers | **Kenney "City Kit (Commercial)"** / Quaternius "Ultimate Modular Buildings" | `city_tower.glb`, `city_lowrise.glb` |
| Houses | Kenney "City Kit (Suburban)" | `city_house.glb` |
| Warehouses | Kenney "City Kit" industrial pieces | `city_industrial.glb` |
| Roads/sidewalks | Kenney "City Kit (Roads)" | `road_segment.glb`, `sidewalk.glb` |
| Street lamps | Kenney "City Kit" props | `streetlight.glb` |
| Signage | any neon/billboard prop | `neon_sign.glb` |
| Benches/hydrants/bins | Kenney "City Kit" props | `city_prop.glb` |

**Interchangeable textures** — drop PBR maps into `godot/assets/textures/`
named `<slot>_albedo.png` (+ `_normal`, `_rough`, `_metallic`,
`_emissive`). The city asks for: `facade_glass`, `facade_concrete`,
`facade_brick`, `facade_metal`, `asphalt`, `sidewalk`, `neon`. Any that
exist are used; the per-race identity lens still tints on top, so the same
wall is a different material on every player's client.

**Interchangeable sounds** — drop looped audio into `godot/assets/audio/`
as `<slot>.ogg`: `city_traffic`, `city_crowd`, `neon_hum`, `machine_hum`.
Absent slots are synthesized live (traffic rumble, crowd murmur, neon
buzz, machine drone) so the city is never silent.

Also worth grabbing (bigger lifts, still free):
- **godotengine/tps-demo** (github) — reference-quality character
  controller + IK setup to graft onto `player_cat.glb`.
- **TokisanGames/Terrain3D** (GDExtension) — heightmap terrain with
  texture splatting to replace `ProceduralTerrain` meshes for hero areas.
- An HDRI sky pack (polyhaven.com, CC0) — drop into `assets/environments/`
  and point `DayNightSky` at it for photoreal skies.

## 4. Before the store page

- [ ] Set a real webhook URL for `DiscordTicketClient` (UGC review).
- [ ] Point `AccountManager` at your production Nakama host (offline
      fallbacks keep everything playable without it).
- [ ] Wire `EconomyManager.purchase_coins()` to the platform IAP SDK.
- [ ] Replace `assets/ui/icon.png` with final key art.
- [ ] Age/market review: PVXC + real-money coins = gambling-adjacent;
      check store policies per region.
- [ ] Marketing hooks that are true today: "No two players ever see or
      hear the same game" (engine-enforced), "480,000+ build identities,"
      "60 crowns, one Conqueror," "the casino has a basement."

## 5. Known simulation stand-ins (honest list)

These play, but resolve by simulation until bespoke gameplay lands:
arena modes (survival/zombies/CTF), PVXC creature fights (stat rolls, not
action combat), racing (results sim, no drivable vehicles), and other
players (creatures/AI stand in until Nakama presence is wired). None of
them block a playable build; all of them are the post-marketing roadmap.
