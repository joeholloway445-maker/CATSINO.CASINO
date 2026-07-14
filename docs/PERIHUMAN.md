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
PeriHuman replaces everything below that: the player's authored genome
(saved on `PlayerProfile.perihuman_dna` via the Studio's "Use This Human"),
and deterministic per-id genomes for NPCs. The old capsule `CharacterRig`
remains only as the absolute last resort.

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
