# PeriHuman — our own MetaHumans, natively in Godot

PeriHuman is Periliminal's in-house parametric human system: the feature
set of Epic's MetaHuman Creator, rebuilt inside the Godot client with no
Unreal, no exports, no asset downloads. A human is a small JSON **genome**;
everything else — skeleton, skinned mesh, face, morphs, eyes, hair,
materials — is grown from it procedurally at runtime.

## Where it lives

| Piece | File |
| --- | --- |
| Genome (the "DNA file") | `godot/src/perihuman/human_dna.gd` |
| Preset gallery | `godot/src/perihuman/human_presets.gd` |
| Humanoid skeleton | `godot/src/perihuman/human_skeleton_builder.gd` |
| Body/face mesh + morphs | `godot/src/perihuman/human_mesh_builder.gd` |
| Skin / eye / hair materials | `godot/src/perihuman/human_materials.gd` |
| Runtime character node | `godot/src/perihuman/peri_human_rig.gd` |
| Race archetypes (20 canon races) | `godot/src/perihuman/human_race_archetypes.gd` |
| Frame archetypes (20 sensorium frames) | `godot/src/perihuman/human_frame_archetypes.gd` |
| Mod archetypes (20 legacy mods) | `godot/src/perihuman/human_mod_archetypes.gd` |
| Identity composer (race+frame+mod → genome) | `godot/src/perihuman/human_identity.gd` |
| Character Studio UI | `godot/src/ui/perihuman_creator_ui.gd` + `godot/scenes/ui/perihuman_creator.tscn` |

The Studio is reachable from the main menu ("🧬 Character Studio").

## Feature map vs. MetaHuman

| MetaHuman Creator | PeriHuman |
| --- | --- |
| DNA file | `HumanDNA` — 40 normalized genes + colors + hairstyle, serializes to a ~1 KB JSON dict |
| Preset gallery | `HumanPresets` — 12 hand-tuned genomes across a wide phenotype range |
| Blend between presets | `HumanDNA.blend([[dna, weight], ...])` — the Studio exposes a 3-way weighted blend |
| Sculpt controls | Every gene is a live slider (head, brow, eyes, nose, cheeks, mouth, jaw, body) |
| Skin/eye/hair | Melanin-ramp SSS skin, procedurally painted irises, parametric hairstyle shells |
| Facial rig | Blend shapes generated from the same mesh generator: `blink`, `jaw_open`, `smile`, `brow_raise` |
| Idle "alive" pass | Procedural breathing, blinking, eye saccades, head micro-motion |
| LODs | 3 mesh tiers; `PeriHumanRig.auto_lod` switches by camera distance |
| Body types | Height/build/muscle/proportion genes reshape skeleton + mesh together |
| Retargeting | Bone names follow Godot's `SkeletonProfileHumanoid`, T-pose rest — stock retarget pipeline applies |

## How the mesh works

Every body part is a loft of elliptical cross-section rings; the head is a
dense lat/lon dome whose radius field is modulated by gaussian feature
bumps (brow ridge, eye sockets, nose bridge/tip/flare, cheekbones, lips,
chin, ears) driven by the genome. Vertex **topology depends only on LOD**,
never on genes or expressions — so re-evaluating the same generator with an
expression pose yields perfectly aligned blend-shape deltas, and any two
genomes could even be vertex-interpolated.

Skin weights (2 bones/vertex) are assigned per ring during the loft, and
the mesh binds with `Skeleton3D.create_skin_from_rest_transforms()`.
Face paint (lips, brow shadow, stubble, flush, freckles) and the neutral
charcoal base layer live in vertex color, multiplied under the SSS skin
material — no textures anywhere except the generated iris.

## Race / frame / mod identity

The character creator already has its own race (20 cat breeds ->
`RaceDataCharacter`, each mapped via `CanonRaces` to one of the 20 canon
species with full lore in `RaceLore`), sensorium frame (20 light/heavy
frames -> `FrameModData.FRAMES`), and mod (20 legacy augments ->
`FrameModData.MODS`) selections. `HumanIdentity.build(race_id, frame_id,
mod_id, seed)` turns that same selection into a PeriHuman genome, so a
citizen looks like their lore before anyone touches a slider:

