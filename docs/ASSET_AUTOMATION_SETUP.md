# Asset Automation Pipeline: Perchance + n8n + Kenney/Sonniss

## Overview

This document outlines how to auto-generate visual assets (entity sprites, race visuals with frame/mod variants) and integrate community audio packs.

---

## Part 1: Visual Asset Generation via Perchance.org

### Setup: Perchance Generator Configuration

1. **Create a new Perchance generator** at perchance.org with the following structure:

```
[entity_visual_generator]

# Entity Name + Lore Injection
[entity_name]
[main_entity_lore]

# Category-Specific Visuals
[category_selector]
Energy => {stellar_plasma, radiant_humanoid, photonic_form, energy_aura}
Entropy => {skeletal_decay, void_black, time_erosion, degradation_pattern}
Gravity => {compressed_matter, stellar_core, tectonic_armor, graviton_field}
Matter => {organic_structure, crystalline_form, metallic_composite, biomatter}
Psyche => {consciousness_manifested, ethereal_ghost, fractured_mind, symbolist_form}
Quantum => {probability_cloud, superposition_shimmer, multiversal_echo, uncertainty_aura}

# Stage Progression
[stage_selector]
Stage 1 => {proto_form, unrefined, raw_potential, nascent}
Stage 2 => {matured_form, specialized, developed, refined}
Stage 3 => {apex_form, perfected, ultimate, transcendent}

# Faction Color Overlay
[faction_selector]
SovereignCrown => {gold_accent, silver_trim, precision_geometry, ordered_form}
VeiledCurrent => {indigo_mist, shadow_veil, cryptic_symbol, dreamlike_quality}
WildlandsAscendant => {verdant_green, feral_markings, organic_chaos, primal_energy}
Factionless => {neutral_grey, unmarked, elemental_purity, undefined_form}

# Final Prompt Template
A {stage_selector} {entity_name} of the {category_selector} category, bearing the {faction_selector} aesthetic. {main_entity_lore}. Illustration style: high fantasy character design, 4K quality, concept art. Award-winning digital painting.
```

2. **Run generation for all 144 entities**:
   - 6 categories × 24 entities per category × 3 stages = 432 images
   - 4 faction variants per base = up to 1,728 total variations
   - **Start with core 144** (one stage-2 per entity), then expand to all stages/factions

3. **Integration**: Save outputs to `godot/assets/entities/` organized by:
   ```
   godot/assets/entities/
   ├── SovereignCrown/
   │   ├── Energy/
   │   │   ├── Surling_stage1.png
   │   │   ├── Surling_stage2.png
   │   │   └── Surling_stage3.png
   │   └── Entropy/
   │       └── ...
   ├── VeiledCurrent/
   └── ...
   ```

### Race/Frame/Mod Visual Variants

1. **Perchance: Race Appearance Generator**

```
[race_frame_mod_generator]

# Base Race Form
[race_selector]
Luminant => {translucent_aura, light_bending, spectral_form, refracted_silhouette}
Kinetic => {motion_trails, speed_blur, afterimage_body, momentum_visuals}
Chronal => {temporal_scars, aging_variation, temporal_echoes, time_worn}
Harmonic => {resonant_patterns, vibrating_aura, musical_geometry, sound_waves}
... [20 total races]

# Frame/Sensorium Overlay
[frame_selector]
Veil => {violet_hush, mystical_glow, ethereal_quality, breathlike_shimmer}
Zephyr => {clear_light, windswept_appearance, airy_presence, flowing_form}
Crimson => {war_scarlet, intense_aura, passionate_fire, dominant_presence}
... [20 total frames]

# Mod Interaction Visual
[mod_selector]
Sync => {entity_bond_visible, harmonic_resonance, unified_form, synchronized_aura}
Wraith => {ghostly_transparency, barely_visible, shadow_form, unnoticed_appearance}
Symbiote => {creature_merged, integrated_body, fused_form, hybrid_appearance}
... [20 total mods]

# Final Template
A {race_selector} player character, embodying the {frame_selector} frame, {mod_selector} modification. Full-body portrait. Fantasy character design, high detail, 4K quality.
```

2. **Batch Generation Strategy**:
   - Start with **20 base race images** (neutral frame/mod)
   - Generate **20 frame variants** (one per frame, neutral race/mod)
   - Generate **20 mod variants** (one per mod, neutral race/frame)
   - Combine into a visual matrix players can browse

3. **Storage**:
   ```
   godot/assets/player_visuals/
   ├── races/
   │   ├── Luminant.png
   │   ├── Kinetic.png
   │   └── ... [20 total]
   ├── frames/
   │   ├── Veil.png
   │   ├── Zephyr.png
   │   └── ... [20 total]
   └── mods/
       ├── Sync.png
       ├── Wraith.png
       └── ... [20 total]
   ```

---

## Part 2: n8n Workflow for Automation

### n8n Flow: Batch Perchance Generation

Create an n8n workflow to:
1. Read entity roster from `entity_dex_data.gd`
2. Generate Perchance prompts for each entity
3. Call Perchance API (if available) or queue manual generation with progress tracking
4. Download generated images
5. Organize into godot/assets/ directories
6. Log completion status

**Workflow Nodes**:

```
Start
  ↓
[Read Entity Database] → Load 144 entities
  ↓
[Generate Prompts] → Create Perchance prompts per entity
  ↓
[Batch to Perchance] → Queue generation (split into chunks of 20)
  ↓
[Poll Status] → Check progress every 60s
  ↓
[Download & Organize] → Save to godot/assets/entities/
  ↓
[Generate Manifest] → Create asset_manifest.json
  ↓
End
```

