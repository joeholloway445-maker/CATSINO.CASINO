# Periliminal.Space UI Screen Inventory

**Total Screens to Build**: 24  
**Status**: Architecture ready, templates building  
**Implementation Order**: 1-24 (prioritized by critical path)

---

## TIER 1: CRITICAL PATH (Must launch with these)

### 1. **Main Menu**
- New Game | Continue | Settings | Credits | Exit
- Background: **[USER CUSTOM BACKGROUND PROVIDED]**
- Logo: **[USER CUSTOM LOGO PROVIDED]**
- Music: **[USER CUSTOM THEME SONG PROVIDED]**
- Status: ✅ CUSTOM ASSETS READY, BUILD IMPLEMENTATION

### 2. **Character Creator**
**ARCHITECTURE**: Races → Frames → Mods (strictly segregated), sourced from the
canonical OmniDex registry (`OmniDexRegistry`, `RaceDataCharacter`,
`CanonRaces`, `MorphRigData`) — this is the actual shipped data, not a
placeholder.

**RACES (20 canon races, each order-mapped 1:1 to a cat type - TEXTURE DRIVERS)**
- 20 canon Periliminal race names (Keth, Lumari, Vex, Ferox, Azhul, Sylva,
  Geara, Nyx, Aquis, Igni, Kryos, Myco, Volt, Petra, Sanguis, Chimera,
  Astra, Ferros, Etherea, Glyphe), each rendered in the Hyperliminal casino
  as a specific cat breed (Tabby, Siamese, Maine Coon, ... Savannah) —
  `CanonRaces.canon_for_id()` does the mapping
- Texture type, primary color, fur pattern, size modifier come from the
  cat-breed record (`RaceDataCharacter`); display name comes from the
  canon race (`OmniDexRegistry.race_display_name`)
- Preview: Full 3D cat model with race textures

**FRAMES (20 Periliminal identity frames = our classes - ROLE DRIVERS)**
- Skirmisher, Strider, Skybound, Flicker, Marshal, Bloom, Rewind, Conduit,
  Shade, Fabricator (light type) + Bastion, Juggernaut, Gravemind,
  Riftbreaker, Sovereign, Worldroot, Epoch, Overlord, Obscura, Architect
  (heavy type)
- Each frame has a distinct role (Duelist, Scout, Aerialist, Tactician,
  Bruiser, Controller, Territory Holder, Time Warden, Detonator,
  Veilkeeper, Fortifier, etc.) — this is the class layer, not a visual
  reskin
- Frame selection changes HUD identity and available ability kit

**MODS (20 morphological rigs - PHYSICAL/MOBILITY/COMBAT-MATH DRIVERS)**
- Heavy Siege, Swiftburner, Multi-Limbed, Towering, Compact, Elastic,
  Floating Core, Split Form, Inverted Spine, Modular, Armored, Lithe,
  Tendril, Rooted, Hover Strider, Centroid, Shardform, Quadruped,
  Serpentine, Colossus
- Each mod is a body plan: one bonus, one drawback (e.g. Heavy Siege:
  +Stability / -Momentum) that drives mobility and combat math — this is
  the physical layer, distinct from Race (texture) and Frame (class)

**FLOW**: Race selected → Preview cat texture | Frame selected → Preview role + kit | Mod selected → Preview bonus/drawback + silhouette

**FINAL PREVIEW**: Real-time 3D character with:
- Race texture + fur pattern
- Frame role/identity
- Mod bonus/drawback + silhouette
- Estimated combined stat values

### 3. **Main HUD (In-Game Overlay)**
- Health bar (top-left)
- Mana bar (top-left, below health)
- Energy bar (top-left, below mana)
- **Current Perception** (top-right) — CHANGED FROM "Current Level"
- **Current Prestige** (top-right, below Perception) — CHANGED FROM "Current XP Progress"
- Minimap (top-right corner)
- Ability hotbar (bottom, 8 slots for abilities 1-8)
- Status effects display (small icons, right side below abilities)
- Quest marker (top-center, updates per active quest)
- FPS counter (top-right, debug mode only)

### 4. **Character Sheet**
Tab System:
- **Stats Tab**: All 10 core stats (health, mana, energy, strength, intelligence, agility, wisdom, defense, speed, attack)
- **Skills Tab**: Learnable skills per tree (Warrior, Mage, Ranger), with level locks and cost display
- **Equipment Tab**: All 9 equipment slots, gear stats, rarity color coding
- **Titles Tab**: Active title, available titles with stat bonuses
- **Achievements Tab**: Unlocked achievements, progress on in-progress achievements

### 5. **Inventory UI**
- 40-item grid display
- Item slots: Common (gray), Uncommon (green), Rare (blue), Epic (purple)
- Drag-drop between slots
- Right-click context menu: Equip, Drop, Sell, Discard
- Equipment preview on right side (shows what items affect)
- Currency display (top-right: Gold, Crystal Shards, Faction Tokens)
- Search/filter bar
- Sort options (rarity, type, level requirement)

