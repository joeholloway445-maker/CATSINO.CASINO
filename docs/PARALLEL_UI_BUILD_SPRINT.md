# Parallel UI Build Sprint: 12-Hour Launch Path

**Status**: Ready to Execute  
**Timeline**: 12 hours elapsed, all 24 screens built simultaneously  
**Workers**: 6+ parallel AI agents (can spawn more if needed)  
**Output**: Production-ready Godot scene files (.tscn) for all screens

---

## Architecture: Parallel Agent Task Allocation

Instead of sequential weeks, deploy agents to build screens in parallel:

```
Agent 1: Screens 1-2 (Main Menu, Character Creator)
Agent 2: Screens 3-4 (HUD, Character Sheet)
Agent 3: Screens 5-7 (Inventory, Quest Log, Combat UI - CRITICAL)
Agent 4: Screens 8-10 (Dialogue, PvP Ranking, Achievement Notifications)
Agent 5: Screens 11-14 (Faction Rep, Cosmetics, Settings, Crafting)
Agent 6: Screens 15-18 (Status Effects, World Map, Level Up, Game Over)
Agent 7: Screens 19-22 (Notifications, Trading, Guild, Friend List)
Agent 8: Screens 23-24 (Options Menu, Loading Screen)
```

**No waiting between agents** - All start immediately, work in parallel.  
**Merge happens at end** - All .tscn files committed in one batch.

---

## Critical Path Screens (Build First, Deploy Immediately)

These 7 screens are launch-blockers. Agents should verify these work before client launch:

### 1. **Main Menu** (Agent 1, 1 hour)
- Asset status: ✅ CUSTOM LOGO, BACKGROUND, THEME SONG PROVIDED
- Implementation:
  - Load custom background image
  - Center logo with pulsing glow effect
  - Menu buttons: New Game, Continue, Settings, Credits, Exit
  - Play theme song on loop
  - Smooth fade transitions between states
- Godot scene: `scenes/ui/main_menu.tscn`
- Signals to wire: 
  - new_game_selected → CharacterCreator
  - continue_selected → LoadGame
  - settings_selected → SettingsMenu
  - quit_selected → get_tree().quit()

### 2. **Character Creator** (Agent 1, 2 hours)
**CRITICAL**: This is where players spend 10-15 minutes
- Architecture: Race → Frame → Mod (strict separation)
- Implementation:
  - **Step 1: Race Selection**
    - Grid of 20 cat breeds (4 columns × 5 rows)
    - Each has: name, texture preview, cat type, stat bonuses
    - Clicking race updates 3D model with race textures
    - Shows: fur pattern, primary color, size modifier
  - **Step 2: Frame Selection**
    - Grid of 20 frames (4 columns × 5 rows)
    - Each has: name, class description, icon
    - Clicking frame updates: HUD lighting color, ability bar layout, ability icons
    - Shows: light color, stat bonuses, 3 class abilities preview
  - **Step 3: Mod Selection**
    - Grid of 20 mods (4 columns × 5 rows)
    - Each has: name, description, armor visual
    - Clicking mod updates: armor appearance on 3D model, stat adjustments
    - Shows: stat modifiers, mobility/damage/defense multipliers
  - **Step 4: Final Confirmation**
    - Full 3D character preview with all selections applied
    - Name input field (pre-filled with "Race Frame Mod")
    - Confirm → Save character, enter world
  - Real-time preview: Update 3D model as selections change
- Godot scene: `scenes/ui/character_creator.tscn`
- Dependencies:
  - CharacterIdentitySystem (provides race/frame/mod data)
  - CharacterRig (3D model with materials)
  - RaceDataCharacter (race textures)

### 3. **Main HUD** (Agent 2, 1.5 hours)
**CRITICAL**: Overlay shown 100% of gameplay
- Implementation:
  - **Left side bars** (top-left):
    - Health bar (red, 200px wide)
    - Mana bar (blue, 200px wide)
    - Energy bar (yellow, 200px wide)
    - Smooth bar animations (0.3s lerp)
  - **Right side info** (top-right):
    - "Current Perception: 42" (player level equivalent)
    - "Current Prestige: 1,234 / 5,000" (progress bar + text)
  - **Bottom center: Ability Hotbar**
    - 8 slots (abilities 1-8)
    - Shows: Icon, keybind label (1-8), cooldown timer, cooldown ring
    - Status: Ready (glowing green), On Cooldown (grayed + timer), Disabled (red)
  - **Right side status effects** (below hotbar):
    - Icon grid for active effects
    - Hover shows: effect name, remaining duration, debuff/buff type
    - Color-coded (burn=red, freeze=blue, poison=green, etc.)
  - **Minimap** (top-right corner, if world map exists):
    - Small radar with player position
    - Can click to navigate
  - **Quest marker** (top-center):
    - Current quest objective text
    - Updates in real-time
