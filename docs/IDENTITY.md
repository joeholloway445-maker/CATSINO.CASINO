# Identity — races, frames, ascension, and the lens

> No two players ever see or hear the same game.

This is not a slogan; it is an invariant the engine enforces
(`src/identity/identity_lens.gd`, autoloaded as `IdentityLens`). Your build
is not an outfit worn by a character inside a fixed world — your build is
the **instrument the world is played through**.

## The metaphysics (why this is lore, not just tech)

The six reality layers are not places; they are depths of the same thing.
What a being *is* determines what it can perceive of them. A race is a
**substance** — the material your perception is made of, and therefore the
material everything looks made of *to you*. A frame is a **sensorium** —
the apparatus you sense through, and therefore the light and sound of your
entire world. This is why the RPS perception model is asymmetric by design:
two beings looking at each other are each rendering the other through their
own substance. Neither view is "the real one." There is no real one.

The Periliminal knows this. It's why it pays so well and takes everything.

## Races — what reality is made of (20)

Each of the 20 races carries a `texture_type` and `primary_color`
(`race_data_character.gd`). Through the lens, that texture governs **every
hard mesh on your client** — terrain chunks, props, buildings, NPCs,
entities, other players:

- A **crystalline** player walks through a world of faceted, half-glass
  surfaces. A **biotech** player sees the same chunk grown, not built.
- Other beings render through your lens too, then the RPS wheel
  (SovereignCrown > WildlandsAscendant > VeiledCurrent > SovereignCrown,
  `perception_system.gd`) scales and auras them: what you counter looks
  diminished; what counters you *looms*; what vastly outclasses you won't
  even show you its loadout — just a silhouette you should walk away from.
- Alignment tints the aura, so a friendly silhouette reads warm even when
  it is very much going to kill you in the open Metroplex.

Entry points: `IdentityLens.world_material()` (all hard mesh),
`IdentityLens.perceive_being()` (other characters/NPCs/entities). Every
procedural hard-surface builder routes through one of these two — terrain
(`procedural_terrain.gd`), the mega-city (`mega_city_builder.gd`), and
forged weapons/armor/entity bodies (`blueprint_mesh.gd`) alike — so a
sword you forge, a creature you tame, and a wall you've never touched are
all rendered in your race's material on your screen and someone else's on
theirs. A few surfaces are deliberately left un-lensed on purpose: PVXC's
danger ring, harvest-node color, and layer-exit door tint are gameplay
*signals* (danger, exit, destination) that need to read identically for
every player, so they're exempt from the "everyone sees something
different" rule by design, not by omission.

## Frames — how reality is lit, and what it sounds like (20)

Each of the 20 frames defines a **sensorium** (`frame_sensorium.gd`): key
light color, exposure, fog, a musical mode, a tempo, a timbre. Two players
standing in the same spot at the same hour are in different weather:

- The **Bolt** pilot lives overexposed at 160bpm, everything staccato.
- The **Behemoth** pilot hears one endless patient drone under granite grey.
- The **Blight** pilot's sounds decay faster than they should, in a sickly
  green haze that isn't in anyone else's game.

The sound contract (`IdentityLens.sound_profile()`) also folds in your
**identity seed**, so even two same-frame players get different voicings —
the mode and tempo match, the phrasing never does.

Entry points: `IdentityLens.tune_sky()` (applied to every DayNightSky),
`sound_profile()` (ambient audio generation contract).

## Mods — how it feels to move, and how hard you hit (20)

