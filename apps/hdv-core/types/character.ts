export type FactionId = 'veiled_current' | 'sovereign_crown' | 'wildlands_ascendants'
export type EntityRole = 'warrior' | 'guardian' | 'trickster'
export type SpaceZone = 'supraliminal' | 'liminal' | 'periliminal' | 'subliminal' | 'hyperliminal'

export interface Faction {
  id: FactionId
  name: string
  origin: string          // cultural pantheon
  description: string
  colorScheme: {
    primary: number       // hex int
    secondary: number
    light: number
    glow: string          // CSS color for UI
    glowHex: number       // Phaser hex
  }
  // RPS: this faction defeats the one in `defeats`
  defeats: FactionId
  defeats_text: string
}

export interface Race {
  id: string
  name: string
  faction: FactionId
  description: string
  texture: {
    type: string
    description: string
    primaryColor: string
    tintHex: number
  }
  lore: string
  statBonus: Partial<{ power: number; agility: number; resonance: number; frequency: number }>
  passive: { name: string; effect: string }
  drawback: string
}

export interface Frame {
  id: string
  name: string
  description: string
  role: string
  stats: {
    agility: number       // 1-10 mobility
    power: number         // 1-10 combat
    resonance: number     // 1-10 light affinity
    frequency: number     // 1-10 sound affinity
  }
  mobility: string        // description of movement style
  combatStyle: string
  lore: string
  frameType: 'light' | 'heavy'
  exclusiveStat: { name: string; effect: string }
}

export interface PhysicalMod {
  id: string
  name: string
  description: string
  visualEffect: string
  statModifier: Partial<{ power: number; agility: number; resonance: number; frequency: number }>
  bonus: string
  drawback: string
}

export interface CharacterDraft {
  faction: FactionId | null
  race: string | null
  frame: string | null
  physicalMod: string | null
  username: string
  /** Data URL of the stylized avatar saved in the Capture step (client-only; not persisted to the characters table). */
  portraitDataUrl?: string | null
}

export interface Character {
  id: string
  user_id: string
  faction: FactionId
  race: string
  frame: string
  physical_mod: string
  prestige_level: number
  xp: number
  created_at: string
}