- Godot scene: `scenes/ui/main_hud.tscn`
- Dependencies:
  - CombatSystemRealtime (for ability cooldowns, energy regen)
  - CharacterProgression (for stats display)

### 4. **Combat UI** (Agent 3, 1.5 hours)
**CRITICAL**: Live-action combat system
- Implementation:
  - **Enemy health bar** (top-center, above enemy):
    - Red bar with current/max HP (e.g., "450 / 600")
    - Smooth animations on damage
    - Boss indicator (red background if boss)
  - **Player stats** (left side, duplicates HUD but larger):
    - Health: Red bar with number
    - Mana: Blue bar with number
    - Energy: Yellow bar with number
    - Larger text (readable during fast combat)
  - **Ability hotbar** (bottom center, 8 slots):
    - Same as HUD but LARGER
    - Cooldown rings (360° visual countdown)
    - Energy cost label on each icon
    - Range indicator (green=in range, red=out of range)
  - **Damage numbers** (floating text, center of screen):
    - White text for normal hits
    - Gold text for crits
    - Red text for misses
    - Yellow text for heal/buff
    - Auto-disappear after 1 second
  - **Status effects display** (right side):
    - Active effects on player + enemy
    - Icon + remaining duration
    - Color-coded by effect type
  - **Casting bar** (if ability has cast_time > 0.3s):
    - Shows which ability is casting
    - Progress bar fills over cast duration
    - Can be interrupted
  - **No turn indicator** - This is real-time action
- Godot scene: `scenes/ui/combat_ui.tscn`
- Dependencies:
  - CombatSystemRealtime (for all data)

### 5. **Inventory UI** (Agent 3, 1 hour)
**CRITICAL**: Item management (frequently used)
- Implementation:
  - **Left panel: Inventory grid** (40 slots, 8 columns × 5 rows):
    - Drag-drop between slots
    - Right-click context menu: Equip, Drop, Sell, Discard
    - Color-coded by rarity: Gray=common, Green=uncommon, Blue=rare, Purple=epic, Gold=legendary
    - Stack counter (if stackable)
  - **Right panel: Equipment slots** (9 slots):
    - Head, Chest, Hands, Legs, Feet, Mainhand, Offhand, Amulet, Ring
    - Shows equipped item + stat bonuses
    - Click to unequip or swap
  - **Top bar: Currency display**:
    - Gold, Gems, Faction Tokens, etc.
  - **Search/filter bar**:
    - Type to search items by name
    - Filter by rarity, type, level requirement
  - **Sort options**:
    - By rarity, type, level, name
- Godot scene: `scenes/ui/inventory_ui.tscn`
- Dependencies:
  - InventorySystem (for item data)

### 6. **Quest Log** (Agent 3, 1 hour)
**CRITICAL**: Quest tracking (used frequently)
- Implementation:
  - **Left panel: Quest list** (scrollable):
    - Filter tabs: Active, Completed, Available
    - Quest names with status indicator
    - Color-coded by faction
    - Hover shows quest summary
  - **Right panel: Quest details**:
    - Quest title, description, faction affiliation
    - Objectives checklist with progress bars
    - Rewards preview (XP, currency, faction rep, items)
    - Map marker showing objective location
    - Branch indicator (if quest has multiple paths)
    - Abandon button (if active)
  - **Status colors**:
    - Green: Active
    - Gold: Complete (ready to turn in)
    - Gray: Available (not started)
    - Blue: Completed (already finished)
- Godot scene: `scenes/ui/quest_log.tscn`
- Dependencies:
  - QuestSystem (for quest data)

### 7. **Dialogue UI** (Agent 4, 1 hour)
**CRITICAL**: NPC interaction (core gameplay loop)
- Implementation:
  - **Left side: NPC portrait** (256×256):
    - Shows NPC face/character model
    - Character name above portrait
  - **Center: Dialogue text**:
    - Large readable font (36pt+)
    - Text appears with typewriter effect (optional)
    - NPC emotion indicator (shown as mood text or emoji)
  - **Bottom: Choice buttons** (3-5 options):
    - Each button is full-width, clickable area
    - Color-coded by faction affiliation
    - Hover highlights button
    - Click selects choice → continues dialogue
  - **Disposition bar** (subtle, below NPC name):
    - Small meter showing NPC's feeling toward player (-10 to +10)
    - Updates based on dialogue choices
  - **Auto-continue arrow** (if dialogue has multiple lines without choices):
    - Blink indicator prompting click to continue