### 6. **Quest Log**
- Quest list (left sidebar, filterable by faction/status)
- Current quest details (center panel)
- Objectives checklist with progress bars
- Quest rewards preview (XP, currency, faction rep, items)
- Map marker for objective location
- Abandon quest button
- Branch visualization (if quest has multiple paths)

### 7. **Combat UI (LIVE ACTION - NO TURNS)**
**ARCHITECTURE**: Real-time action-based combat with cooldowns

- **Enemy health bar** (above enemy, real-time updates)
- **Player health/mana/energy** (left side, large bars with continuous regen visualization)
- **Ability hotbar** (bottom, 8-slot with COOLDOWN RINGS not turn order)
  - Each ability shows: remaining cooldown, range indicator
  - Ability unavailable: grayed out + cooldown timer
  - Ability ready: glowing green
- **Energy system** (replaces turn cost):
  - Abilities cost energy (depletes on use)
  - Energy regenerates over time (10/sec in combat)
  - Full recharge: ~10 seconds
- **Damage numbers** (floating text, color-coded: white=normal, gold=crit, red=miss)
- **Status effects** (icon display, duration bar per effect)
- **Range indicator** (shows if target is in ability range)
- **Positioning** (shows distance to enemy, affects ability availability)
- **Casting bar** (if ability has cast time > 0.3s)
- **No turn indicator** - actions are simultaneous/parallel

