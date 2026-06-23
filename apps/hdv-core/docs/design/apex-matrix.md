# Apex Matrix (4096) — UGC-as-NPC Companion Grid

Status: **Design captured, not yet implemented.**

## Concept

The Apex Matrix is a large grid of NPC "slots" (4096 total) that populate the
game world and its fiction. Instead of being hand-authored only, these slots
can be **filled by player UGC creations** — meaning a player's custom
companion/item build (made via the Blueprint deconstruct system, see
`docs/design/` UGC notes and `supabase/migrations/002_ugc_blueprints.sql`)
can be promoted into the world as an NPC that *other players* encounter,
complete with its own storyline/lore presence.

This makes player creations literally part of the game and its fiction, not
just cosmetic skins on the player's own roster — a strong differentiator.

## How it Connects to Existing Systems

- **Blueprint economy** (migration 002): a `player_creations` row is the
  source material. Its `blueprint_id` still locks gameplay shape
  (faction/role/tier -> mesh size, attack rate/damage/type); only
  name/skin/visual are player-authored.
- **UGC Pipeline** (4 stages: Initial Submission -> QA & Moderation ->
  Balancing & Stat Normalization -> Deployment & Instancing): a creation must
  pass all four stages before it's eligible for Apex Matrix promotion.
- **Views system**: once placed in a slot, the NPC is rendered to other
  players through the normal View resolution (relationship + power-tier
  delta -> holographic<->distorted fidelity), exactly like any other entity.
- **Race / Frame / Mod tiers**: the NPC's visuals (Race), lights/sounds
  (Frame), and physics/combat math (Mod) are inherited from the underlying
  creation, same as for the owning player.

## Promotion / Verification Criteria — Resolved

A player's creation is usable **unrestricted within that player's own
personal Subliminal Space** with no review needed — it's private to them.

To go **anywhere else** (Apex Matrix promotion, or any visibility/use outside
the owner's Subliminal Space), the creation must first be **manually
verified**:

1. Player submits the creation via a ticket in the official Discord.
2. A dedicated community moderation team (separate from the dev team)
   reviews it for checks and balances — this is the human-run version of the
   UGC Pipeline's "QA & Moderation" and "Balancing & Stat Normalization"
   stages.
3. Only after the community team clears it does it reach the dev team for
   final addition (e.g. Apex Matrix slot placement, broader deployment).

This is a human-gated pipeline, not an automated QA score or pure player
vote — the Discord ticket + community review team *is* the moderation layer.

## Open Design Questions (for later)

- Storyline authorship: who writes the "fiction" layer for a promoted
  creation — the original player, procedurally generated, or staff-curated?
- Slot structure: is 4096 a flat pool, or organized (e.g. by zone/faction/
  tier, similar to the 64x64 layout seen in the Omni Dex)?
- Ownership/attribution: does the original player retain credit/visibility
  when their creation appears as an NPC for others?
- Lifecycle: can a slot's NPC be rotated out, retired, or replaced; does the
  original player's own copy stay independent of the promoted instance?

## Next Steps (not started)

- Define `apex_matrix_slots` data model (slot id, occupant creation id,
  status, zone/placement, storyline ref)
- Define promotion pipeline hook at end of UGC Deployment & Instancing stage
- Decide slot organization (flat 4096 vs. structured grid)
- Tie slot rendering into the Views resolver from `views-system.md`
