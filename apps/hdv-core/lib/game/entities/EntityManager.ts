import type { Entity } from '@/types/entities'
import type { FactionId } from '@/types/character'
import { getRandomEncounter } from '@/lib/game/data/entities'

export interface EncounterResult {
  entity: Entity
  outcome: 'collected' | 'fled' | 'failed'
  fragmentsEarned: number
  renownEarned: number
}

export function rollEncounter(zone: string, playerFaction: FactionId): Entity | null {
  // Determine encounter tier based on zone
  const tierMap: Record<string, 1 | 2 | 3 | 4 | 5> = {
    supraliminal: 1,
    liminal: 2,
    periliminal: 3,
    subliminal: 1,
    hyperliminal: 5,
  }
  const tier = tierMap[zone] ?? 1

  // Pick entity from same or opposing faction for variety
  const factions: FactionId[] = ['veiled_current', 'sovereign_crown', 'wildlands_ascendants']
  const encounterFaction = factions[Math.floor(Math.random() * factions.length)]

  return getRandomEncounter(encounterFaction, tier)
}

export function resolveCapture(entity: Entity, playerPower: number): EncounterResult {
  const captureProbability = Math.max(0.1, 1 - (entity.tier * 0.15))
  const success = Math.random() < captureProbability

  const fragmentsEarned = entity.tier * 5 * (success ? 1 : 0)
  const renownEarned = entity.tier * 2

  return {
    entity,
    outcome: success ? 'collected' : 'fled',
    fragmentsEarned,
    renownEarned,
  }
}
