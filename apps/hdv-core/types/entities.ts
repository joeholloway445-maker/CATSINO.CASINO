import type { FactionId, EntityRole } from './character'

export interface Entity {
  id: string
  faction: FactionId
  name: string            // deity name
  title: string           // in-game title
  description: string
  role: EntityRole        // warrior | guardian | trickster
  tier: 1 | 2 | 3 | 4 | 5
  stats: {
    power: number         // 1-20
    agility: number
    resonance: number
    frequency: number
  }
  defeats: EntityRole     // which role this defeats
  lore: string
  specialAbility: string
}

export interface PlayerEntity {
  id: string
  user_id: string
  entity_id: string
  faction: FactionId
  entity_type: EntityRole
  count: number
  first_encountered_at: string
  caught_at: string | null
}
