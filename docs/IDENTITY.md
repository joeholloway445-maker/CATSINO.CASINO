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
`IdentityLens.perceive_being()` (other characters/NPCs/entities).

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
