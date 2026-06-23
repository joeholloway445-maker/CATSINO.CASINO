import type { FactionId, EntityRole } from './character'

// Locked gameplay template — one per entity. faction/role/tier define the
// "shape" (mesh size, attack rate/damage/type equivalent) that any creation
// built on this blueprint must preserve. Visuals are unrestricted.
export interface CompanionBlueprint {
  blueprint_id: string
  faction: FactionId
  role: EntityRole
  tier: 1 | 2 | 3 | 4 | 5
}

export type CreationSkin = FactionId | 'custom'

// A player-built companion/item derived from a blueprint. Gameplay stats
// come from the blueprint (locked); name/skin/visual are player-defined.
export interface PlayerCreation {
  id: string
  user_id: string
  blueprint_id: string
  name: string
  skin: CreationSkin
  visual: Record<string, unknown>
  power_level: number
  created_at: string
}

// Shared per-blueprint currency pool, spendable on any of the player's
// creations derived from that blueprint.
export interface PlayerBlueprintCharges {
  user_id: string
  blueprint_id: string
  charge_count: number
  updated_at: string
}

const CREATION_COST_BY_TIER: Record<CompanionBlueprint['tier'], number> = {
  1: 5,
  2: 8,
  3: 12,
  4: 18,
  5: 25,
}

const CHARGE_RATE_BY_TIER: Record<CompanionBlueprint['tier'], number> = {
  1: 1,
  2: 1,
  3: 2,
  4: 2,
  5: 3,
}

// Number of duplicate copies required to deconstruct into a new creation.
export function blueprintCreationCost(tier: CompanionBlueprint['tier']): number {
  return CREATION_COST_BY_TIER[tier]
}

// Charges granted per extra duplicate deconstructed after creation.
export function blueprintChargeRate(tier: CompanionBlueprint['tier']): number {
  return CHARGE_RATE_BY_TIER[tier]
}