### 8. **Dialogue UI**
- NPC portrait (left side)
- NPC name (above portrait)
- Dialogue text (center, large readable font)
- Choice buttons (bottom, 3-5 options per dialogue node)
- Disposition indicator (small meter showing NPC's feeling toward you)
- Continue arrow (if dialogue has multiple lines)
- Skip/Auto-play options

### 9. **PvP Ranking Display**
- Current rating (large number, center)
- Current tier (visual badge, Bronze-Grandmaster)
- Rating change (last match: +32, -15, etc.)
- Wins/losses record (50 wins, 30 losses)
- Top 100 leaderboard (scrollable, top-right)
- Rating distribution chart (rank vs. MMR)
- Seasonal rank

### 10. **Achievement Notifications**
- Pop-up (top-right corner)
- Icon + achievement name
- Point value earned
- Auto-dismiss after 5 seconds
- Sound effect + visual flourish (particle effect)

---

## TIER 2: SOCIAL/PROGRESSION (Launch + 2 weeks)

### 11. **Faction Reputation Panel**
- 4 faction rows: Sovereign Crown, Veiled Current, Wildlands, Factionless
- Reputation bar per faction (-300 to +300 scale)
- Tier badge (showing current standing)
- Faction-specific perks/unlocks at each tier
- Reputation change log (recent actions that affected rep)

### 12. **Cosmetics Shop (1,000+ COSMETICS)**
- **Category tabs**: 
  - Transmog (armor/outfits, 400+ variants)
  - Auras (energy effects, 150+ variants)
  - Particles (ability VFX, 200+ variants)
  - Titles (stat-boosting cosmetics, 100+ variants)
  - Emotes (character animations, 150+ variants)
  - Pets (companion cosmetics)
- **Item grid** (1,000+ cosmetics with prices)
- **Price tiers**: 
  - Common: 100 gems
  - Rare: 500 gems
  - Epic: 2000 gems
  - Legendary: 5000 gems
- **Purchase button** + currency validation
- **Equipped indicator** (gold star, checkmark)
- **Preview on player model** (real-time update)
- **Filter/search**:
  - By category
  - By rarity
  - By price
  - By name (search bar)
- **Favorites system** (star icon to bookmark)
- **Limited edition tracker** (time-limited cosmetics with countdown)

### 13. **Settings Menu**
- **Audio**: Master volume, SFX volume, Music volume, Voice volume, Mute option
- **Graphics**: Resolution, FPS cap, Vsync, Anti-aliasing, Shadows, Draw distance
- **Gameplay**: Difficulty, Auto-loot, Show damage numbers, Show FPS, Screen shake intensity
- **Accessibility**: Color blind mode, Large text, Subtitle size, Controller dead-zone
- **Keybinds**: Remappable keys for all abilities and actions
- **Account**: Change password, Log out, Delete account

### 14. **Crafting UI**
- Recipe list (left sidebar, filterable)
- Selected recipe details (center)
  - Required materials (with "have X/need Y" indicators)
  - Crafting time (countdown timer during crafting)
  - XP reward
  - Result preview
- Crafting queue (right panel, shows in-progress crafts)
- Craft button (disabled if materials insufficient)
- Material inventory quick-view

### 15. **Status Effects Display**
- Large icon grid (during combat)
- Tooltip on hover (shows effect name, duration, stat changes)
- Removal option (if player can cleanse)
- Color-coded by effect type (burn=red, freeze=blue, poison=green, stun=yellow, confusion=purple, bleed=crimson, weakness=gray, vulnerability=orange)

### 16. **World Map**
- Full overworld map showing all 6 layers
- Waypoints (fast travel points)
- Quest markers
- Current player position (blinking marker)
- Legend (location types)
- Zoom in/out controls
- Pan with mouse/stick

### 17. **Level Up Screen**
- Level number (large, center)
- Stat increases preview
- Skill point allocation (spend 2 points on skills)
- Continue button

### 18. **Game Over Screen**
- You Defeated! / You Survived!
- Rewards earned (XP, currency, items)
- Best performance stat (highest damage, fastest victory, etc.)
- Retry / Main Menu buttons
- Session summary (kills, deaths, time played)

---

## TIER 3: QUALITY OF LIFE (Launch + 1 month)

### 19. **Notifications Panel**
- Quest updates
- Faction rep changes
- Achievement unlocks
- Friend activity (multiplayer)
- Event announcements

### 20. **Trading Interface**
- Player inventory (left)
- Trade window (center, drag items to propose)
- Other player inventory (right)
- Accept/Decline buttons
- Safety confirmation ("Are you sure?")

### 21. **Guild Interface**
- Guild name and emblem
- Members list with roles
- Treasury (shared guild items)
- Guild hall decorations
- Message board

### 22. **Friend List**
- Online friends (green indicator)
- Offline friends (gray)
- Add friend button
- Invite to party
- Private message

### 23. **Options Menu (Mid-Game)**
- Quick return to main menu
- Save game
- Load game
- Exit without saving

### 24. **Loading Screen**
- Animated background (layer-specific)
- Loading bar
- Random lore tips
- Asset streaming status
- Music continues seamlessly

---

## UI Color Scheme

### Faction Colors
- **Sovereign Crown**: Gold (#FFD700), Silver (#C0C0C0), White (#FFFFFF)
- **Veiled Current**: Deep Purple (#4B0082), Midnight Blue (#191970), Dark Teal (#003333)
- **Wildlands Ascendant**: Emerald Green (#50C878), Amber (#FFBF00), Bronze (#CD7F32)
- **Factionless**: Neutral Gray (#808080), Dark Gray (#A9A9A9)

### Rarity Colors
- **Common**: Gray (#808080)
- **Uncommon**: Green (#32CD32)
- **Rare**: Blue (#1E90FF)
- **Epic**: Purple (#9932CC)
- **Legendary**: Gold (#FFD700)

### UI Element Standards
- **Text**: Use clear sans-serif (Arial, Roboto)
- **Buttons**: 40px height minimum, hover state brightens by 20%
- **Bars**: Smooth animation (0.3s transition)
- **Icons**: 32x32px or 48x48px, vectorized for clarity
- **Shadows**: Soft drop shadow (5px blur, 30% opacity)
- **Borders**: 2px rounded corners, faction-color borders

---

## Implementation Priority

**STATUS**: PARALLEL BUILD - ALL SCREENS SIMULTANEOUSLY (not sequential)

**CRITICAL PATH (Launch blockers - must ship day 1)**:
1. Main Menu (custom assets ready)
2. Character Creator (identity system complete)
3. Main HUD (live action overlay)
4. Combat UI (live action real-time)
5. Inventory UI (item equip/management)
6. Quest Log (objective tracking)
7. Ability Hotbar (linked to combat system)

**SECONDARY (Ship week 1-2)**:
- Character Sheet
- Dialogue UI
- PvP Ranking
- Achievement Notifications
- Faction Reputation
- Cosmetics Shop (1,000+ items)
- Settings
- Crafting UI
- Status Effects Display
- World Map
- Level Up Screen
- Game Over Screen

**TERTIARY (Nice to have, post-launch)**:
- Notifications Panel
- Trading Interface
- Guild Interface
- Friend List
- Options Menu
- Loading Screen

**BUILD STRATEGY**: Deploy **parallel agent teams** per screen (not sequential weeks)

---

## Asset Requirements Per Screen

| Screen | Images | Icons | Animations |
|--------|--------|-------|------------|
| Main Menu | 3 (bg, logo, buttons) | - | 2 (fade-in, button pulse) |
| Character Creator | 20 race base, 20 frame, 20 mod overlays | - | 1 (preview rotation) |
| Main HUD | 1 (background) | 50 (status, ability icons) | 8 (bar animations) |
| Inventory | - | 50+ (item icons) | 1 (item pickup animation) |
| Combat UI | 1 (background) | 30 (ability icons) | 5 (damage numbers, floats) |
| **Total** | **25** | **180+** | **20+** |

---

## Godot Implementation Notes

- All screens as `.tscn` prefab files
- Responsive design (supports 1920x1080, 1280x720, mobile)
- Signal-based communication between screens
- Theme system for easy recoloring per faction
- Exported variables for easy content update (no code changes needed for text/images)