**Asset Manifest Output** (`godot/assets/entity_manifest.json`):
```json
{
  "generated_at": "2026-07-10T22:00:00Z",
  "total_entities": 144,
  "by_faction": {
    "SovereignCrown": 48,
    "VeiledCurrent": 48,
    "WildlandsAscendant": 48,
    "Factionless": 0
  },
  "by_category": {
    "Energy": 24,
    "Entropy": 24,
    "Gravity": 24,
    "Matter": 24,
    "Psyche": 24,
    "Quantum": 24
  },
  "assets": [
    {
      "entity_id": "SC-EN1",
      "name": "Surling",
      "stage": 2,
      "image_path": "res://assets/entities/SovereignCrown/Energy/Surling_stage2.png",
      "generated": true
    }
    ...
  ]
}
```

---

## Part 3: Audio Asset Integration (Kenney + Sonniss)

### Kenney Audio Pack Integration

**Already documented in `docs/ADDONS.md`**. Kenney packs include:
- UI sounds (button clicks, confirmations, errors)
- Footsteps (multiple surfaces)
- Ambiences (per-layer, per-faction)
- Music stings

**Asset Structure**:
```
godot/assets/audio/
├── kenney/
│   ├── ui/
│   │   ├── button_click.ogg
│   │   ├── confirm.ogg
│   │   └── error.ogg
│   ├── footsteps/
│   │   ├── stone_walk.ogg
│   │   ├── metal_walk.ogg
│   │   └── soft_walk.ogg
│   ├── ambience/
│   │   ├── subliminal_hum.ogg
│   │   ├── liminal_whisper.ogg
│   │   └── periliminal_dread.ogg
│   └── music/
│       ├── sovereign_crown_theme.ogg
│       ├── veiled_current_theme.ogg
│       └── wildlands_theme.ogg
└── sonniss/
    ├── sfx/
    │   ├── entity_roar.ogg
    │   ├── combat_hit.ogg
    │   └── magical_cast.ogg
    └── music/
        ├── boss_theme.ogg
        └── victory_theme.ogg
```

### AssetLibrary Integration (Already Exists)

The game already has `AssetLibrary.sound()` hooks (per `docs/ADDONS.md`). Wire it:

```gdscript
# In src/audio/asset_library.gd (already exists)
func sound(sound_key: String) -> AudioStream:
	var path_map = {
		"ui_button": "res://assets/audio/kenney/ui/button_click.ogg",
		"ui_confirm": "res://assets/audio/kenney/ui/confirm.ogg",
		"footstep_stone": "res://assets/audio/kenney/footsteps/stone_walk.ogg",
		"ambience_subliminal": "res://assets/audio/kenney/ambience/subliminal_hum.ogg",
		"music_crown": "res://assets/audio/kenney/music/sovereign_crown_theme.ogg",
		"entity_roar": "res://assets/audio/sonniss/sfx/entity_roar.ogg",
		# ... more mappings
	}
	return ResourceLoader.load(path_map.get(sound_key, ""))
```

### Sonniss GDC Bundle

Download from: https://sonniss.com/gdc-bundle/

Contains:
- 1000+ royalty-free SFX
- Multiple music tracks
- Instrument samples

**Recommended selections for Periliminal.Space**:
- Entity vocalization (creature sounds)
- Combat impacts (blade, magic, explosions)
- Periliminal psychological effects (warping, breaking, distortion)
- Boss themes
- Victory/defeat fanfares

**Organization**:
```
godot/assets/audio/sonniss/
├── entity_sounds/
│   ├── creature_roar.ogg
│   ├── alien_chirp.ogg
│   └── ...
├── combat/
│   ├── slash_metal.ogg
│   ├── impact_heavy.ogg
│   └── ...
├── periliminal/
│   ├── reality_warp.ogg
│   ├── mind_break.ogg
│   └── ...
└── music/
    ├── boss_theme.ogg
    └── victory.ogg
```

---

## Integration Checklist

- [ ] **Entity Visuals**: Generate 144 entity stage-2 images via Perchance
- [ ] **Race Variants**: Generate 20 race base visuals
- [ ] **Frame Variants**: Generate 20 frame overlay visuals
- [ ] **Mod Variants**: Generate 20 mod variant visuals
- [ ] **Asset Manifest**: Create and validate JSON
- [ ] **n8n Workflow**: Set up automation pipeline
- [ ] **Kenney Audio**: Download and organize into godot/assets/audio/kenney/
- [ ] **Sonniss Audio**: Download and organize into godot/assets/audio/sonniss/
- [ ] **AssetLibrary Wiring**: Update sound() mappings
- [ ] **Perchance Account**: Create, configure, populate
- [ ] **n8n Deployment**: Deploy workflow (self-hosted or n8n.cloud)

---

## Launch Timeline

**Phase 1 (Week 1)**: 
- Set up Perchance generator
- Start entity visual generation (~144 images)
- Download Kenney + Sonniss packs

**Phase 2 (Week 2)**:
- Generate race/frame/mod variants (80 images)
- Organize all assets into godot/assets/
- Wire AssetLibrary sound mappings

**Phase 3 (Week 3)**:
- Deploy n8n workflow for ongoing asset generation
- Test asset loading in-game
- Generate additional faction/stage variants if desired

**By Launch**: 144 core entities + 80 race/frame/mod visuals + full audio library ready.

