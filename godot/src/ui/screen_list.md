# Periliminal.Space UI Screen Inventory

**Total Screens to Build**: 24  
**Status**: Architecture ready, templates building  
**Implementation Order**: 1-24 (prioritized by critical path)

---

## TIER 1: CRITICAL PATH (Must launch with these)

### 1. **Main Menu**
- New Game | Continue | Settings | Credits | Exit
- Background: Animated liminal space
- Logo center
- Music: Ambient layer theme

### 2. **Character Creator**
- Race selection (20 races, 3-option preview per race)
- Frame selection (20 frames, visual overlay)
- Mod selection (20 mods, final appearance preview)
- Full body preview (real-time update as selections change)
- Name input field
- Confirm / Back buttons

### 3. **Main HUD (In-Game Overlay)**
- Health bar (top-left)
- Mana bar (top-left, below health)
- Energy bar (top-left, below mana)
- Current level (top-right)
- Current XP progress (top-right, below level)
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

### 7. **Combat UI**
- Initiative order display (top-center, shows turn sequence)
- Enemy health bar (center, above enemy sprite)
- Player health/mana/energy (left side, large bars)
- Ability icons (bottom, 8-slot hotbar with cooldown rings)
- Damage numbers (floating text when hits land)
- Status effects on player/enemy (icon display)
- Turn indicator (whose turn is it?)
- Special attack warning (red highlight when under attack)

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

### 12. **Cosmetics Shop**
- Category tabs (Transmog, Auras, Particles, Titles)
- Item grid (cosmetics with prices)
- Purchase button + currency validation
- Equipped cosmetic indicator (checkmark)
- Preview on player model
- Filter by rarity/type

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

**Week 1** (screens 1-10):
- Main Menu
- Character Creator
- Main HUD
- Character Sheet
- Inventory
- Quest Log
- Combat UI
- Dialogue UI
- PvP Ranking
- Achievement Notifications

**Week 2** (screens 11-18):
- Faction Reputation
- Cosmetics Shop
- Settings
- Crafting
- Status Effects
- World Map
- Level Up Screen
- Game Over Screen

**Week 3+** (screens 19-24):
- Notifications Panel
- Trading Interface
- Guild Interface
- Friend List
- Options Menu
- Loading Screen

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
