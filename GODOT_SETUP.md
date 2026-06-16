# CATSINO.CASINO — Godot 4 Setup Walkthrough

> Free-to-play virtual Cat Coins economy only. No real money, no sweeps, no redemption.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Godot 4 | 4.3+ | https://godotengine.org/download |
| Docker Desktop | Latest | https://www.docker.com/products/docker-desktop |
| Node.js | 20+ | https://nodejs.org |
| Git | Any | https://git-scm.com |

---

## Click-to-Start (Automated)

```bash
cd godot
bash setup.sh
```

This script:
1. Checks all prerequisites
2. Compiles Nakama TypeScript modules (`npm install && npm run build`)
3. Starts Nakama 3.21.1 + Postgres 14 via Docker
4. Waits until Nakama passes its health check
5. Prints next steps

---

## Manual Setup (Step by Step)

### Step 1 — Clone & Navigate

```bash
git clone https://github.com/joeholloway445-maker/catsino.casino.git
cd catsino.casino/godot
```

### Step 2 — Start Nakama Backend

```bash
docker-compose up -d
```

Wait ~15 seconds, then verify:
- Nakama Console → http://localhost:7351 (login: admin / password)
- Health endpoint → http://localhost:7350/healthcheck

### Step 3 — Open the Project in Godot

1. Launch **Godot 4.3**
2. Click **Import** in the Project Manager
3. Navigate to `catsino.casino/godot/`
4. Select `project.godot` → click **Import & Edit**

### Step 4 — Enable the Nakama Plugin

1. Go to **Project → Project Settings → Plugins** tab
2. Find **Nakama** in the list
3. Click the **Enable** checkbox ✓
4. Godot will reload — this is normal

### Step 5 — Verify Autoloads

Go to **Project → Project Settings → Autoload** tab. You should see:

| Name | Path |
|------|------|
| AutoloadInit | `res://src/core/autoload_init.gd` |
| GameManager | `res://src/core/game_manager.gd` |
| NetworkManager | `res://src/networking/network_manager.gd` |
| PlayerProfile | `res://src/character/player_profile.gd` |
| AchievementManager | `res://src/core/achievement_manager.gd` |
| QuestManager | `res://src/core/quest_manager.gd` |
| XPManager | `res://src/core/xp_manager.gd` |
| EventManager | `res://src/liveops/event_manager.gd` |
| FactionSystem | `res://src/social/faction_system.gd` |
| DailyRewards | `res://src/core/daily_rewards.gd` |
| BattlePass | `res://src/liveops/battlepass.gd` |
| NotificationUI | `res://src/ui/notification_ui.gd` |
| *(+ others)* | |

### Step 6 — Run the Game

Press **F5** (or click the Play button ▶).

- The splash screen loads at `res://scenes/ui/splash.tscn`
- Authentication happens automatically via Device ID (no login required for dev)
- The Output panel will show the CATSINO.CASINO startup banner

---

## Project Structure

```
godot/
├── setup.sh                  ← one-click setup
├── docker-compose.yml         ← Nakama + Postgres
├── project.godot              ← Godot project file
├── export_presets.cfg         ← Windows/Linux/macOS/Web exports
├── addons/
│   └── nakama/               ← Nakama GDScript client
│       ├── plugin.cfg
│       ├── nakama.gd          ← plugin entry point
│       ├── nakama_client.gd   ← HTTP auth + RPC calls
│       ├── nakama_session.gd  ← session token wrapper
│       └── nakama_socket.gd   ← real-time socket stub
├── assets/
│   ├── ui/                   ← icons, sprites
│   └── audio/                ← SFX, music
├── scenes/
│   ├── ui/                   ← splash, HUD, menus
│   ├── games/                ← slots, blackjack, poker...
│   ├── world/                ← district maps, NPCs
│   └── combat/               ← turn-based combat arena
└── src/
    ├── core/                 ← GameManager, QuestManager, XPManager...
    ├── character/            ← PlayerProfile, CharacterStats, CharacterCreatorLogic
    ├── games/
    │   ├── slots/            ← SlotGameManager, SlotsUI
    │   ├── racing/           ← RaceGameManager
    │   └── arcade/           ← Blackjack, Poker, Holdem, CatPuzzle, SpinWheel...
    ├── combat/               ← CombatManager (Light/Heavy/Tech RPS)
    ├── companion/            ← CompanionSynergy, CompanionEvolution
    ├── liveops/              ← BattlePass, EventManager, LiveOpsManager
    ├── social/               ← FactionSystem, GuildSystem, Leaderboard
    ├── world/                ← NPCSpawner, Minimap, DistrictTransition
    ├── ui/                   ← GachaUI, ShopUI, LoreUI, HUDOverlay...
    ├── networking/
    │   ├── network_manager.gd ← wraps NakamaClient; call_rpc(id, payload, cb)
    │   └── nakama_modules/   ← TypeScript server-side RPCs (30 modules)
    └── data/                 ← CompanionRegistry, NPCData, ItemData, ShopData...
```