Frame and race are read-only, given at creation; a **mod** is the one
build piece with a live, tunable mechanical effect
(`frame_mod_data.gd`'s `stat_bonus`, translated into concrete numbers by
`mod_mechanics.gd`'s `ModMechanics`). Rather than a second table to keep
in sync by hand, the mechanics are *derived* straight from the stat bonus
already on the mod — one source of truth:

- **spd** bonus/penalty scales move speed, acceleration, and jump height
  (`ThirdPersonController` reads this on ready and again on every
  `PlayerProfile.profile_updated`) — a **Turbo Injector** pilot visibly
  outpaces everyone else on foot; a **Shield Matrix** pilot is a hair
  slower for the defense it buys.
- **pow** bonus/penalty scales outgoing damage; **res** bonus/penalty
  scales damage *taken* (inverted — more res, less gets through); **lck**
  bonus/penalty nudges crit chance up or down on top of whatever the
  ability already rolls (`CombatSystemRealtime.calculate_damage()` /
  `use_ability()`). A **Berserker Chip** hits noticeably harder and takes
  noticeably more; a **Harmony Crystal**'s five flat +5s round out to a
  gentle, well-rounded bump across the board.

This runs through the live-action combat system (`CombatSystemRealtime`,
what the PVXC arena actually plays on) and the overworld movement
controller — not the older turn-based Cat Coliseum encounter resolver
(`combat_system.gd`), which is a self-contained minigame with its own
canned opponent stats and predates the current race/frame/mod id scheme;
unifying the two is a bigger, separate undertaking.

## Ascension — the second frame

At level 50 you may opt into the **Champion trial** (4 provisional PvP
hours, per the crowns system). Champions choose a **second frame**
(`PlayerProfile.set_ascended_frame`). The sensoria **blend** — your base
frame keeps 60% authority (it is still who you are), the ascension frame
colors it, and the soundscape becomes a duet: 20 solo instruments become
400 possible duets. Your world audibly, visibly changes the day you ascend.

## The build math

| Stage | Multiplier | Space |
|---|---|---|
| Creation: 20 races × 20 frames × 20 mods | — | **8,000** |
| Champion ascension: second frame | ×20 | **160,000** |
| Faction choice (three factions) | ×3 | **480,000** |
| Each quest-reward title earned | ×2 each | 480,000 × 2ⁿ |

At creation you are a once-in-8,000 build. Every threshold multiplies it.
`IdentityLens.rarity_denominator()` computes it live and
`rarity_text()` renders it ("You are 1 in 960,000.") — surfaced at
character creation and on the profile. Titles are the deliberate late-game
multiplier: they only come from quests, crowns, and feats
(`title_data.gd`), never the shop.

## View scale — the perception style toggle

The RPS distortion (apparent scale + aura from `PerceptionSystem.perceive`)
is core to "no two players see the same game," but it's also a real
visual-intensity preference, so it's opt-in-by-default rather than
mandatory (`PlayerProfile.view_scale_style`, `ViewScale`
`src/identity/view_scale.gd`):

| Style | What it does |
|---|---|
| **Glitchy** | Aura shifts toward magenta/cyan and the material's emission live-flickers on a jittery cadence — the one style with real per-frame motion. |
| **Holographic** *(default)* | Aura leans cyan-white, the surface goes semi-transparent with a soft emission floor — a projection, not flesh. |
| **Shadowy** | No aura, darkened albedo, flattened roughness, apparent scale pulled slightly down — reads as a silhouette rather than a rendered being. |
| **Off** | Plain lensed material, apparent scale locked to 1.0, no aura. Full opt-out. |

Applies uniformly to players, entities, and companions, because all three
funnel through the same `PerceptionSystem.perceive()` call. The one
asymmetry: **opt-out travels with the subject, not the viewer.** If a
player sets their own style to Off, they render undistorted on *every*
client that looks at them — and so would anything tied to them (a
companion, an owned entity), by passing `opted_out: true` in that
subject's profile dict — not just their own screen. Wildlife and PVXC
creatures have no owner, so that override never applies to them; they
just always follow whichever style the local viewer has picked. Change it
any time from Settings → 🌐 Identity Lens.

## How it connects to everything else

- **Discovery** — your influence pack (race color) repaints chunks you
  frequent; other players see *your substance* bleeding into territory you
  hold, through *their* lens.
- **Crowns** — auras from crowns/Champion/God stack on top of the lens.
  A God-tier Triple Crown holder looks different in every witness's world,
  but looms in all of them.
- **Entities** — faction-exclusive rosters render through your lens like
  all beings; your entities inherit your substance's look on your client
  and read as *theirs* on everyone else's.
- **UGC** — blueprints built in the Subliminal apartment carry the
  creator's identity seed, so even shared UGC re-tunes per viewer.
- **Equivalent exchange** — race/faction gates on any of this can be
  bought through with Prestige. Nothing is out of reach; some things are
  just expensive in time.

## The soundtrack & the signature style

Original tracks (Suno-produced; the catalog grows over time) live in
`godot/assets/music/` and are context-mapped by `MusicManager`:

| Track | Context |
|---|---|
| **Periliminal Space** | THE theme song — title, main menu, Subliminal |
| **noclip** | The Liminal and the Periliminal (falling out of reality) |
| **Ridin' Tonight** | Racing |
| **Taillights Fade** | Supraliminal/Extraliminal overworld (night driving) |
| **Take a Bow for Blake** | Tournament/championship victory stinger |

Two rules define the audio signature:
1. **The tracks carry the melody; your build carries the texture.** Under
   every track, `SensoriumAmbience` live-synthesizes a quiet bed from your
   frame's mode/tempo/timbre and your identity seed — the world's hum is
   yours alone.
2. **Multiple tracks per context rotate by identity seed** — as the Suno
   catalog grows, different builds hear different cuts in the same places.
   Drop a new .mp3 in `assets/music/` and add it to a context's list in
   `music_manager.gd`; nothing else needed.

## Skills — lines, morphs, bars, ultimates

ESO-shaped, but every line comes from what you ARE (`src/skills/`):

- **Frame Discipline** (all 20 frames): 5 actives + 1 ultimate + 3
  passives, generated from the frame's stat profile, lore, and sensorium —
  a Bolt line plays nothing like an Ossian line. Your ascended frame's
  line powers **Bar II**, so bar-swapping is literally swapping sensoria.
- **Race Heritage** (all 20): passive-heavy, 2 actives + the True-Form
  ultimate ("every hard surface in YOUR world turns to your substance —
  and everyone nearby sees theirs flicker").
- **Faction lines**: Crown Mandate / Wild Ascension / Current Working —
  and the **Lone Wolf** line, Factionless-only, whose ultimate
  ("Nobody's Hour") stops you rendering on anyone's client entirely.
- **The Liminal Arts**: the universal line (Doorframe, Wrong Hallway,
  Hum of the Vents, and the Noclip ultimate).
- **Morphs**: every active refracts at rank IV — lore says a skill
  practiced long enough starts perceiving YOU back and must choose what
  it sees: a weapon (Edge: +35% power) or a survivor (Still: -30%
  cost/cooldown).
- **Ranks by use**, skill points from level-ups and quests, flux resource
  scaled by STY/RES (regen by SPD), ultimate charge from dealing AND
  taking damage. Hotbar: keys 1-5, R ultimate, Tab bar-swap.