- **Race** (`HumanRaceArchetypes`) sets species-level traits straight from
  each race's blurb — a Ferox reads as a towering, scarred apex predator;
  a Lumari as pale and crystalline with a bioluminescent glow; a Nyx with
  light-swallowing black eyes and skin; an Igni running hot with an ember
  emissive; a Petra stone-grey and ancient; and so on for all 20. A
  handful of genes get nudged, eye/hair color and a default hairstyle are
  set, and — where the lore calls for it — `skin_tint`, `marking_color`,
  `skin_material` (roughness/metallic/transparency/emissive, the same
  shape as `TextureMaterials.TEXTURE_MATERIAL`), and `emissive_boost` give
  the skin its material identity. Chimera is the one exception: instead of
  a fixed body it seed-jitters a wide gene spread and picks from a
  deliberately unusual eye/hair palette, because "no two Chimera are
  alike" is the whole point.
- **Frame** (`HumanFrameArchetypes`) is worn architecture, not species, so
  it only reshapes build along the light/heavy axis described in each
  frame's lore (`veil` gossamer-thin, `bastion` a fortress, `bolt`
  sacrifices everything for speed, `behemoth` maximum bulk, ...), plus a
  small accent for the loudest frames (`ignis` runs hot, `phantom`
  partially dematerializes).
- **Mod** (`HumanModArchetypes`) is a small installed system layered last,
  so its accent sits on top of the race/frame look: a subtle gene nudge
  plus a marking/emissive touch (`berserker_chip` flushes red and scars,
  `void_capacitor` darkens the eyes, `harmony_crystal` gets a soft
  balanced glow).

Layering order is always race → frame → mod: genes are additive nudges at
each step, while colors/material keys from a later layer override the
earlier one. The Character Studio's **Identity** tab exposes this
directly — pick a race/frame/mod and hit Generate, then keep sculpting on
every other tab as normal. `MetahumanCharacter._native_player()` /
`_native_npc()` call `HumanIdentity.build()` automatically whenever a
player hasn't authored a custom genome in the Studio (or an NPC has no
authored one at all), using `PlayerProfile.selected_race_id` /
`selected_frame` / `selected_mod`.

## Runtime usage

```gdscript
var rig := PeriHumanRig.new()
rig.dna = HumanPresets.by_name("Freja")        # or HumanDNA.random(npc_id.hash())
add_child(rig)
rig.set_expression("smile", 0.6)
rig.set_lod(1)                                  # or rig.auto_lod = true
```

## Where it sits in the visual chain

`MetahumanCharacter` (the ESO-bar resolver) still lets a real Unreal
MetaHuman GLB export win if one is dropped into `assets/models/`
(`metahuman_player` etc.), because a film-quality scan beats procedural.
PeriHuman replaces everything below that, in order: the player's authored
genome (saved on `PlayerProfile.perihuman_dna` via the Studio's "Use This
Human"); failing that, a genome composed from their race/frame/mod
selection via `HumanIdentity`; failing that, a neutral default preset.
NPCs always go through `HumanIdentity` off their race id. The old capsule
`CharacterRig` remains only as the absolute last resort.

## Extending it

- **New gene**: add one row to `HumanDNA.GENES`, consume it in
  `HumanMeshBuilder.head_point()` (or the body lofts) — the Studio slider,
  serialization, blending and randomization appear automatically.
- **New hairstyle**: add an entry to `HumanMeshBuilder.HAIR_PARAMS`
  (+ optional extras like the bun/ponytail lofts) and the id to
  `HumanDNA.HAIR_STYLES`.
- **New expression morph**: append to `HumanMeshBuilder.MORPHS` and give it
  a response in `head_point()` — it becomes a blend shape on every LOD.
- **Outfits**: the base layer is vertex-colored; a clothing system can
  either paint more of the body or parent meshes to the standard bones.
- **New/changed race, frame, or mod lore**: edit the matching entry in
  `HumanRaceArchetypes.RACES` / `HumanFrameArchetypes.FRAMES` /
  `HumanModArchetypes.MODS` — gene deltas, colors, and the optional
  `skin_tint`/`marking_color`/`skin_material`/`emissive_boost` keys are
  all `HumanIdentity` needs to pick it up everywhere the identity is used.
