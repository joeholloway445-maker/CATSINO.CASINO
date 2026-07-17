# Periliminal.Space — UGC & Blueprint Policy

Periliminal.Space fully encourages players to be uniquely their own selves.
Every weapon, armor set, skill effect, and entity is a **blueprint** — and
this document is the rulebook for what happens to a blueprint from the
moment it's forged to the moment it becomes canon lore.

## Where UGC lives

**All UGC building happens in your Subliminal** — the apartment layer,
the start screen you land in every single session. Inside your own
Subliminal a design can be *anything*: it can never hurt canon lore
because it never leaves your space. Unapproved UGC does not render in
any other layer, cannot be equipped in the open world, and cannot be
sold.

**Nothing auto-spawns in the Subliminal.** It is each player's private
safe zone. Ambient figures require an active Creator subscription.
Item storage is capped for free players; raise the ceiling with a
Creator subscription and/or one-time locker expansions.

## The canonization pipeline

```
private ──submit──▶ mod_review ──pass──▶ dev_review ──pass──▶ CANON
   ▲                    │ fail               │ fail
   └──── rejected ◀─────┴────────────────────┘
```

1. **Discord mod team** — balance check. Is it fair, exploit-free,
   within visual/audio limits?
2. **Dev team** — canon check. Does it fit the lore, the layer rules,
   the world's tone?
3. **Canon** — the design enters in-game lore.

## Ownership on canonization

When UGC becomes canon it becomes property of **Holloway's Own
Providential Enterprise Apex Holdings Inc.**, which takes a small cut
(currently 10%) of each sold copy. In exchange, the creator keeps
everything that matters:

- **The blueprint stays theirs** — unless they sell it outright.
- **Every copy carries their name** — unless the blueprint is sold.
- **Only they can craft it.** Buying a copy is buying the item, never
  the recipe.
- **Forking is opt-in only.** Creators may allow others to fork their
  builds, but only at their discretion — never without.

Selling the blueprint itself transfers *all* of the above to the buyer:
name, crafting rights, listing rights. It is the one way a creator's
name comes off a design, and it is irreversible.

## The marketplace & player trade

Canon UGC sells in Arlington's marketplace through its vendor stalls:
guild traders, armorers, blacksmiths, merchants, black-market merchants,
stables, jewelers, alchemists, outfitters, curio dealers, and the bank
branch — with more stalls to come.

Every listing, sale, and blueprint transfer appends to an auditable
ledger (`Marketplace.audit_log`). Direct player-to-player swaps go
through `TradeManager` with escrow, a house tax on coin legs, and the
same append-only audit trail.

Currency cage rates are house-favorable: buying chips costs more
Coins/Ex-Coins than face value; cashing chips out pays fewer **Ex-Coins**
(never purchasable Coins) — see `EconomyManager` chip buy / `cashout_chips_to_ex`.

## Subliminal tiers

Your Subliminal grows with you. All tiers keep the same rule — what
happens inside stays inside:

| Tier | Slots | Guests | Public? | Price |
|---|---|---|---|---|
| Studio Flat | 8×6 | 4 | no | free |
| Corner Loft | 12×10 | 12 | no | 8,000 🪙 |
| Gallery | 18×14 | 40 | optional | 30,000 🪙 |
| Grand Hall | 26×20 | 120 | optional | 90,000 🪙 |
| Pavilion | 40×30 | 300 | optional | 250,000 🪙 |

Keep it private, or open a Pavilion to 300 strangers — your space, your
rules.