- Godot scene: `scenes/ui/dialogue_ui.tscn`
- Dependencies:
  - NPCDialogueSystem (for dialogue data)
  - DispositionSystem (for NPC feelings)

---

## Secondary Screens (7 screens, deploy week 1-2)

### 8. **Character Sheet** (Agent 2, 1 hour)
- Tab system: Stats, Skills, Equipment, Titles, Achievements
- Large stat display with detailed breakdowns
- Skill tree visualization (shows learned skills + available skills)
- Equipment comparison (if hovering over new item)

### 9. **PvP Ranking** (Agent 4, 45 min)
- Current rating (large centered number)
- Tier badge (Bronze-Grandmaster)
- Win/loss record
- Top 100 leaderboard (scrollable)
- Rating change history (last 10 matches)

### 10-24. **Other Screens** (Agents 5-8)
- See detailed spec in original Screen List document

---

## Build Command Sequence (For Parallel Execution)

Each agent runs this sequence simultaneously:

```bash
# Agent 1: Screens 1-2
godot_build_screen("main_menu")
godot_build_screen("character_creator")

# Agent 2: Screens 3-4
godot_build_screen("main_hud")
godot_build_screen("character_sheet")

# Agent 3: Screens 5-7 (CRITICAL)
godot_build_screen("inventory_ui")
godot_build_screen("quest_log")
godot_build_screen("combat_ui")

# [Continue for other agents...]

# When all agents finish:
git merge all scenes/ui/ changes
git commit -m "feat: all 24 UI screens complete"
git push
```

---

## Testing & Validation Checklist

Each agent must verify their screens before marking complete:

### Per-Screen Validation
- [ ] Scene loads without errors
- [ ] All signals connected correctly
- [ ] Responsive to data changes (real-time updates)
- [ ] No memory leaks (GDScript profiling)
- [ ] Button presses execute intended actions
- [ ] Animations are smooth (target 60fps)
- [ ] Text is readable (font sizes 24pt+)
- [ ] Mobile responsive (if applicable)

### Critical Screens Extra Validation (1-7)
- [ ] Main Menu: Theme song plays, transitions smooth
- [ ] Character Creator: 3D model updates real-time, no lag
- [ ] HUD: All bars update, cooldown rings visible
- [ ] Combat UI: Damage numbers appear, abilities queue
- [ ] Inventory: Drag-drop works, equip/unequip instant
- [ ] Quest Log: Branching quests display correctly
- [ ] Dialogue: Choices update disposition, dialogue flows

---

## Asset Requirements Summary

| Screen | Custom Assets Needed | Status |
|--------|---------------------|--------|
| 1. Main Menu | Background, Logo, Theme Song | ✅ PROVIDED |
| 2. Character Creator | Race texture presets | ⚠️ Using Perchance generated |
| 3-7. Critical Screens | UI icons (status effects, abilities) | 🔄 Generate via cosmetics gen |
| 8-24. Other Screens | Faction-specific icons | 🔄 Font Awesome icons + custom |

---

## Deployment Flow (After 12 Hours)

1. **Hour 12**: All agents commit their scenes
2. **+15 min**: Code review (spot-check critical screens)
3. **+30 min**: Integration test (all screens link correctly)
4. **+1 hour**: Visual polish pass (lighting, animations, colors)
5. **+SHIP**: Deploy to beta testers

**Total elapsed: ~13.5 hours** for production-ready UI

---

## Troubleshooting

**Screen won't load:**
- Check dependencies (parent scripts exist)
- Verify signal connections
- Check for circular dependencies

**Lag/performance issues:**
- Profile with `print_debug()` statements
- Reduce animation complexity
- Batch visual updates (don't update every frame)

**Data not syncing:**
- Verify signals emit from backend systems
- Check _process vs _ready for data initialization
- Log all signal emissions

---

## Success Criteria

✅ All 24 screens load without errors  
✅ Critical 7 screens fully functional  
✅ All signals connected to backend systems  
✅ 60fps performance on target hardware  
✅ Ready for client launch with backend servers