---

## Nakama RPC Reference

All game logic is server-authoritative. Client calls `NetworkManager.call_rpc(id, payload_dict, callback)`.

| RPC ID | Game / Feature |
|--------|---------------|
| `spin_slots` | Slot machine spin |
| `play_blackjack` | Blackjack hand |
| `play_poker` | Video poker |
| `play_holdem` | Texas Hold'em |
| `draw_fortune` | Fortune spin wheel |
| `play_scratch` | Scratch card |
| `place_sports_bet` | Sports betting |
| `start_combat` / `submit_combat_move` | PvE combat |
| `start_race` | Cat racing |
| `gacha_pull` | Companion gacha summon |
| `get_shop_inventory` / `shop_purchase` | Shop system |
| `submit_puzzle_score` | Cat Puzzle arcade |
| `join_tournament` | Tournament entry |
| `submit_score` | Leaderboard score |
| `get_profile` / `update_profile` | Player profile |
| `get_wallet` / `add_coins` | Wallet management |
| `companion_evolve` | Companion evolution |
| `add_friend` / `get_friends` | Social system |
| `join_guild` / `list_guilds` | Guild system |
| `get_inventory` / `use_item` | Inventory |
| `update_quest` / `complete_quest` | Quest system |
| `claim_battlepass` | Battle pass reward |
| `get_event_status` | Live events |
| `unlock_achievement` | Achievements |
| `add_to_matchmaking` | Matchmaking queue |
| `send_chat` | Chat system |
| `get_economy_summary` | Economy overview |

---

## Exporting the Game

1. **Project → Export**
2. Select preset (Windows / Linux / macOS / Web)
3. Click **Export Project** → choose output folder
4. For Web export, serve `build/web/` with any static HTTP server:
   ```bash
   cd build/web && python3 -m http.server 8080
   ```

> Web exports require HTTPS in production (for SharedArrayBuffer / COOP headers).

---

## Nakama Console

After `docker-compose up -d`:

- **URL**: http://localhost:7351
- **Username**: `admin`
- **Password**: `password`

From the console you can:
- Browse registered accounts
- View leaderboard records
- Monitor RPC calls in the API explorer
- Inspect storage objects (wallets, profiles, quests)

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Nakama` singleton missing error | Enable plugin in Project Settings → Plugins |
| Docker containers not starting | Run `docker-compose logs nakama` for details |
| RPC returns HTTP 401 | Session expired — call `NetworkManager.authenticate_device()` |
| Scenes missing `@onready` nodes | Scene tree structure must match the `.tscn` node paths in scripts |
| `user://` save files corrupted | Delete files in `%APPDATA%\Godot\app_userdata\CATSINO.CASINO\` |
| Port 7350 already in use | Stop other Nakama instances: `docker-compose down` |

---

## Architecture Overview

```
┌─────────────────────────────────┐
│       CATSINO.CASINO CLIENT     │
│  ┌──────────┐  ┌─────────────┐ │
│  │ Godot 4  │  │ Next.js Web │ │
│  │ GDScript │  │ React 19    │ │
│  └────┬─────┘  └──────┬──────┘ │
│       │ NakamaClient  │ fetch  │
└───────┼───────────────┼────────┘
        │               │
┌───────▼───────────────▼────────┐
│       NAKAMA 3.21.1            │
│  TypeScript RPC Modules (30)   │
│  Leaderboards, Auth, Storage   │
└────────────────┬───────────────┘
                 │
┌────────────────▼───────────────┐
│     SUPABASE (PostgreSQL)      │
│  security definer RPCs         │
│  Server-authoritative RNG      │
│  14 migrations applied         │
└────────────────────────────────┘
```

---

*CATSINO.CASINO — virtual Cat Coins only. No real money, no sweeps, no redemption, no purchases.*
