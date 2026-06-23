import { VEILED_CURRENT_ENTITIES } from './veiledCurrent'
import { SOVEREIGN_CROWN_ENTITIES } from './sovereignCrown'
import { WILDLANDS_ASCENDANTS_ENTITIES } from './wildlandsAscendants'
import type { Entity } from '@/types/entities'
import type { FactionId } from '@/types/character'

export const ALL_ENTITIES: Entity[] = [
  ...VEILED_CURRENT_ENTITIES,
  ...SOVEREIGN_CROWN_ENTITIES,
  ...WILDLANDS_ASCENDANTS_ENTITIES,
]

export function getEntitiesByFaction(faction: FactionId): Entity[] {
  return ALL_ENTITIES.filter((e) => e.faction === faction)
}

export function getEntityById(id: string): Entity | undefined {
  return ALL_ENTITIES.find((e) => e.id === id)
}

export function getRandomEncounter(faction: FactionId, tier: 1 | 2 | 3 | 4 | 5 = 1): Entity {
  const pool = getEntitiesByFaction(faction).filter((e) => e.tier <= tier)
  return pool[Math.floor(Math.random() * pool.length)] ?? ALL_ENTITIES[0]
}

// RPS defeat resolution
// Warrior > Trickster > Guardian > Warrior
export function resolveRPS(attacker: Entity, defender: Entity): 'win' | 'lose' | 'draw' {
  if (attacker.defeats === defender.role) return 'win'
  if (defender.defeats === attacker.role) return 'lose'
  return 'draw'
}
